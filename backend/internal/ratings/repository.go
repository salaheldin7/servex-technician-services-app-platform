package ratings

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

func (r *Repository) Create(ctx context.Context, rating *Rating) error {
	rating.ID = uuid.New()
	rating.CreatedAt = time.Now().UTC()
	query := `INSERT INTO ratings (id, booking_id, user_id, technician_id, score, comment, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)`
	_, err := r.db.Exec(ctx, query, rating.ID, rating.BookingID, rating.UserID,
		rating.TechnicianID, rating.Score, rating.Comment, rating.CreatedAt)
	return err
}

func (r *Repository) GetByTechnician(ctx context.Context, techID uuid.UUID, page, pageSize int) ([]Rating, float64, error) {
	offset := (page - 1) * pageSize

	var avgRating float64
	err := r.db.QueryRow(ctx,
		`SELECT COALESCE(AVG(score), 0) FROM ratings WHERE technician_id = $1`, techID).Scan(&avgRating)
	if err != nil {
		return nil, 0, err
	}

	query := `SELECT r.id, r.booking_id, r.user_id, r.technician_id, r.score, r.comment, r.created_at,
		u.full_name as user_name
		FROM ratings r JOIN users u ON u.id = r.user_id
		WHERE r.technician_id = $1 ORDER BY r.created_at DESC LIMIT $2 OFFSET $3`

	rows, err := r.db.Query(ctx, query, techID, pageSize, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var ratings []Rating
	for rows.Next() {
		var rt Rating
		err := rows.Scan(&rt.ID, &rt.BookingID, &rt.UserID, &rt.TechnicianID,
			&rt.Score, &rt.Comment, &rt.CreatedAt, &rt.UserName)
		if err != nil {
			return nil, 0, err
		}
		ratings = append(ratings, rt)
	}

	return ratings, avgRating, nil
}

func (r *Repository) GetAvgRating(ctx context.Context, techID uuid.UUID) (float64, error) {
	var avg float64
	err := r.db.QueryRow(ctx,
		`SELECT COALESCE(AVG(score), 0) FROM ratings WHERE technician_id = $1`, techID).Scan(&avg)
	return avg, err
}

func (r *Repository) Exists(ctx context.Context, bookingID, userID uuid.UUID) (bool, error) {
	var exists bool
	err := r.db.QueryRow(ctx,
		`SELECT EXISTS(SELECT 1 FROM ratings WHERE booking_id = $1 AND user_id = $2)`,
		bookingID, userID).Scan(&exists)
	return exists, err
}
