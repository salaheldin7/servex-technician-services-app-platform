package payments

import (
	"time"

	"github.com/google/uuid"
)

type Payment struct {
	ID            uuid.UUID `json:"id"`
	BookingID     uuid.UUID `json:"booking_id"`
	UserID        uuid.UUID `json:"user_id"`
	TechnicianID  uuid.UUID `json:"technician_id"`
	Amount        float64   `json:"amount"`
	Commission    float64   `json:"commission"`
	TechnicianPay float64   `json:"technician_pay"`
	Method        string    `json:"method"` // card, cash
	Status        string    `json:"status"` // pending, completed, failed, refunded
	GatewayRef    string    `json:"gateway_ref,omitempty"`
	CreatedAt     time.Time `json:"created_at"`
}

type ProcessPaymentRequest struct {
	Amount float64 `json:"amount" binding:"required,gt=0"`
	Method string  `json:"method" binding:"required,oneof=card cash"`
}
