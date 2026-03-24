package support

import (
	"context"

	"github.com/google/uuid"
	"github.com/techapp/backend/internal/notifications"
)

type Service struct {
	repo         *Repository
	notifService *notifications.Service
}

func NewService(repo *Repository, notifService *notifications.Service) *Service {
	return &Service{repo: repo, notifService: notifService}
}

func (s *Service) CreateTicket(ctx context.Context, userID uuid.UUID, req *CreateTicketRequest) (*Ticket, error) {
	ticket := &Ticket{
		UserID:      userID,
		Subject:     req.Subject,
		Description: req.Description,
		Priority:    req.Priority,
	}
	if err := s.repo.CreateTicket(ctx, ticket); err != nil {
		return nil, err
	}
	return ticket, nil
}

func (s *Service) GetTicket(ctx context.Context, id uuid.UUID) (*Ticket, error) {
	return s.repo.GetByID(ctx, id)
}

func (s *Service) ListUserTickets(ctx context.Context, userID uuid.UUID) ([]Ticket, error) {
	return s.repo.ListByUser(ctx, userID)
}

func (s *Service) AddMessage(ctx context.Context, ticketID, senderID uuid.UUID, content string, isAdmin bool) error {
	msg := &TicketMessage{
		TicketID: ticketID,
		SenderID: senderID,
		Content:  content,
		IsAdmin:  isAdmin,
	}
	if err := s.repo.AddMessage(ctx, msg); err != nil {
		return err
	}

	// If admin is replying, update ticket status and notify the ticket owner (only on first reply)
	if isAdmin {
		// Auto-update ticket status to in_progress when admin replies
		_ = s.repo.UpdateStatus(ctx, ticketID, "in_progress")

		// Only send notification on first admin reply, not every message
		hadPriorReply, _ := s.repo.HasAdminReply(ctx, ticketID)
		if !hadPriorReply {
			ticket, err := s.repo.GetByID(ctx, ticketID)
			if err == nil && ticket != nil {
				s.notifService.SendPush(&notifications.PushNotification{
					UserID: ticket.UserID.String(),
					Title:  "Support Reply",
					Body:   "Your support ticket has been replied to: " + ticket.Subject,
					Data:   map[string]string{"type": "support_reply", "ticket_id": ticketID.String()},
				})
			}
		}
	}
	return nil
}

func (s *Service) GetMessages(ctx context.Context, ticketID uuid.UUID) ([]TicketMessage, error) {
	return s.repo.GetMessages(ctx, ticketID)
}

func (s *Service) ListAllTickets(ctx context.Context, page, pageSize int, status string) ([]Ticket, int, error) {
	return s.repo.ListAll(ctx, page, pageSize, status)
}

func (s *Service) AssignTicket(ctx context.Context, ticketID, adminID uuid.UUID) error {
	return s.repo.AssignTicket(ctx, ticketID, adminID)
}

func (s *Service) CloseTicket(ctx context.Context, ticketID uuid.UUID) error {
	return s.repo.CloseTicket(ctx, ticketID)
}
