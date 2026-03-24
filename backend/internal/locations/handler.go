package locations

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

func (h *Handler) ListCountries(c *gin.Context) {
	countries, err := h.service.ListCountries(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if countries == nil {
		countries = []Country{}
	}
	c.JSON(http.StatusOK, gin.H{"countries": countries})
}

func (h *Handler) ListGovernorates(c *gin.Context) {
	countryID, err := uuid.Parse(c.Param("country_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid country_id"})
		return
	}

	govs, err := h.service.ListGovernorates(c.Request.Context(), countryID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if govs == nil {
		govs = []Governorate{}
	}
	c.JSON(http.StatusOK, gin.H{"governorates": govs})
}

func (h *Handler) ListCities(c *gin.Context) {
	govID, err := uuid.Parse(c.Param("governorate_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid governorate_id"})
		return
	}

	cities, err := h.service.ListCities(c.Request.Context(), govID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if cities == nil {
		cities = []City{}
	}
	c.JSON(http.StatusOK, gin.H{"cities": cities})
}
