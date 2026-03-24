package notifications

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	db *pgxpool.Pool
}

func NewRepository(db *pgxpool.Pool) *Repository {
	return &Repository{db: db}
}

func (r *Repository) Create(ctx context.Context, notif *Notification) error {
	query := `
		INSERT INTO notifications (id, user_id, title, body, type, data, is_read, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, false, NOW())
	`
	notif.ID = uuid.New()
	dataJSON, _ := json.Marshal(notif.Data)
	_, err := r.db.Exec(ctx, query,
		notif.ID, notif.UserID, notif.Title, notif.Body, notif.Type, dataJSON,
	)
	return err
}

func (r *Repository) GetByUser(ctx context.Context, userID uuid.UUID, page, pageSize int) ([]Notification, int, error) {
	offset := (page - 1) * pageSize

	countQuery := `SELECT COUNT(*) FROM notifications WHERE user_id = $1`
	var total int
	if err := r.db.QueryRow(ctx, countQuery, userID).Scan(&total); err != nil {
		return nil, 0, err
	}

	query := `
		SELECT id, user_id, title, body, type, COALESCE(data, '{}'), is_read, created_at
		FROM notifications WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`
	rows, err := r.db.Query(ctx, query, userID, pageSize, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var notifs []Notification
	for rows.Next() {
		var n Notification
		var dataJSON []byte
		if err := rows.Scan(&n.ID, &n.UserID, &n.Title, &n.Body, &n.Type, &dataJSON, &n.IsRead, &n.CreatedAt); err != nil {
			return nil, 0, err
		}
		if len(dataJSON) > 0 {
			json.Unmarshal(dataJSON, &n.Data)
		}
		if n.Data == nil {
			n.Data = make(map[string]string)
		}
		notifs = append(notifs, n)
	}
	return notifs, total, nil
}

func (r *Repository) CountUnread(ctx context.Context, userID uuid.UUID) (int, error) {
	query := `SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND is_read = false`
	var count int
	err := r.db.QueryRow(ctx, query, userID).Scan(&count)
	return count, err
}

func (r *Repository) MarkRead(ctx context.Context, notifID uuid.UUID) error {
	query := `UPDATE notifications SET is_read = true WHERE id = $1`
	_, err := r.db.Exec(ctx, query, notifID)
	return err
}

func (r *Repository) MarkAllRead(ctx context.Context, userID uuid.UUID) error {
	query := `UPDATE notifications SET is_read = true WHERE user_id = $1 AND is_read = false`
	_, err := r.db.Exec(ctx, query, userID)
	return err
}

func (r *Repository) Delete(ctx context.Context, notifID uuid.UUID) error {
	query := `DELETE FROM notifications WHERE id = $1`
	_, err := r.db.Exec(ctx, query, notifID)
	return err
}

func (r *Repository) GetByID(ctx context.Context, id uuid.UUID) (*Notification, error) {
	query := `
		SELECT id, user_id, title, body, type, COALESCE(data, '{}'), is_read, created_at
		FROM notifications WHERE id = $1
	`
	var n Notification
	var dataJSON []byte
	err := r.db.QueryRow(ctx, query, id).Scan(&n.ID, &n.UserID, &n.Title, &n.Body, &n.Type, &dataJSON, &n.IsRead, &n.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("notification not found: %w", err)
	}
	if len(dataJSON) > 0 {
		json.Unmarshal(dataJSON, &n.Data)
	}
	if n.Data == nil {
		n.Data = make(map[string]string)
	}
	return &n, nil
}
