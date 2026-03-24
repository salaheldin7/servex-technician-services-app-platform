package payments

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

func (r *Repository) Create(ctx context.Context, payment *Payment) error {
	payment.ID = uuid.New()
	payment.CreatedAt = time.Now().UTC()

	query := `
		INSERT INTO payments (id, booking_id, user_id, technician_id, amount, commission,
			technician_pay, method, status, gateway_ref, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
	`
	_, err := r.db.Exec(ctx, query,
		payment.ID, payment.BookingID, payment.UserID, payment.TechnicianID,
		payment.Amount, payment.Commission, payment.TechnicianPay,
		payment.Method, payment.Status, payment.GatewayRef, payment.CreatedAt,
	)
	return err
}

func (r *Repository) GetByBooking(ctx context.Context, bookingID uuid.UUID) (*Payment, error) {
	query := `SELECT id, booking_id, user_id, technician_id, amount, commission,
		technician_pay, method, status, gateway_ref, created_at
		FROM payments WHERE booking_id = $1`
	p := &Payment{}
	err := r.db.QueryRow(ctx, query, bookingID).Scan(
		&p.ID, &p.BookingID, &p.UserID, &p.TechnicianID, &p.Amount,
		&p.Commission, &p.TechnicianPay, &p.Method, &p.Status,
		&p.GatewayRef, &p.CreatedAt,
	)
	return p, err
}

func (r *Repository) ListByUser(ctx context.Context, userID uuid.UUID, page, pageSize int) ([]Payment, int, error) {
	offset := (page - 1) * pageSize

	var total int
	err := r.db.QueryRow(ctx, `SELECT COUNT(*) FROM payments WHERE user_id = $1`, userID).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	query := `SELECT id, booking_id, user_id, technician_id, amount, commission,
		technician_pay, method, status, gateway_ref, created_at
		FROM payments WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`

	rows, err := r.db.Query(ctx, query, userID, pageSize, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var payments []Payment
	for rows.Next() {
		var p Payment
		err := rows.Scan(&p.ID, &p.BookingID, &p.UserID, &p.TechnicianID, &p.Amount,
			&p.Commission, &p.TechnicianPay, &p.Method, &p.Status,
			&p.GatewayRef, &p.CreatedAt)
		if err != nil {
			return nil, 0, err
		}
		payments = append(payments, p)
	}

	return payments, total, nil
}

func (r *Repository) ListAll(ctx context.Context, page, pageSize int) ([]Payment, int, error) {
	offset := (page - 1) * pageSize

	var total int
	err := r.db.QueryRow(ctx, `SELECT COUNT(*) FROM payments`).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	query := `SELECT id, booking_id, user_id, technician_id, amount, commission,
		technician_pay, method, status, gateway_ref, created_at
		FROM payments ORDER BY created_at DESC LIMIT $1 OFFSET $2`

	rows, err := r.db.Query(ctx, query, pageSize, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var payments []Payment
	for rows.Next() {
		var p Payment
		err := rows.Scan(&p.ID, &p.BookingID, &p.UserID, &p.TechnicianID, &p.Amount,
			&p.Commission, &p.TechnicianPay, &p.Method, &p.Status,
			&p.GatewayRef, &p.CreatedAt)
		if err != nil {
			return nil, 0, err
		}
		payments = append(payments, p)
	}

	return payments, total, nil
}
