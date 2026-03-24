package websocket

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	ws "github.com/gorilla/websocket"
	"github.com/techapp/backend/internal/config"
)

var upgrader = ws.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // In production, restrict origins
	},
}

type Event struct {
	Type string      `json:"event"`
	Data interface{} `json:"data"`
}

// BookingParticipants contains both parties of a booking for message routing
type BookingParticipants struct {
	UserID       string
	TechnicianID string
}

// BookingLookup allows the hub to resolve booking participants without importing bookings package
type BookingLookup interface {
	GetBookingParticipants(ctx context.Context, bookingID string) (*BookingParticipants, error)
	GetActiveTechnicianBooking(ctx context.Context, technicianUserID string) (*BookingParticipants, string, error) // returns participants + bookingID
}

type Client struct {
	Hub    *Hub
	Conn   *ws.Conn
	Send   chan []byte
	UserID string
	Role   string
	mu     sync.Mutex
}

type Hub struct {
	clients       map[string]*Client // userID -> client
	register      chan *Client
	unregister    chan *Client
	mu            sync.RWMutex
	bookingLookup BookingLookup
}

func NewHub() *Hub {
	return &Hub{
		clients:    make(map[string]*Client),
		register:   make(chan *Client),
		unregister: make(chan *Client),
	}
}

// SetBookingLookup sets the booking lookup interface (called after hub creation to avoid import cycles)
func (h *Hub) SetBookingLookup(bl BookingLookup) {
	h.bookingLookup = bl
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client.UserID] = client
			h.mu.Unlock()
			log.Printf("WebSocket client connected: %s", client.UserID)

		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client.UserID]; ok {
				delete(h.clients, client.UserID)
				close(client.Send)
			}
			h.mu.Unlock()
			log.Printf("WebSocket client disconnected: %s", client.UserID)
		}
	}
}

func (h *Hub) SendToUser(userID string, event Event) {
	h.mu.RLock()
	client, ok := h.clients[userID]
	h.mu.RUnlock()

	if !ok {
		return
	}

	data, err := json.Marshal(event)
	if err != nil {
		return
	}

	select {
	case client.Send <- data:
	default:
		// Client send buffer full, disconnect
		h.unregister <- client
	}
}

func (h *Hub) SendToBooking(bookingID string, event Event) {
	if h.bookingLookup == nil {
		return
	}
	participants, err := h.bookingLookup.GetBookingParticipants(context.Background(), bookingID)
	if err != nil {
		return
	}
	if participants.UserID != "" {
		h.SendToUser(participants.UserID, event)
	}
	if participants.TechnicianID != "" {
		h.SendToUser(participants.TechnicianID, event)
	}
}

func (h *Hub) IsOnline(userID string) bool {
	h.mu.RLock()
	defer h.mu.RUnlock()
	_, ok := h.clients[userID]
	return ok
}

func ServeWS(hub *Hub, c *gin.Context, cfg *config.Config) {
	// Authenticate via query param token
	tokenStr := c.Query("token")
	if tokenStr == "" {
		authHeader := c.GetHeader("Authorization")
		tokenStr = strings.TrimPrefix(authHeader, "Bearer ")
	}

	if tokenStr == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "token required"})
		return
	}

	token, err := jwt.Parse(tokenStr, func(token *jwt.Token) (interface{}, error) {
		return []byte(cfg.JWTSecret), nil
	})

	if err != nil || !token.Valid {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
		return
	}

	claims := token.Claims.(jwt.MapClaims)
	userID := claims["sub"].(string)
	role := claims["role"].(string)

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("WebSocket upgrade error: %v", err)
		return
	}

	client := &Client{
		Hub:    hub,
		Conn:   conn,
		Send:   make(chan []byte, 256),
		UserID: userID,
		Role:   role,
	}

	hub.register <- client

	go client.writePump()
	go client.readPump()
}

func (c *Client) readPump() {
	defer func() {
		c.Hub.unregister <- c
		c.Conn.Close()
	}()

	c.Conn.SetReadLimit(512 * 1024) // 512KB
	c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	c.Conn.SetPongHandler(func(string) error {
		c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		_, message, err := c.Conn.ReadMessage()
		if err != nil {
			break
		}

		// Handle incoming messages (e.g., location updates, chat messages)
		var raw map[string]interface{}
		if err := json.Unmarshal(message, &raw); err != nil {
			continue
		}

		// Support both "event" and "type" keys from clients
		eventType := ""
		if v, ok := raw["event"].(string); ok {
			eventType = v
		} else if v, ok := raw["type"].(string); ok {
			eventType = v
		}
		data, _ := raw["data"].(map[string]interface{})
		if data == nil {
			data = raw
		}

		// Process event based on type
		switch eventType {
		case "technician_location":
			// Look up the active booking for this technician and forward location to the customer
			if c.Hub.bookingLookup != nil {
				participants, bookingID, err := c.Hub.bookingLookup.GetActiveTechnicianBooking(context.Background(), c.UserID)
				if err == nil && participants != nil && participants.UserID != "" {
					lat, _ := data["latitude"].(float64)
					lng, _ := data["longitude"].(float64)
					c.Hub.SendToUser(participants.UserID, Event{
						Type: "technician_location_update",
						Data: map[string]interface{}{
							"booking_id": bookingID,
							"latitude":   lat,
							"longitude":  lng,
						},
					})
				}
			}
		case "chat_message":
			// Forward chat message to the other party in the booking
			if bookingID, ok := data["booking_id"].(string); ok && c.Hub.bookingLookup != nil {
				participants, err := c.Hub.bookingLookup.GetBookingParticipants(context.Background(), bookingID)
				if err == nil && participants != nil {
					msg := data["message"]
					if msg == nil {
						msg = data["content"]
					}
					// Determine recipient: send to the other party
					recipientID := participants.UserID
					if c.UserID == participants.UserID {
						recipientID = participants.TechnicianID
					}
					if recipientID != "" {
						c.Hub.SendToUser(recipientID, Event{
							Type: "chat_message",
							Data: map[string]interface{}{
								"booking_id": bookingID,
								"sender_id":  c.UserID,
								"message":    msg,
								"content":    msg,
								"created_at": time.Now().UTC().Format(time.RFC3339),
							},
						})
					}
				}
			}
		case "ping":
			// Heartbeat - no action needed
		}
	}
}

func (c *Client) writePump() {
	ticker := time.NewTicker(30 * time.Second)
	defer func() {
		ticker.Stop()
		c.Conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.Send:
			c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				c.Conn.WriteMessage(ws.CloseMessage, []byte{})
				return
			}

			c.mu.Lock()
			err := c.Conn.WriteMessage(ws.TextMessage, message)
			c.mu.Unlock()
			if err != nil {
				return
			}

		case <-ticker.C:
			c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.Conn.WriteMessage(ws.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
