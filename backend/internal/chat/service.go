package chat

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
	"github.com/techapp/backend/internal/websocket"
)

type Service struct {
	repo  *Repository
	wsHub *websocket.Hub
	rdb   *redis.Client
}

func NewService(repo *Repository, wsHub *websocket.Hub, rdb *redis.Client) *Service {
	return &Service{repo: repo, wsHub: wsHub, rdb: rdb}
}

func (s *Service) SendMessage(ctx context.Context, bookingID, senderID uuid.UUID, content, msgType string) (*Message, error) {
	if msgType == "" {
		msgType = "text"
	}

	msg := &Message{
		BookingID: bookingID,
		SenderID:  senderID,
		Content:   content,
		Type:      msgType,
	}

	// Persist asynchronously via Redis queue
	msgJSON, _ := json.Marshal(msg)
	s.rdb.RPush(ctx, "chat:persist_queue", msgJSON)

	// Also persist synchronously as fallback
	if err := s.repo.Create(ctx, msg); err != nil {
		return nil, fmt.Errorf("save message: %w", err)
	}

	// Cache last 50 messages
	cacheKey := fmt.Sprintf("chat:booking:%s", bookingID)
	s.rdb.LPush(ctx, cacheKey, msgJSON)
	s.rdb.LTrim(ctx, cacheKey, 0, 49)

	// Send via WebSocket — send to both parties in the booking
	s.wsHub.SendToBooking(bookingID.String(), websocket.Event{
		Type: "chat_message",
		Data: map[string]interface{}{
			"id":         msg.ID,
			"booking_id": msg.BookingID,
			"sender_id":  msg.SenderID,
			"content":    msg.Content,
			"message":    msg.Content,
			"type":       msg.Type,
			"created_at": msg.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		},
	})

	return msg, nil
}

func (s *Service) GetMessages(ctx context.Context, bookingID uuid.UUID, limit, offset int) ([]Message, error) {
	if limit == 0 {
		limit = 50
	}

	// Try cache first (only for first page)
	if offset == 0 {
		cacheKey := fmt.Sprintf("chat:booking:%s", bookingID)
		cached, err := s.rdb.LRange(ctx, cacheKey, 0, int64(limit-1)).Result()
		if err == nil && len(cached) > 0 {
			var messages []Message
			for _, raw := range cached {
				var msg Message
				if err := json.Unmarshal([]byte(raw), &msg); err == nil {
					messages = append(messages, msg)
				}
			}
			if len(messages) > 0 {
				return messages, nil
			}
		}
	}

	return s.repo.GetByBooking(ctx, bookingID, limit, offset)
}
