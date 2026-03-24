package support

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	db *pgxpool.Pool
}

func NewRepository(db *pgxpool.Pool) *Repository {
	return &Repository{db: db}
}

func (r *Repository) CreateTicket(ctx context.Context, ticket *Ticket) error {
	ticket.ID = uuid.New()
	ticket.Status = "open"
	if ticket.Priority == "" {
		ticket.Priority = "medium"
	}
	now := time.Now().UTC()
	ticket.CreatedAt = now
	ticket.UpdatedAt = now

	query := `INSERT INTO support_tickets (id, user_id, subject, description, status, priority, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`
	_, err := r.db.Exec(ctx, query, ticket.ID, ticket.UserID, ticket.Subject,
		ticket.Description, ticket.Status, ticket.Priority, ticket.CreatedAt, ticket.UpdatedAt)
	return err
}

func (r *Repository) GetByID(ctx context.Context, id uuid.UUID) (*Ticket, error) {
	query := `SELECT t.id, t.user_id, t.assigned_to, t.subject, t.description, t.status, t.priority,
		t.created_at, t.updated_at, u.full_name
		FROM support_tickets t JOIN users u ON u.id = t.user_id WHERE t.id = $1`
	t := &Ticket{}
	err := r.db.QueryRow(ctx, query, id).Scan(&t.ID, &t.UserID, &t.AssignedTo,
		&t.Subject, &t.Description, &t.Status, &t.Priority, &t.CreatedAt, &t.UpdatedAt, &t.UserName)
	return t, err
}

func (r *Repository) ListByUser(ctx context.Context, userID uuid.UUID) ([]Ticket, error) {
	query := `SELECT id, user_id, assigned_to, subject, description, status, priority, created_at, updated_at
		FROM support_tickets WHERE user_id = $1 ORDER BY created_at DESC`
	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var tickets []Ticket
	for rows.Next() {
		var t Ticket
		rows.Scan(&t.ID, &t.UserID, &t.AssignedTo, &t.Subject, &t.Description,
			&t.Status, &t.Priority, &t.CreatedAt, &t.UpdatedAt)
		tickets = append(tickets, t)
	}
	return tickets, nil
}

func (r *Repository) ListAll(ctx context.Context, page, pageSize int, status string) ([]Ticket, int, error) {
	offset := (page - 1) * pageSize

	var total int
	if status != "" {
		countQuery := `SELECT COUNT(*) FROM support_tickets WHERE status = $1`
		r.db.QueryRow(ctx, countQuery, status).Scan(&total)
	} else {
		countQuery := `SELECT COUNT(*) FROM support_tickets`
		r.db.QueryRow(ctx, countQuery).Scan(&total)
	}

	var rows pgx.Rows
	var err error
	if status != "" {
		query := `SELECT t.id, t.user_id, t.assigned_to, t.subject, t.description, t.status, t.priority,
		t.created_at, t.updated_at, u.full_name
		FROM support_tickets t JOIN users u ON u.id = t.user_id
		WHERE t.status = $1
		ORDER BY t.created_at DESC LIMIT $2 OFFSET $3`
		rows, err = r.db.Query(ctx, query, status, pageSize, offset)
	} else {
		query := `SELECT t.id, t.user_id, t.assigned_to, t.subject, t.description, t.status, t.priority,
		t.created_at, t.updated_at, u.full_name
		FROM support_tickets t JOIN users u ON u.id = t.user_id
		ORDER BY t.created_at DESC LIMIT $1 OFFSET $2`
		rows, err = r.db.Query(ctx, query, pageSize, offset)
	}
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()
	var tickets []Ticket
	for rows.Next() {
		var t Ticket
		rows.Scan(&t.ID, &t.UserID, &t.AssignedTo, &t.Subject, &t.Description,
			&t.Status, &t.Priority, &t.CreatedAt, &t.UpdatedAt, &t.UserName)
		tickets = append(tickets, t)
	}
	return tickets, total, nil
}

func (r *Repository) AddMessage(ctx context.Context, msg *TicketMessage) error {
	msg.ID = uuid.New()
	msg.CreatedAt = time.Now().UTC()
	query := `INSERT INTO support_ticket_messages (id, ticket_id, sender_id, content, is_admin, created_at)
		VALUES ($1, $2, $3, $4, $5, $6)`
	_, err := r.db.Exec(ctx, query, msg.ID, msg.TicketID, msg.SenderID, msg.Content, msg.IsAdmin, msg.CreatedAt)
	return err
}

func (r *Repository) GetMessages(ctx context.Context, ticketID uuid.UUID) ([]TicketMessage, error) {
	query := `SELECT m.id, m.ticket_id, m.sender_id, m.content, m.is_admin, m.created_at,
		COALESCE(u.full_name, '') as sender_name
		FROM support_ticket_messages m
		LEFT JOIN users u ON u.id = m.sender_id
		WHERE m.ticket_id = $1 ORDER BY m.created_at ASC`
	rows, err := r.db.Query(ctx, query, ticketID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var messages []TicketMessage
	for rows.Next() {
		var m TicketMessage
		rows.Scan(&m.ID, &m.TicketID, &m.SenderID, &m.Content, &m.IsAdmin, &m.CreatedAt, &m.SenderName)
		messages = append(messages, m)
	}
	return messages, nil
}

func (r *Repository) AssignTicket(ctx context.Context, ticketID, adminID uuid.UUID) error {
	_, err := r.db.Exec(ctx, `UPDATE support_tickets SET assigned_to = $1, status = 'in_progress', updated_at = $2 WHERE id = $3`,
		adminID, time.Now().UTC(), ticketID)
	return err
}

func (r *Repository) CloseTicket(ctx context.Context, ticketID uuid.UUID) error {
	_, err := r.db.Exec(ctx, `UPDATE support_tickets SET status = 'closed', updated_at = $1 WHERE id = $2`,
		time.Now().UTC(), ticketID)
	return err
}

func (r *Repository) UpdateStatus(ctx context.Context, ticketID uuid.UUID, status string) error {
	_, err := r.db.Exec(ctx, `UPDATE support_tickets SET status = $1, updated_at = $2 WHERE id = $3 AND status != 'closed'`,
		status, time.Now().UTC(), ticketID)
	return err
}

func (r *Repository) HasAdminReply(ctx context.Context, ticketID uuid.UUID) (bool, error) {
	var count int
	err := r.db.QueryRow(ctx, `SELECT COUNT(*) FROM support_ticket_messages WHERE ticket_id = $1 AND is_admin = true`, ticketID).Scan(&count)
	if err != nil {
		return false, err
	}
	// count > 1 means there was already an admin message before this one
	return count > 1, nil
}
