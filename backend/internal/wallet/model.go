package wallet

import (
	"time"

	"github.com/google/uuid"
)

type TransactionType string

const (
	TxJobCredit   TransactionType = "job_credit"
	TxCommission  TransactionType = "commission"
	TxWithdrawal  TransactionType = "withdrawal"
	TxPenalty     TransactionType = "penalty"
	TxDebt        TransactionType = "debt"
	TxDebtPayment TransactionType = "debt_payment"
)

type Transaction struct {
	ID          uuid.UUID       `json:"id"`
	UserID      uuid.UUID       `json:"user_id"`
	BookingID   *uuid.UUID      `json:"booking_id,omitempty"`
	Type        TransactionType `json:"type"`
	Amount      float64         `json:"amount"` // positive = credit, negative = debit
	Description string          `json:"description"`
	CreatedAt   time.Time       `json:"created_at"`
}

type WalletBalance struct {
	UserID  uuid.UUID `json:"user_id"`
	Balance float64   `json:"balance"` // Computed from sum of transactions
	Debt    float64   `json:"debt"`    // Accumulated debt for cash payments
}

type WithdrawalRequest struct {
	Amount float64 `json:"amount" binding:"required,gt=0"`
}

type TransactionListResponse struct {
	Transactions []Transaction `json:"transactions"`
	Balance      float64       `json:"balance"`
	TotalCount   int           `json:"total_count"`
	Page         int           `json:"page"`
	PageSize     int           `json:"page_size"`
}
