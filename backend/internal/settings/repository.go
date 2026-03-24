package settings

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

func (r *Repository) UpdateName(ctx context.Context, userID uuid.UUID, name string) error {
	_, err := r.db.Exec(ctx, `UPDATE users SET full_name = $1, updated_at = $2 WHERE id = $3`,
		name, time.Now().UTC(), userID)
	return err
}

func (r *Repository) UpdatePhone(ctx context.Context, userID uuid.UUID, phone string) error {
	_, err := r.db.Exec(ctx, `UPDATE users SET phone = $1, updated_at = $2 WHERE id = $3`,
		phone, time.Now().UTC(), userID)
	return err
}

func (r *Repository) UpdateEmail(ctx context.Context, userID uuid.UUID, email string) error {
	_, err := r.db.Exec(ctx, `UPDATE users SET email = $1, updated_at = $2 WHERE id = $3`,
		email, time.Now().UTC(), userID)
	return err
}

func (r *Repository) UpdateLanguage(ctx context.Context, userID uuid.UUID, language string) error {
	_, err := r.db.Exec(ctx, `UPDATE users SET language = $1, updated_at = $2 WHERE id = $3`,
		language, time.Now().UTC(), userID)
	return err
}

func (r *Repository) SoftDelete(ctx context.Context, userID uuid.UUID) error {
	now := time.Now().UTC()
	_, err := r.db.Exec(ctx, `UPDATE users SET deleted_at = $1, is_active = false, updated_at = $1 WHERE id = $2`, now, userID)
	return err
}
