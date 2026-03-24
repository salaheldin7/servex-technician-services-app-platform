package addresses

import (
	"net/http"

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
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	var req CreateAddressRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	addr := &Address{
		UserID:         uid,
		Label:          req.Label,
		StreetName:     req.StreetName,
		BuildingName:   req.BuildingName,
		BuildingNumber: req.BuildingNumber,
		Floor:          req.Floor,
		Apartment:      req.Apartment,
		Latitude:       req.Latitude,
		Longitude:      req.Longitude,
		FullAddress:    req.FullAddress,
		IsDefault:      req.IsDefault,
	}

	if req.CountryID != "" {
		id, _ := uuid.Parse(req.CountryID)
		addr.CountryID = &id
	}
	if req.GovernorateID != "" {
		id, _ := uuid.Parse(req.GovernorateID)
		addr.GovernorateID = &id
	}
	if req.CityID != "" {
		id, _ := uuid.Parse(req.CityID)
		addr.CityID = &id
	}

	if err := h.service.Create(c.Request.Context(), addr); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, addr)
}

func (h *Handler) List(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	addresses, err := h.service.ListByUser(c.Request.Context(), uid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if addresses == nil {
		addresses = []Address{}
	}
	c.JSON(http.StatusOK, gin.H{"addresses": addresses})
}

func (h *Handler) GetDefault(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))

	addr, err := h.service.GetDefault(c.Request.Context(), uid)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "no default address"})
		return
	}
	c.JSON(http.StatusOK, addr)
}

func (h *Handler) SetDefault(c *gin.Context) {
	userID, _ := c.Get("user_id")
	uid, _ := uuid.Parse(userID.(string))
	addrID, _ := uuid.Parse(c.Param("id"))

	if err := h.service.SetDefault(c.Request.Context(), uid, addrID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "default address set"})
}

func (h *Handler) Delete(c *gin.Context) {
	addrID, _ := uuid.Parse(c.Param("id"))
	if err := h.service.Delete(c.Request.Context(), addrID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "address deleted"})
}
