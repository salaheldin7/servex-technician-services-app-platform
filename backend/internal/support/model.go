package support

import (
	"time"

	"github.com/google/uuid"
)

type Ticket struct {
	ID          uuid.UUID  `json:"id"`
	UserID      uuid.UUID  `json:"user_id"`
	AssignedTo  *uuid.UUID `json:"assigned_to,omitempty"`
	Subject     string     `json:"subject"`
	Description string     `json:"description"`
	Status      string     `json:"status"`   // open, in_progress, resolved, closed
	Priority    string     `json:"priority"` // low, medium, high
	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`

	UserName string `json:"user_name,omitempty"`
}

type TicketMessage struct {
	ID         uuid.UUID `json:"id"`
	TicketID   uuid.UUID `json:"ticket_id"`
	SenderID   uuid.UUID `json:"sender_id"`
	Content    string    `json:"content"`
	IsAdmin    bool      `json:"is_admin"`
	SenderName string    `json:"sender_name,omitempty"`
	CreatedAt  time.Time `json:"created_at"`
}

type CreateTicketRequest struct {
	Subject     string `json:"subject" binding:"required"`
	Description string `json:"description" binding:"required"`
	Priority    string `json:"priority" binding:"omitempty,oneof=low medium high"`
}

type AddMessageRequest struct {
	Content string `json:"content" binding:"required"`
}
