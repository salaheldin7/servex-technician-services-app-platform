package locations

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

func (s *Service) ListCountries(ctx context.Context) ([]Country, error) {
	return s.repo.ListCountries(ctx)
}

func (s *Service) ListGovernorates(ctx context.Context, countryID uuid.UUID) ([]Governorate, error) {
	return s.repo.ListGovernorates(ctx, countryID)
}

func (s *Service) ListCities(ctx context.Context, governorateID uuid.UUID) ([]City, error) {
	return s.repo.ListCities(ctx, governorateID)
}
