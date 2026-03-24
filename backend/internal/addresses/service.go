package addresses

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

func (s *Service) Create(ctx context.Context, addr *Address) error {
	return s.repo.Create(ctx, addr)
}

func (s *Service) ListByUser(ctx context.Context, userID uuid.UUID) ([]Address, error) {
	return s.repo.GetByUser(ctx, userID)
}

func (s *Service) GetByID(ctx context.Context, id uuid.UUID) (*Address, error) {
	return s.repo.GetByID(ctx, id)
}

func (s *Service) GetDefault(ctx context.Context, userID uuid.UUID) (*Address, error) {
	return s.repo.GetDefault(ctx, userID)
}

func (s *Service) SetDefault(ctx context.Context, userID, addressID uuid.UUID) error {
	return s.repo.SetDefault(ctx, userID, addressID)
}

func (s *Service) Delete(ctx context.Context, id uuid.UUID) error {
	return s.repo.Delete(ctx, id)
}
