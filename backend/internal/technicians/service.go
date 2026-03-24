package technicians

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

func (s *Service) Register(ctx context.Context, userID uuid.UUID, req *RegisterRequest) (*TechnicianProfile, error) {
	profile := &TechnicianProfile{
		UserID:     userID,
		Bio:        req.Bio,
		HourlyRate: req.HourlyRate,
		NationalID: req.NationalID,
	}

	if err := s.repo.Create(ctx, profile); err != nil {
		return nil, err
	}

	return s.repo.GetByUserID(ctx, userID)
}

func (s *Service) GetProfile(ctx context.Context, userID uuid.UUID) (*TechnicianProfile, error) {
	return s.repo.GetByUserID(ctx, userID)
}

func (s *Service) UpdateProfile(ctx context.Context, userID uuid.UUID, req *UpdateProfileRequest) error {
	return s.repo.Update(ctx, userID, req)
}

func (s *Service) SetOnline(ctx context.Context, userID uuid.UUID, online bool) error {
	return s.repo.SetOnline(ctx, userID, online)
}

func (s *Service) UpdateLocation(ctx context.Context, userID uuid.UUID, lat, lng float64) error {
	return s.repo.UpdateLocation(ctx, userID, lat, lng)
}

func (s *Service) GetNearby(ctx context.Context, query *NearbyQuery) ([]TechnicianProfile, error) {
	radius := query.Radius
	if radius == 0 {
		radius = 5000
	}
	return s.repo.FindNearby(ctx, query.Lat, query.Lng, radius, query.CategoryID)
}

func (s *Service) SearchByServiceAndLocation(ctx context.Context, categoryID, countryID, governorateID, cityID string) ([]TechnicianProfile, error) {
	return s.repo.SearchByServiceAndLocation(ctx, categoryID, countryID, governorateID, cityID)
}

func (s *Service) AutoAssign(ctx context.Context, categoryID, countryID, governorateID, cityID string) (*TechnicianProfile, error) {
	return s.repo.AutoAssign(ctx, categoryID, countryID, governorateID, cityID)
}
