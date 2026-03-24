package notifications

import (
	"context"
	"log"

	"github.com/google/uuid"
	"github.com/techapp/backend/internal/config"
)

type Service struct {
	cfg  *config.Config
	repo *Repository
}

func NewService(cfg *config.Config, repo *Repository) *Service {
	return &Service{cfg: cfg, repo: repo}
}

type PushNotification struct {
	UserID string
	Title  string
	Body   string
	Data   map[string]string
}

// SendPush sends a push notification via Firebase Cloud Messaging AND stores in DB
func (s *Service) SendPush(notif *PushNotification) error {
	// Store in-app notification
	userID, err := uuid.Parse(notif.UserID)
	if err == nil && s.repo != nil {
		notifType := "general"
		if t, ok := notif.Data["type"]; ok {
			notifType = t
		}
		dbNotif := &Notification{
			UserID: userID,
			Title:  notif.Title,
			Body:   notif.Body,
			Type:   notifType,
			Data:   notif.Data,
		}
		if err := s.repo.Create(context.Background(), dbNotif); err != nil {
			log.Printf("Failed to store notification: %v", err)
		}
	}

	// TODO: Implement FCM integration
	log.Printf("Push notification to %s: %s - %s", notif.UserID, notif.Title, notif.Body)
	return nil
}

// SendEmail sends an email notification
func (s *Service) SendEmail(to, subject, body string) error {
	// TODO: Implement email sending (SES, SendGrid, etc.)
	log.Printf("Email to %s: %s", to, subject)
	return nil
}

// SendSMS sends an SMS
func (s *Service) SendSMS(phone, message string) error {
	// TODO: Implement SMS provider (Twilio, etc.)
	log.Printf("SMS to %s: %s", phone, message)
	return nil
}

// GetNotifications returns paginated notifications for a user
func (s *Service) GetNotifications(ctx context.Context, userID uuid.UUID, page, pageSize int) ([]Notification, int, error) {
	return s.repo.GetByUser(ctx, userID, page, pageSize)
}

// CountUnread returns the count of unread notifications
func (s *Service) CountUnread(ctx context.Context, userID uuid.UUID) (int, error) {
	return s.repo.CountUnread(ctx, userID)
}

// MarkRead marks a single notification as read
func (s *Service) MarkRead(ctx context.Context, notifID uuid.UUID) error {
	return s.repo.MarkRead(ctx, notifID)
}

// MarkAllRead marks all notifications for a user as read
func (s *Service) MarkAllRead(ctx context.Context, userID uuid.UUID) error {
	return s.repo.MarkAllRead(ctx, userID)
}
