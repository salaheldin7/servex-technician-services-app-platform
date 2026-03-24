package ratings

import (
	"time"

	"github.com/google/uuid"
)

type Rating struct {
	ID           uuid.UUID `json:"id"`
	BookingID    uuid.UUID `json:"booking_id"`
	UserID       uuid.UUID `json:"user_id"`
	TechnicianID uuid.UUID `json:"technician_id"`
	Score        int       `json:"score"` // 1-5
	Comment      string    `json:"comment,omitempty"`
	CreatedAt    time.Time `json:"created_at"`

	UserName string `json:"user_name,omitempty"`
}

type CreateRatingRequest struct {
	Score   int    `json:"score" binding:"required,min=1,max=5"`
	Comment string `json:"comment"`
}
