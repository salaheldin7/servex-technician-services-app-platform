package verification

import (
	"encoding/base64"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) getTechID(c *gin.Context) (uuid.UUID, error) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))
	return h.service.GetTechnicianID(c.Request.Context(), uid)
}

// POST /technicians/verification/face
func (h *Handler) UploadFace(c *gin.Context) {
	techID, err := h.getTechID(c)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "technician profile not found"})
		return
	}

	var req UploadFaceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.service.UploadFace(c.Request.Context(), techID, req.FaceFrontBase64, req.FaceRightBase64, req.FaceLeftBase64); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "face verification uploaded", "status": "face_done"})
}

// POST /technicians/verification/documents
func (h *Handler) UploadDocuments(c *gin.Context) {
	techID, err := h.getTechID(c)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "technician profile not found"})
		return
	}

	form, err := c.MultipartForm()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid form data"})
		return
	}

	files := form.File["documents"]
	if len(files) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "no documents uploaded"})
		return
	}
	if len(files) > 2 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "maximum 2 documents allowed"})
		return
	}

	uploadDir := "uploads/documents"
	os.MkdirAll(uploadDir, 0755)

	var saved []IDDocument
	for i, file := range files {
		ext := strings.ToLower(filepath.Ext(file.Filename))
		if ext != ".jpg" && ext != ".jpeg" && ext != ".png" {
			c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("unsupported file type: %s, only images allowed", ext)})
			return
		}

		docType := "id_card_front"
		if i == 1 {
			docType = "id_card_back"
		}

		fileType := strings.TrimPrefix(ext, ".")
		if fileType == "jpeg" {
			fileType = "jpg"
		}

		filename := fmt.Sprintf("%s_%s%s", techID.String(), docType, ext)
		savePath := filepath.Join(uploadDir, filename)

		src, err := file.Open()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to open file"})
			return
		}
		defer src.Close()

		dst, err := os.Create(savePath)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to save file"})
			return
		}
		defer dst.Close()
		io.Copy(dst, src)

		doc := &IDDocument{
			TechnicianID: techID,
			DocType:      docType,
			FileURL:      savePath,
			FileType:     fileType,
		}
		if err := h.service.SaveIDDocument(c.Request.Context(), doc); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		saved = append(saved, *doc)
	}

	// Send notification that application was submitted
	h.service.NotifyApplicationSubmitted(c.Request.Context(), techID)

	c.JSON(http.StatusOK, gin.H{"message": "documents uploaded", "documents": saved, "status": "docs_done"})
}

// POST /technicians/verification/documents/base64
func (h *Handler) UploadDocumentsBase64(c *gin.Context) {
	techID, err := h.getTechID(c)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "technician profile not found"})
		return
	}

	var req struct {
		Documents []struct {
			Data    string `json:"data" binding:"required"`
			DocType string `json:"doc_type" binding:"required"`
		} `json:"documents" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if len(req.Documents) > 2 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "maximum 2 documents"})
		return
	}

	uploadDir := "uploads/documents"
	os.MkdirAll(uploadDir, 0755)

	for _, d := range req.Documents {
		data, err := base64.StdEncoding.DecodeString(d.Data)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid base64 data"})
			return
		}

		ext := ".jpg"
		fileType := "jpg"

		filename := fmt.Sprintf("%s_%s%s", techID.String(), d.DocType, ext)
		savePath := filepath.Join(uploadDir, filename)
		os.WriteFile(savePath, data, 0644)

		doc := &IDDocument{
			TechnicianID: techID,
			DocType:      d.DocType,
			FileURL:      savePath,
			FileType:     fileType,
		}
		if err := h.service.SaveIDDocument(c.Request.Context(), doc); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	}

	// Send notification that application was submitted
	h.service.NotifyApplicationSubmitted(c.Request.Context(), techID)

	c.JSON(http.StatusOK, gin.H{"message": "documents uploaded", "status": "docs_done"})
}

// GET /technicians/verification/status
func (h *Handler) GetVerificationStatus(c *gin.Context) {
	techID, err := h.getTechID(c)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "technician profile not found"})
		return
	}

	status, err := h.service.GetVerificationStatus(c.Request.Context(), techID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, status)
}

// POST /technicians/services
func (h *Handler) AddServices(c *gin.Context) {
	techID, err := h.getTechID(c)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "technician profile not found"})
		return
	}

	var req AddServicesRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.service.AddServices(c.Request.Context(), techID, req.Services); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	services, _ := h.service.GetServices(c.Request.Context(), techID)
	c.JSON(http.StatusOK, gin.H{"message": "services added", "services": services})
}

// GET /technicians/services
func (h *Handler) GetServices(c *gin.Context) {
	techID, err := h.getTechID(c)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "technician profile not found"})
		return
	}

	services, err := h.service.GetServices(c.Request.Context(), techID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if services == nil {
		services = []TechnicianService{}
	}

	c.JSON(http.StatusOK, gin.H{"services": services})
}

// DELETE /technicians/services/:id
func (h *Handler) RemoveService(c *gin.Context) {
	techID, err := h.getTechID(c)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "technician profile not found"})
		return
	}

	serviceID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid service id"})
		return
	}

	if err := h.service.RemoveService(c.Request.Context(), techID, serviceID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "service removed"})
}

// POST /technicians/locations
func (h *Handler) AddLocations(c *gin.Context) {
	techID, err := h.getTechID(c)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "technician profile not found"})
		return
	}

	var req AddLocationsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.service.AddLocations(c.Request.Context(), techID, req.Locations); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	locs, _ := h.service.GetLocations(c.Request.Context(), techID)
	c.JSON(http.StatusOK, gin.H{"message": "locations added", "locations": locs})
}

// GET /technicians/locations
func (h *Handler) GetLocations(c *gin.Context) {
	techID, err := h.getTechID(c)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "technician profile not found"})
		return
	}

	locs, err := h.service.GetLocations(c.Request.Context(), techID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if locs == nil {
		locs = []ServiceLocation{}
	}

	c.JSON(http.StatusOK, gin.H{"locations": locs})
}

// DELETE /technicians/locations/:id
func (h *Handler) RemoveLocation(c *gin.Context) {
	techID, err := h.getTechID(c)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "technician profile not found"})
		return
	}

	locID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid location id"})
		return
	}

	if err := h.service.RemoveLocation(c.Request.Context(), techID, locID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "location removed"})
}
