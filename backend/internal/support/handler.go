package support

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

func (h *Handler) CreateTicket(c *gin.Context) {
	userID, _ := c.Get("user_id")
	id, _ := uuid.Parse(userID.(string))
	var req CreateTicketRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	ticket, err := h.service.CreateTicket(c.Request.Context(), id, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, ticket)
}

func (h *Handler) ListTickets(c *gin.Context) {
	userID, _ := c.Get("user_id")
	id, _ := uuid.Parse(userID.(string))
	tickets, err := h.service.ListUserTickets(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"tickets": tickets})
}

func (h *Handler) GetTicket(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))
	ticket, err := h.service.GetTicket(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "ticket not found"})
		return
	}
	c.JSON(http.StatusOK, ticket)
}

func (h *Handler) AddMessage(c *gin.Context) {
	ticketID, _ := uuid.Parse(c.Param("id"))
	userID, _ := c.Get("user_id")
	senderID, _ := uuid.Parse(userID.(string))
	role, _ := c.Get("role")

	var req AddMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	isAdmin := role.(string) != "customer" && role.(string) != "technician"
	if err := h.service.AddMessage(c.Request.Context(), ticketID, senderID, req.Content, isAdmin); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"message": "message added"})
}

func (h *Handler) GetMessages(c *gin.Context) {
	ticketID, _ := uuid.Parse(c.Param("id"))
	messages, err := h.service.GetMessages(c.Request.Context(), ticketID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if messages == nil {
		messages = []TicketMessage{}
	}
	c.JSON(http.StatusOK, gin.H{"messages": messages})
}

func (h *Handler) AdminListTickets(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	status := c.Query("status")

	tickets, total, err := h.service.ListAllTickets(c.Request.Context(), page, pageSize, status)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"tickets": tickets, "total": total, "page": page})
}

func (h *Handler) AssignTicket(c *gin.Context) {
	ticketID, _ := uuid.Parse(c.Param("id"))
	adminID, _ := c.Get("user_id")
	aid, _ := uuid.Parse(adminID.(string))
	if err := h.service.AssignTicket(c.Request.Context(), ticketID, aid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "ticket assigned"})
}

func (h *Handler) CloseTicket(c *gin.Context) {
	ticketID, _ := uuid.Parse(c.Param("id"))
	if err := h.service.CloseTicket(c.Request.Context(), ticketID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "ticket closed"})
}
