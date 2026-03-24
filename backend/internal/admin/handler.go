package admin

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) Dashboard(c *gin.Context) {
	stats, err := h.service.Dashboard(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, stats)
}

func (h *Handler) ListUsers(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	role := c.Query("role")

	users, total, err := h.service.ListUsers(c.Request.Context(), page, pageSize, role)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"users": users, "total": total, "page": page})
}

func (h *Handler) GetUser(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))
	user, err := h.service.GetUser(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}
	c.JSON(http.StatusOK, user)
}

func (h *Handler) BanUser(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))
	if err := h.service.BanUser(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "user banned"})
}

func (h *Handler) UnbanUser(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))
	if err := h.service.UnbanUser(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "user unbanned"})
}

func (h *Handler) DeleteUser(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))
	if err := h.service.DeleteUser(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "user deleted"})
}

func (h *Handler) ResetUserPassword(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))
	var req struct {
		NewPassword string `json:"new_password" binding:"required,min=8"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to hash password"})
		return
	}

	if err := h.service.ResetUserPassword(c.Request.Context(), id, string(hash)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "password reset"})
}

func (h *Handler) ListTechnicians(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	var verified *bool
	if v := c.Query("verified"); v != "" {
		b := v == "true"
		verified = &b
	}

	// optional verification_status filter (comma-separated)
	var statuses []string
	if s := c.Query("status"); s != "" {
		for _, st := range splitAndTrim(s) {
			statuses = append(statuses, st)
		}
	}

	techs, total, err := h.service.ListTechnicians(c.Request.Context(), page, pageSize, verified, statuses...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"technicians": techs, "total": total, "page": page})
}

func splitAndTrim(s string) []string {
	var result []string
	for _, part := range strings.Split(s, ",") {
		p := strings.TrimSpace(part)
		if p != "" {
			result = append(result, p)
		}
	}
	return result
}

func (h *Handler) GetTechnician(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))
	tech, err := h.service.GetTechnician(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "technician not found"})
		return
	}
	c.JSON(http.StatusOK, tech)
}

func (h *Handler) VerifyTechnician(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))
	var req struct {
		Verified bool   `json:"verified"`
		Reason   string `json:"reason"`
	}
	c.ShouldBindJSON(&req)
	if req.Verified {
		if err := h.service.ApproveTechnician(c.Request.Context(), id); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	} else {
		if err := h.service.RejectTechnician(c.Request.Context(), id, req.Reason); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
	}
	c.JSON(http.StatusOK, gin.H{"message": "technician verification updated"})
}

func (h *Handler) GetTechnicianVerification(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))
	detail, err := h.service.GetTechnicianVerificationDetail(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "technician not found"})
		return
	}
	c.JSON(http.StatusOK, detail)
}

func (h *Handler) BanTechnician(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))
	if err := h.service.BanTechnician(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "technician banned"})
}

func (h *Handler) UnbanTechnician(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))
	if err := h.service.UnbanTechnician(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "technician unbanned"})
}

func (h *Handler) ListBookings(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	status := c.Query("status")

	bookings, total, err := h.service.ListBookings(c.Request.Context(), page, pageSize, status)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"bookings": bookings, "total": total, "page": page})
}

func (h *Handler) GetBooking(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))
	booking, err := h.service.GetBooking(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "booking not found"})
		return
	}
	c.JSON(http.StatusOK, booking)
}

func (h *Handler) ListPayments(c *gin.Context) {
	// TODO: Implement admin payment listing
	c.JSON(http.StatusOK, gin.H{"payments": []interface{}{}, "total": 0})
}

func (h *Handler) RevenueReport(c *gin.Context) {
	days, _ := strconv.Atoi(c.DefaultQuery("days", "30"))
	data, err := h.service.RevenueReport(c.Request.Context(), days)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": data})
}

func (h *Handler) BookingReport(c *gin.Context) {
	days, _ := strconv.Atoi(c.DefaultQuery("days", "30"))
	data, err := h.service.BookingReport(c.Request.Context(), days)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": data})
}
