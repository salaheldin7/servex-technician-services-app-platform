package payments

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/techapp/backend/internal/config"
	"github.com/techapp/backend/internal/wallet"
)

type Service struct {
	repo          *Repository
	walletService *wallet.Service
	cfg           *config.Config
}

func NewService(repo *Repository, walletService *wallet.Service, cfg *config.Config) *Service {
	return &Service{repo: repo, walletService: walletService, cfg: cfg}
}

func (s *Service) ProcessPayment(ctx context.Context, bookingID, userID, technicianID uuid.UUID, amount float64, method string) (*Payment, error) {
	commission := amount * s.cfg.CommissionRate
	technicianPay := amount - commission

	payment := &Payment{
		BookingID:     bookingID,
		UserID:        userID,
		TechnicianID:  technicianID,
		Amount:        amount,
		Commission:    commission,
		TechnicianPay: technicianPay,
		Method:        method,
		Status:        "pending",
	}

	if method == "card" {
		// Process card payment via gateway
		// TODO: Integrate with payment gateway (Stripe/etc)
		payment.Status = "completed"
		payment.GatewayRef = "gateway_" + uuid.New().String()[:8]

		// Auto-split: credit technician, deduct commission
		if err := s.walletService.CreditTechnician(ctx, technicianID, bookingID, technicianPay); err != nil {
			return nil, fmt.Errorf("credit technician: %w", err)
		}
		if err := s.walletService.DeductCommission(ctx, technicianID, bookingID, commission); err != nil {
			return nil, fmt.Errorf("deduct commission: %w", err)
		}
	} else if method == "cash" {
		// Cash payment: create debt for technician (commission owed)
		payment.Status = "completed"

		if err := s.walletService.CreateDebt(ctx, technicianID, bookingID, commission); err != nil {
			return nil, fmt.Errorf("create debt: %w", err)
		}
	}

	if err := s.repo.Create(ctx, payment); err != nil {
		return nil, fmt.Errorf("save payment: %w", err)
	}

	return payment, nil
}

func (s *Service) GetHistory(ctx context.Context, userID uuid.UUID, page, pageSize int) ([]Payment, int, error) {
	return s.repo.ListByUser(ctx, userID, page, pageSize)
}
