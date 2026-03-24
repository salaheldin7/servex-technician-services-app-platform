package chat

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

func (r *Repository) Create(ctx context.Context, msg *Message) error {
	msg.ID = uuid.New()
	msg.CreatedAt = time.Now().UTC()

	query := `
		INSERT INTO chat_messages (id, booking_id, sender_id, content, type, created_at)
		VALUES ($1, $2, $3, $4, $5, $6)
	`
	_, err := r.db.Exec(ctx, query,
		msg.ID, msg.BookingID, msg.SenderID, msg.Content, msg.Type, msg.CreatedAt,
	)
	return err
}

func (r *Repository) GetByBooking(ctx context.Context, bookingID uuid.UUID, limit, offset int) ([]Message, error) {
	query := `
		SELECT m.id, m.booking_id, m.sender_id, m.content, m.type, m.created_at,
			u.full_name as sender_name
		FROM chat_messages m
		JOIN users u ON u.id = m.sender_id
		WHERE m.booking_id = $1
		ORDER BY m.created_at DESC
		LIMIT $2 OFFSET $3
	`
	rows, err := r.db.Query(ctx, query, bookingID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var messages []Message
	for rows.Next() {
		var m Message
		err := rows.Scan(&m.ID, &m.BookingID, &m.SenderID, &m.Content,
			&m.Type, &m.CreatedAt, &m.SenderName)
		if err != nil {
			return nil, err
		}
		messages = append(messages, m)
	}
	return messages, nil
}
