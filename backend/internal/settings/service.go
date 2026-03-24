package settings

import (
	"context"

	"github.com/google/uuid"
	"github.com/techapp/backend/internal/auth"
)

type Service struct {
	repo        *Repository
	authService *auth.Service
}

func NewService(repo *Repository, authService *auth.Service) *Service {
	return &Service{repo: repo, authService: authService}
}

func (s *Service) ChangeName(ctx context.Context, userID uuid.UUID, name string) error {
	return s.repo.UpdateName(ctx, userID, name)
}

func (s *Service) ChangePhone(ctx context.Context, userID uuid.UUID, phone, otp string) error {
	// Verify OTP before changing phone
	// TODO: Verify OTP via auth service
	return s.repo.UpdatePhone(ctx, userID, phone)
}

func (s *Service) ChangeEmail(ctx context.Context, userID uuid.UUID, email string) error {
	return s.repo.UpdateEmail(ctx, userID, email)
}

func (s *Service) ChangeLanguage(ctx context.Context, userID uuid.UUID, language string) error {
	return s.repo.UpdateLanguage(ctx, userID, language)
}

func (s *Service) DeleteAccount(ctx context.Context, userID uuid.UUID) error {
	// Soft delete — 30 day retention
	return s.repo.SoftDelete(ctx, userID)
}
