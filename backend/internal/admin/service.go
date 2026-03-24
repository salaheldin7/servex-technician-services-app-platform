package admin

import (
	"context"

	"github.com/google/uuid"
	"github.com/techapp/backend/internal/bookings"
	"github.com/techapp/backend/internal/notifications"
	"github.com/techapp/backend/internal/technicians"
	"github.com/techapp/backend/internal/users"
)

type Service struct {
	repo         *Repository
	userRepo     *users.Repository
	techRepo     *technicians.Repository
	bookRepo     *bookings.Repository
	notifService *notifications.Service
}

func NewService(repo *Repository, userRepo *users.Repository, techRepo *technicians.Repository, bookRepo *bookings.Repository, notifService *notifications.Service) *Service {
	return &Service{repo: repo, userRepo: userRepo, techRepo: techRepo, bookRepo: bookRepo, notifService: notifService}
}

func (s *Service) Dashboard(ctx context.Context) (*DashboardStats, error) {
	return s.repo.GetDashboardStats(ctx)
}

func (s *Service) ListUsers(ctx context.Context, page, pageSize int, role string) ([]users.User, int, error) {
	return s.userRepo.List(ctx, page, pageSize, role)
}

func (s *Service) GetUser(ctx context.Context, id uuid.UUID) (*users.User, error) {
	return s.userRepo.GetByID(ctx, id)
}

func (s *Service) BanUser(ctx context.Context, id uuid.UUID) error {
	return s.userRepo.SetActive(ctx, id, false)
}

func (s *Service) ListTechnicians(ctx context.Context, page, pageSize int, verified *bool, statuses ...string) ([]technicians.TechnicianProfile, int, error) {
	return s.techRepo.List(ctx, page, pageSize, verified, statuses...)
}

func (s *Service) GetTechnician(ctx context.Context, id uuid.UUID) (*technicians.TechnicianProfile, error) {
	return s.techRepo.GetByID(ctx, id)
}

func (s *Service) VerifyTechnician(ctx context.Context, id uuid.UUID, verified bool) error {
	return s.techRepo.Verify(ctx, id, verified)
}

func (s *Service) BanTechnician(ctx context.Context, userID uuid.UUID) error {
	return s.userRepo.SetActive(ctx, userID, false)
}

func (s *Service) UnbanTechnician(ctx context.Context, userID uuid.UUID) error {
	return s.userRepo.SetActive(ctx, userID, true)
}

func (s *Service) UnbanUser(ctx context.Context, id uuid.UUID) error {
	return s.repo.UnbanUser(ctx, id)
}

func (s *Service) DeleteUser(ctx context.Context, id uuid.UUID) error {
	return s.repo.DeleteUser(ctx, id)
}

func (s *Service) ResetUserPassword(ctx context.Context, id uuid.UUID, hashedPassword string) error {
	return s.repo.ResetUserPassword(ctx, id, hashedPassword)
}

func (s *Service) GetTechnicianVerificationDetail(ctx context.Context, techID uuid.UUID) (*TechnicianVerificationDetail, error) {
	return s.repo.GetTechnicianVerificationDetail(ctx, techID)
}

func (s *Service) ApproveTechnician(ctx context.Context, techID uuid.UUID) error {
	// Set is_verified and verification_status
	if err := s.techRepo.Verify(ctx, techID, true); err != nil {
		return err
	}
	// Clear any old rejection reason
	_ = s.techRepo.SetRejectionReason(ctx, techID, "")

	// Send notification to technician
	tech, err := s.techRepo.GetByID(ctx, techID)
	if err == nil && tech != nil {
		s.notifService.SendPush(&notifications.PushNotification{
			UserID: tech.UserID.String(),
			Title:  "Verification Approved",
			Body:   "Congratulations! Your account has been verified. You can now go online and start receiving jobs.",
			Data:   map[string]string{"type": "verification_approved"},
		})
	}
	return nil
}

func (s *Service) RejectTechnician(ctx context.Context, techID uuid.UUID, reason string) error {
	if err := s.techRepo.Verify(ctx, techID, false); err != nil {
		return err
	}

	if reason == "" {
		reason = "Your verification has been rejected. Please re-submit your documents."
	}

	// Store rejection reason on profile
	_ = s.techRepo.SetRejectionReason(ctx, techID, reason)

	// Send notification to technician
	tech, err := s.techRepo.GetByID(ctx, techID)
	if err == nil && tech != nil {
		s.notifService.SendPush(&notifications.PushNotification{
			UserID: tech.UserID.String(),
			Title:  "Verification Rejected",
			Body:   reason,
			Data:   map[string]string{"type": "verification_rejected", "reason": reason},
		})
	}
	return nil
}

func (s *Service) ListBookings(ctx context.Context, page, pageSize int, status string) ([]bookings.Booking, int, error) {
	return s.bookRepo.ListAll(ctx, page, pageSize, status)
}

func (s *Service) GetBooking(ctx context.Context, id uuid.UUID) (*bookings.Booking, error) {
	return s.bookRepo.GetByID(ctx, id)
}

func (s *Service) RevenueReport(ctx context.Context, days int) ([]RevenueData, error) {
	return s.repo.GetRevenueReport(ctx, days)
}

func (s *Service) BookingReport(ctx context.Context, days int) ([]BookingReportData, error) {
	return s.repo.GetBookingReport(ctx, days)
}
