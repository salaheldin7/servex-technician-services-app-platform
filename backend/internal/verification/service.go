package verification

import (
	"context"

	"github.com/google/uuid"
	"github.com/techapp/backend/internal/notifications"
)

type Service struct {
	repo         *Repository
	notifService *notifications.Service
}

func NewService(repo *Repository, notifService *notifications.Service) *Service {
	return &Service{repo: repo, notifService: notifService}
}

func (s *Service) GetTechnicianID(ctx context.Context, userID uuid.UUID) (uuid.UUID, error) {
	return s.repo.GetTechnicianIDByUserID(ctx, userID)
}

func (s *Service) UploadFace(ctx context.Context, techID uuid.UUID, front, right, left string) error {
	v := &FaceVerification{
		TechnicianID: techID,
		FaceFrontURL: front,
		FaceRightURL: right,
		FaceLeftURL:  left,
	}
	return s.repo.SaveFaceVerification(ctx, v)
}

func (s *Service) GetFaceVerification(ctx context.Context, techID uuid.UUID) (*FaceVerification, error) {
	return s.repo.GetFaceVerification(ctx, techID)
}

func (s *Service) SaveIDDocument(ctx context.Context, doc *IDDocument) error {
	return s.repo.SaveIDDocument(ctx, doc)
}

func (s *Service) NotifyApplicationSubmitted(ctx context.Context, techID uuid.UUID) {
	// Get user_id from technician
	var userID string
	err := s.repo.db.QueryRow(ctx, `SELECT u.id FROM users u JOIN technician_profiles tp ON tp.user_id = u.id WHERE tp.id = $1`, techID).Scan(&userID)
	if err != nil || s.notifService == nil {
		return
	}
	s.notifService.SendPush(&notifications.PushNotification{
		UserID: userID,
		Title:  "Application Submitted",
		Body:   "Your verification application has been submitted and is under review.",
		Data:   map[string]string{"type": "verification_submitted"},
	})
}

func (s *Service) GetIDDocuments(ctx context.Context, techID uuid.UUID) ([]IDDocument, error) {
	return s.repo.GetIDDocuments(ctx, techID)
}

func (s *Service) AddServices(ctx context.Context, techID uuid.UUID, services []AddServiceRequest) error {
	return s.repo.AddServices(ctx, techID, services)
}

func (s *Service) GetServices(ctx context.Context, techID uuid.UUID) ([]TechnicianService, error) {
	return s.repo.GetServices(ctx, techID)
}

func (s *Service) RemoveService(ctx context.Context, techID, serviceID uuid.UUID) error {
	return s.repo.RemoveService(ctx, techID, serviceID)
}

func (s *Service) AddLocations(ctx context.Context, techID uuid.UUID, locs []AddLocationRequest) error {
	return s.repo.AddLocations(ctx, techID, locs)
}

func (s *Service) GetLocations(ctx context.Context, techID uuid.UUID) ([]ServiceLocation, error) {
	return s.repo.GetLocations(ctx, techID)
}

func (s *Service) RemoveLocation(ctx context.Context, techID, locID uuid.UUID) error {
	return s.repo.RemoveLocation(ctx, techID, locID)
}

func (s *Service) GetVerificationStatus(ctx context.Context, techID uuid.UUID) (*VerificationStatus, error) {
	return s.repo.GetVerificationStatus(ctx, techID)
}
