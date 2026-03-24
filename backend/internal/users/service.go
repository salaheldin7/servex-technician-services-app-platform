package users

import (
	"context"

	"github.com/google/uuid"
)

type Service struct {
	repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{repo: repo}
}

func (s *Service) GetProfile(ctx context.Context, userID uuid.UUID) (*User, error) {
	return s.repo.GetByID(ctx, userID)
}

func (s *Service) UpdateProfile(ctx context.Context, userID uuid.UUID, req *UpdateProfileRequest) error {
	return s.repo.Update(ctx, userID, req)
}

func (s *Service) DeleteAccount(ctx context.Context, userID uuid.UUID) error {
	return s.repo.SoftDelete(ctx, userID)
}
