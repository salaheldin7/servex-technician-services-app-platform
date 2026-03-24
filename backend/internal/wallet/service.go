package wallet

import (
	"context"
	"fmt"

	"github.com/google/uuid"
)

type Service struct {
	repo *Repository
}

func NewService(repo *Repository) *Service {
	return &Service{repo: repo}
}

func (s *Service) GetBalance(ctx context.Context, userID uuid.UUID) (*WalletBalance, error) {
	balance, err := s.repo.GetBalance(ctx, userID)
	if err != nil {
		return nil, err
	}
	debt, err := s.repo.GetDebt(ctx, userID)
	if err != nil {
		return nil, err
	}
	return &WalletBalance{
		UserID:  userID,
		Balance: balance,
		Debt:    debt,
	}, nil
}

func (s *Service) GetTransactions(ctx context.Context, userID uuid.UUID, page, pageSize int) (*TransactionListResponse, error) {
	transactions, total, err := s.repo.GetTransactions(ctx, userID, page, pageSize)
	if err != nil {
		return nil, err
	}

	balance, _ := s.repo.GetBalance(ctx, userID)

	return &TransactionListResponse{
		Transactions: transactions,
		Balance:      balance,
		TotalCount:   total,
		Page:         page,
		PageSize:     pageSize,
	}, nil
}

func (s *Service) CreditTechnician(ctx context.Context, techUserID uuid.UUID, bookingID uuid.UUID, amount float64) error {
	tx := &Transaction{
		UserID:      techUserID,
		BookingID:   &bookingID,
		Type:        TxJobCredit,
		Amount:      amount,
		Description: fmt.Sprintf("Job payment for booking %s", bookingID),
	}
	return s.repo.CreateTransaction(ctx, tx)
}

func (s *Service) DeductCommission(ctx context.Context, techUserID uuid.UUID, bookingID uuid.UUID, amount float64) error {
	tx := &Transaction{
		UserID:      techUserID,
		BookingID:   &bookingID,
		Type:        TxCommission,
		Amount:      -amount, // Negative = debit
		Description: fmt.Sprintf("Commission for booking %s", bookingID),
	}
	return s.repo.CreateTransaction(ctx, tx)
}

func (s *Service) CreateDebt(ctx context.Context, techUserID uuid.UUID, bookingID uuid.UUID, amount float64) error {
	tx := &Transaction{
		UserID:      techUserID,
		BookingID:   &bookingID,
		Type:        TxDebt,
		Amount:      -amount,
		Description: fmt.Sprintf("Cash booking commission debt for %s", bookingID),
	}
	return s.repo.CreateTransaction(ctx, tx)
}

func (s *Service) RequestWithdrawal(ctx context.Context, userID uuid.UUID, amount float64) error {
	balance, err := s.repo.GetBalance(ctx, userID)
	if err != nil {
		return err
	}

	if balance < amount {
		return fmt.Errorf("insufficient balance: available %.2f, requested %.2f", balance, amount)
	}

	tx := &Transaction{
		UserID:      userID,
		Type:        TxWithdrawal,
		Amount:      -amount,
		Description: fmt.Sprintf("Withdrawal of %.2f", amount),
	}
	return s.repo.CreateTransaction(ctx, tx)
}
