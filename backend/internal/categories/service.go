package categories

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

func (s *Service) Create(ctx context.Context, req *CreateCategoryRequest) (*Category, error) {
	cat := &Category{
		ParentID:  req.ParentID,
		Type:      req.Type,
		NameEN:    req.NameEN,
		NameAR:    req.NameAR,
		Icon:      req.Icon,
		SortOrder: req.SortOrder,
	}
	if err := s.repo.Create(ctx, cat); err != nil {
		return nil, err
	}
	return cat, nil
}

func (s *Service) Get(ctx context.Context, id uuid.UUID) (*Category, error) {
	return s.repo.GetByID(ctx, id)
}

func (s *Service) List(ctx context.Context, lang string) ([]Category, error) {
	return s.repo.ListTree(ctx, lang)
}

func (s *Service) Update(ctx context.Context, id uuid.UUID, req *UpdateCategoryRequest) error {
	return s.repo.Update(ctx, id, req)
}

func (s *Service) Delete(ctx context.Context, id uuid.UUID) error {
	return s.repo.Delete(ctx, id)
}
