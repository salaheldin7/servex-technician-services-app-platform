package categories

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	db *pgxpool.Pool
}

func NewRepository(db *pgxpool.Pool) *Repository {
	return &Repository{db: db}
}

func (r *Repository) Create(ctx context.Context, cat *Category) error {
	cat.ID = uuid.New()
	now := time.Now().UTC()
	cat.CreatedAt = now
	cat.UpdatedAt = now
	cat.IsActive = true

	query := `INSERT INTO categories (id, parent_id, type, name_en, name_ar, icon, sort_order, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`
	_, err := r.db.Exec(ctx, query, cat.ID, cat.ParentID, cat.Type, cat.NameEN, cat.NameAR,
		cat.Icon, cat.SortOrder, cat.IsActive, cat.CreatedAt, cat.UpdatedAt)
	return err
}

func (r *Repository) GetByID(ctx context.Context, id uuid.UUID) (*Category, error) {
	query := `SELECT id, parent_id, type, name_en, name_ar, icon, sort_order, is_active, created_at, updated_at
		FROM categories WHERE id = $1`
	cat := &Category{}
	err := r.db.QueryRow(ctx, query, id).Scan(&cat.ID, &cat.ParentID, &cat.Type, &cat.NameEN, &cat.NameAR,
		&cat.Icon, &cat.SortOrder, &cat.IsActive, &cat.CreatedAt, &cat.UpdatedAt)
	return cat, err
}

func (r *Repository) ListTree(ctx context.Context, lang string) ([]Category, error) {
	// Get all root categories first
	query := `SELECT id, parent_id, type, name_en, name_ar, icon, sort_order, is_active, created_at, updated_at
		FROM categories WHERE parent_id IS NULL AND is_active = true ORDER BY sort_order`
	rows, err := r.db.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var roots []Category
	for rows.Next() {
		var c Category
		err := rows.Scan(&c.ID, &c.ParentID, &c.Type, &c.NameEN, &c.NameAR, &c.Icon,
			&c.SortOrder, &c.IsActive, &c.CreatedAt, &c.UpdatedAt)
		if err != nil {
			return nil, err
		}

		// Get children
		children, err := r.getChildren(ctx, c.ID)
		if err != nil {
			return nil, err
		}
		c.Children = children

		roots = append(roots, c)
	}

	return roots, nil
}

func (r *Repository) getChildren(ctx context.Context, parentID uuid.UUID) ([]Category, error) {
	query := `SELECT id, parent_id, type, name_en, name_ar, icon, sort_order, is_active, created_at, updated_at
		FROM categories WHERE parent_id = $1 AND is_active = true ORDER BY sort_order`
	rows, err := r.db.Query(ctx, query, parentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var children []Category
	for rows.Next() {
		var c Category
		err := rows.Scan(&c.ID, &c.ParentID, &c.Type, &c.NameEN, &c.NameAR, &c.Icon,
			&c.SortOrder, &c.IsActive, &c.CreatedAt, &c.UpdatedAt)
		if err != nil {
			return nil, err
		}
		children = append(children, c)
	}
	return children, nil
}

func (r *Repository) Update(ctx context.Context, id uuid.UUID, req *UpdateCategoryRequest) error {
	query := `UPDATE categories SET
		name_en = COALESCE(NULLIF($1, ''), name_en),
		name_ar = COALESCE(NULLIF($2, ''), name_ar),
		icon = COALESCE(NULLIF($3, ''), icon),
		sort_order = CASE WHEN $4 > 0 THEN $4 ELSE sort_order END,
		updated_at = $5
		WHERE id = $6`
	_, err := r.db.Exec(ctx, query, req.NameEN, req.NameAR, req.Icon, req.SortOrder, time.Now().UTC(), id)
	return err
}

func (r *Repository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `UPDATE categories SET is_active = false, updated_at = $1 WHERE id = $2`
	_, err := r.db.Exec(ctx, query, time.Now().UTC(), id)
	return err
}
