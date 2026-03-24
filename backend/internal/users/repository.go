package users

import (
	"context"
	"fmt"
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

func (r *Repository) GetByID(ctx context.Context, id uuid.UUID) (*User, error) {
	query := `
		SELECT id, email, phone, COALESCE(username,''), full_name, avatar_url, role, is_active, language, property_type, created_at, updated_at
		FROM users WHERE id = $1 AND deleted_at IS NULL
	`
	user := &User{}
	err := r.db.QueryRow(ctx, query, id).Scan(
		&user.ID, &user.Email, &user.Phone, &user.Username, &user.FullName,
		&user.AvatarURL, &user.Role, &user.IsActive,
		&user.Language, &user.PropertyType, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("user not found: %w", err)
	}
	return user, nil
}

func (r *Repository) Update(ctx context.Context, id uuid.UUID, req *UpdateProfileRequest) error {
	query := `
		UPDATE users SET full_name = COALESCE(NULLIF($1, ''), full_name),
		avatar_url = COALESCE(NULLIF($2, ''), avatar_url),
		language = COALESCE(NULLIF($3, ''), language),
		property_type = COALESCE(NULLIF($4, ''), property_type),
		updated_at = $5
		WHERE id = $6 AND deleted_at IS NULL
	`
	_, err := r.db.Exec(ctx, query, req.FullName, req.AvatarURL, req.Language, req.PropertyType, time.Now().UTC(), id)
	return err
}

func (r *Repository) SoftDelete(ctx context.Context, id uuid.UUID) error {
	query := `UPDATE users SET deleted_at = $1, is_active = false, updated_at = $1 WHERE id = $2`
	_, err := r.db.Exec(ctx, query, time.Now().UTC(), id)
	return err
}

func (r *Repository) List(ctx context.Context, page, pageSize int, role string) ([]User, int, error) {
	offset := (page - 1) * pageSize

	countQuery := `SELECT COUNT(*) FROM users WHERE deleted_at IS NULL`
	args := []interface{}{}
	argIdx := 1

	if role != "" {
		countQuery += fmt.Sprintf(" AND role = $%d", argIdx)
		args = append(args, role)
		argIdx++
	}

	var total int
	err := r.db.QueryRow(ctx, countQuery, args...).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	query := `
		SELECT id, email, phone, COALESCE(username,''), full_name, avatar_url, role, is_active, language, property_type, created_at, updated_at
		FROM users WHERE deleted_at IS NULL
	`
	if role != "" {
		query += fmt.Sprintf(" AND role = $%d", argIdx-1)
	}
	query += fmt.Sprintf(" ORDER BY created_at DESC LIMIT $%d OFFSET $%d", argIdx, argIdx+1)
	args = append(args, pageSize, offset)

	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var users []User
	for rows.Next() {
		var u User
		err := rows.Scan(&u.ID, &u.Email, &u.Phone, &u.Username, &u.FullName,
			&u.AvatarURL, &u.Role, &u.IsActive,
			&u.Language, &u.PropertyType, &u.CreatedAt, &u.UpdatedAt)
		if err != nil {
			return nil, 0, err
		}
		users = append(users, u)
	}

	return users, total, nil
}

func (r *Repository) SetActive(ctx context.Context, id uuid.UUID, active bool) error {
	query := `UPDATE users SET is_active = $1, updated_at = $2 WHERE id = $3`
	_, err := r.db.Exec(ctx, query, active, time.Now().UTC(), id)
	return err
}

func (r *Repository) CountByRole(ctx context.Context, role string) (int, error) {
	query := `SELECT COUNT(*) FROM users WHERE role = $1 AND deleted_at IS NULL`
	var count int
	err := r.db.QueryRow(ctx, query, role).Scan(&count)
	return count, err
}
