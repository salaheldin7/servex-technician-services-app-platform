package wallet

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

func (r *Repository) CreateTransaction(ctx context.Context, tx *Transaction) error {
	tx.ID = uuid.New()
	tx.CreatedAt = time.Now().UTC()

	query := `
		INSERT INTO wallet_transactions (id, user_id, booking_id, type, amount, description, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`
	_, err := r.db.Exec(ctx, query,
		tx.ID, tx.UserID, tx.BookingID, tx.Type, tx.Amount, tx.Description, tx.CreatedAt,
	)
	return err
}

func (r *Repository) GetBalance(ctx context.Context, userID uuid.UUID) (float64, error) {
	query := `SELECT COALESCE(SUM(amount), 0) FROM wallet_transactions WHERE user_id = $1`
	var balance float64
	err := r.db.QueryRow(ctx, query, userID).Scan(&balance)
	return balance, err
}

func (r *Repository) GetDebt(ctx context.Context, userID uuid.UUID) (float64, error) {
	query := `
		SELECT COALESCE(SUM(amount), 0) FROM wallet_transactions
		WHERE user_id = $1 AND type IN ('debt', 'debt_payment')
	`
	var debt float64
	err := r.db.QueryRow(ctx, query, userID).Scan(&debt)
	return debt, err
}

func (r *Repository) GetTransactions(ctx context.Context, userID uuid.UUID, page, pageSize int) ([]Transaction, int, error) {
	offset := (page - 1) * pageSize

	var total int
	countQuery := `SELECT COUNT(*) FROM wallet_transactions WHERE user_id = $1`
	err := r.db.QueryRow(ctx, countQuery, userID).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	query := `
		SELECT id, user_id, booking_id, type, amount, description, created_at
		FROM wallet_transactions
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`
	rows, err := r.db.Query(ctx, query, userID, pageSize, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var transactions []Transaction
	for rows.Next() {
		var t Transaction
		err := rows.Scan(&t.ID, &t.UserID, &t.BookingID, &t.Type, &t.Amount, &t.Description, &t.CreatedAt)
		if err != nil {
			return nil, 0, err
		}
		transactions = append(transactions, t)
	}

	return transactions, total, nil
}
