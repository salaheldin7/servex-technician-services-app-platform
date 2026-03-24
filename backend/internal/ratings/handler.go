package ratings

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) Create(c *gin.Context) {
	bookingID, _ := uuid.Parse(c.Param("booking_id"))
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	var req CreateRatingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: Get technician ID from booking
	techID := uuid.New() // placeholder

	if err := h.service.Create(c.Request.Context(), bookingID, uid, techID, &req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "rating submitted"})
}

func (h *Handler) GetTechnicianRatings(c *gin.Context) {
	techID, _ := uuid.Parse(c.Param("tech_id"))
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	ratings, avg, err := h.service.GetTechnicianRatings(c.Request.Context(), techID, page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"ratings": ratings, "average": avg})
}
