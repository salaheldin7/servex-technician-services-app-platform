package technicians

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// OnGoOnlineCallback is called when a technician goes online.
// Implemented by bookings.Service to send searching bookings.
type OnGoOnlineCallback interface {
	NotifyTechnicianOfSearchingBookings(ctx context.Context, technicianUserID uuid.UUID)
}

type Handler struct {
	service            *Service
	onGoOnlineCallback OnGoOnlineCallback
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

// SetOnGoOnlineCallback sets the callback invoked when a technician comes online.
func (h *Handler) SetOnGoOnlineCallback(cb OnGoOnlineCallback) {
	h.onGoOnlineCallback = cb
}

func (h *Handler) Register(c *gin.Context) {
	userID, _ := c.Get("user_id")
	id, _ := uuid.Parse(userID.(string))

	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	profile, err := h.service.Register(c.Request.Context(), id, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, profile)
}

func (h *Handler) GetProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")
	id, _ := uuid.Parse(userID.(string))

	profile, err := h.service.GetProfile(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "technician profile not found"})
		return
	}

	c.JSON(http.StatusOK, profile)
}

func (h *Handler) UpdateProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")
	id, _ := uuid.Parse(userID.(string))

	var req UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.service.UpdateProfile(c.Request.Context(), id, &req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "profile updated"})
}

func (h *Handler) SetOnline(c *gin.Context) {
	userID, _ := c.Get("user_id")
	id, _ := uuid.Parse(userID.(string))

	var req OnlineStatus
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// If trying to go online, enforce verification
	if req.IsOnline {
		profile, err := h.service.GetProfile(c.Request.Context(), id)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "technician profile not found"})
			return
		}
		if !profile.IsVerified {
			c.JSON(http.StatusForbidden, gin.H{"error": "verification_required", "message": "You must complete verification before going online"})
			return
		}
	}

	if err := h.service.SetOnline(c.Request.Context(), id, req.IsOnline); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// When technician comes online, notify them of any searching bookings
	if req.IsOnline && h.onGoOnlineCallback != nil {
		go h.onGoOnlineCallback.NotifyTechnicianOfSearchingBookings(context.Background(), id)
	}

	c.JSON(http.StatusOK, gin.H{"is_online": req.IsOnline})
}

func (h *Handler) UpdateLocation(c *gin.Context) {
	userID, _ := c.Get("user_id")
	id, _ := uuid.Parse(userID.(string))

	var req LocationUpdate
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.service.UpdateLocation(c.Request.Context(), id, req.Lat, req.Lng); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "location updated"})
}

func (h *Handler) GetNearby(c *gin.Context) {
	var req NearbyQuery
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	technicians, err := h.service.GetNearby(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"technicians": technicians})
}

func (h *Handler) GetEarnings(c *gin.Context) {
	// TODO: Implement earnings query
	c.JSON(http.StatusOK, &EarningsResponse{})
}

func (h *Handler) GetStats(c *gin.Context) {
	// TODO: Implement stats query
	c.JSON(http.StatusOK, &StatsResponse{})
}

func (h *Handler) SearchByServiceAndLocation(c *gin.Context) {
	var req SearchByServiceQuery
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	technicians, err := h.service.SearchByServiceAndLocation(
		c.Request.Context(), req.CategoryID, req.CountryID, req.GovernorateID, req.CityID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"technicians": technicians})
}

func (h *Handler) AutoAssign(c *gin.Context) {
	var req AutoAssignRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	technician, err := h.service.AutoAssign(
		c.Request.Context(), req.CategoryID, req.CountryID, req.GovernorateID, req.CityID,
	)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "no available technician found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"technician": technician})
}
