package ratings

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/techapp/backend/internal/technicians"
)

type Service struct {
	repo     *Repository
	techRepo *technicians.Repository
}

func NewService(repo *Repository, techRepo *technicians.Repository) *Service {
	return &Service{repo: repo, techRepo: techRepo}
}

func (s *Service) Create(ctx context.Context, bookingID, userID, techID uuid.UUID, req *CreateRatingRequest) error {
	exists, err := s.repo.Exists(ctx, bookingID, userID)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("rating already submitted for this booking")
	}

	rating := &Rating{
		BookingID:    bookingID,
		UserID:       userID,
		TechnicianID: techID,
		Score:        req.Score,
		Comment:      req.Comment,
	}

	if err := s.repo.Create(ctx, rating); err != nil {
		return err
	}

	// Recalculate average rating
	avg, err := s.repo.GetAvgRating(ctx, techID)
	if err != nil {
		return nil // Non-critical
	}
	s.techRepo.UpdateRating(ctx, techID, avg)

	return nil
}

func (s *Service) GetTechnicianRatings(ctx context.Context, techID uuid.UUID, page, pageSize int) ([]Rating, float64, error) {
	return s.repo.GetByTechnician(ctx, techID, page, pageSize)
}
