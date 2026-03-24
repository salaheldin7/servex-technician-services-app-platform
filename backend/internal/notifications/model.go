package notifications

import (
	"time"

	"github.com/google/uuid"
)

type Notification struct {
	ID        uuid.UUID         `json:"id"`
	UserID    uuid.UUID         `json:"user_id"`
	Title     string            `json:"title"`
	Body      string            `json:"body"`
	Type      string            `json:"type"`
	Data      map[string]string `json:"data"`
	IsRead    bool              `json:"is_read"`
	CreatedAt time.Time         `json:"created_at"`
}

type CreateNotificationRequest struct {
	UserID string            `json:"user_id"`
	Title  string            `json:"title"`
	Body   string            `json:"body"`
	Type   string            `json:"type"`
	Data   map[string]string `json:"data"`
}
