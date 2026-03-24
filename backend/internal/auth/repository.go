package auth

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

func (r *Repository) CreateUser(ctx context.Context, user *User) error {
	query := `
		INSERT INTO users (id, email, phone, username, password_hash, full_name, role, language, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`
	user.ID = uuid.New()
	now := time.Now().UTC()
	user.CreatedAt = now
	user.UpdatedAt = now

	_, err := r.db.Exec(ctx, query,
		user.ID, user.Email, user.Phone, user.Username, user.PasswordHash,
		user.FullName, user.Role, user.Language, user.CreatedAt, user.UpdatedAt,
	)
	return err
}

func (r *Repository) GetByEmail(ctx context.Context, email string) (*User, error) {
	query := `
		SELECT id, email, phone, COALESCE(username,''), password_hash, full_name, avatar_url, role, is_active, language, created_at, updated_at
		FROM users WHERE email = $1 AND deleted_at IS NULL
	`
	user := &User{}
	err := r.db.QueryRow(ctx, query, email).Scan(
		&user.ID, &user.Email, &user.Phone, &user.Username, &user.PasswordHash,
		&user.FullName, &user.AvatarURL, &user.Role, &user.IsActive,
		&user.Language, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("user not found: %w", err)
	}
	return user, nil
}

func (r *Repository) GetByPhone(ctx context.Context, phone string) (*User, error) {
	query := `
		SELECT id, email, phone, COALESCE(username,''), password_hash, full_name, avatar_url, role, is_active, language, created_at, updated_at
		FROM users WHERE phone = $1 AND deleted_at IS NULL
	`
	user := &User{}
	err := r.db.QueryRow(ctx, query, phone).Scan(
		&user.ID, &user.Email, &user.Phone, &user.Username, &user.PasswordHash,
		&user.FullName, &user.AvatarURL, &user.Role, &user.IsActive,
		&user.Language, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("user not found: %w", err)
	}
	return user, nil
}

func (r *Repository) GetByID(ctx context.Context, id uuid.UUID) (*User, error) {
	query := `
		SELECT id, email, phone, COALESCE(username,''), password_hash, full_name, avatar_url, role, is_active, language, created_at, updated_at
		FROM users WHERE id = $1 AND deleted_at IS NULL
	`
	user := &User{}
	err := r.db.QueryRow(ctx, query, id).Scan(
		&user.ID, &user.Email, &user.Phone, &user.Username, &user.PasswordHash,
		&user.FullName, &user.AvatarURL, &user.Role, &user.IsActive,
		&user.Language, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("user not found: %w", err)
	}
	return user, nil
}

func (r *Repository) UpdateDeviceToken(ctx context.Context, userID uuid.UUID, token string) error {
	query := `UPDATE users SET device_token = $1, updated_at = $2 WHERE id = $3`
	_, err := r.db.Exec(ctx, query, token, time.Now().UTC(), userID)
	return err
}

func (r *Repository) EmailExists(ctx context.Context, email string) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM users WHERE email = $1 AND deleted_at IS NULL)`
	var exists bool
	err := r.db.QueryRow(ctx, query, email).Scan(&exists)
	return exists, err
}

func (r *Repository) PhoneExists(ctx context.Context, phone string) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM users WHERE phone = $1 AND deleted_at IS NULL)`
	var exists bool
	err := r.db.QueryRow(ctx, query, phone).Scan(&exists)
	return exists, err
}

func (r *Repository) UsernameExists(ctx context.Context, username string) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM users WHERE username = $1 AND deleted_at IS NULL)`
	var exists bool
	err := r.db.QueryRow(ctx, query, username).Scan(&exists)
	return exists, err
}

func (r *Repository) GetByUsername(ctx context.Context, username string) (*User, error) {
	query := `
		SELECT id, email, phone, COALESCE(username,''), password_hash, full_name, avatar_url, role, is_active, language, created_at, updated_at
		FROM users WHERE username = $1 AND deleted_at IS NULL
	`
	user := &User{}
	err := r.db.QueryRow(ctx, query, username).Scan(
		&user.ID, &user.Email, &user.Phone, &user.Username, &user.PasswordHash,
		&user.FullName, &user.AvatarURL, &user.Role, &user.IsActive,
		&user.Language, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("user not found: %w", err)
	}
	return user, nil
}

func (r *Repository) UpdateUsername(ctx context.Context, userID uuid.UUID, username string) error {
	query := `UPDATE users SET username = $1, updated_at = $2 WHERE id = $3`
	_, err := r.db.Exec(ctx, query, username, time.Now().UTC(), userID)
	return err
}

func (r *Repository) CreateTechnicianProfile(ctx context.Context, userID uuid.UUID) error {
	query := `
		INSERT INTO technician_profiles (id, user_id, bio, hourly_rate, national_id, verification_status, created_at, updated_at)
		VALUES ($1, $2, '', 0, '', 'none', $3, $3)
		ON CONFLICT (user_id) DO NOTHING
	`
	now := time.Now().UTC()
	_, err := r.db.Exec(ctx, query, uuid.New(), userID, now)
	return err
}
