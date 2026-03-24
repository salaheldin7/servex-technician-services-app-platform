package chat

import (
	"time"

	"github.com/google/uuid"
)

type Message struct {
	ID        uuid.UUID `json:"id"`
	BookingID uuid.UUID `json:"booking_id"`
	SenderID  uuid.UUID `json:"sender_id"`
	Content   string    `json:"content"`
	Type      string    `json:"type"` // text, image, system
	CreatedAt time.Time `json:"created_at"`

	SenderName string `json:"sender_name,omitempty"`
}

type SendMessageRequest struct {
	Content string `json:"content"`
	Message string `json:"message"`
	Type    string `json:"type" binding:"omitempty,oneof=text image"`
}

// GetContent returns whichever field has content (mobile sends 'message', web may send 'content')
func (r *SendMessageRequest) GetContent() string {
	if r.Content != "" {
		return r.Content
	}
	return r.Message
}
