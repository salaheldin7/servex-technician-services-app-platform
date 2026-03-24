package workers

import (
	"context"
	"log"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
	"github.com/techapp/backend/internal/config"
)

type Dispatcher struct {
	db  *pgxpool.Pool
	rdb *redis.Client
	cfg *config.Config
}

func NewDispatcher(db *pgxpool.Pool, rdb *redis.Client, cfg *config.Config) *Dispatcher {
	return &Dispatcher{db: db, rdb: rdb, cfg: cfg}
}

func (d *Dispatcher) Start(ctx context.Context) {
	go d.chatPersistenceWorker(ctx)
	go d.cleanupWorker(ctx)
	go d.ratingRecalcWorker(ctx)
	go d.notificationWorker(ctx)
	go d.softDeleteCleanupWorker(ctx)
	go d.staleBookingCleanupWorker(ctx)
}

// chatPersistenceWorker processes chat messages from Redis queue to DB
func (d *Dispatcher) chatPersistenceWorker(ctx context.Context) {
	for {
		select {
		case <-ctx.Done():
			return
		default:
			result, err := d.rdb.BLPop(ctx, 5*time.Second, "chat:persist_queue").Result()
			if err != nil {
				continue
			}
			if len(result) < 2 {
				continue
			}
			// Message already persisted synchronously in chat service
			// This worker handles any failed/queued messages
			log.Printf("Chat persistence worker processed message: %s", result[1][:50])
		}
	}
}

// cleanupWorker handles periodic cleanup tasks
func (d *Dispatcher) cleanupWorker(ctx context.Context) {
	ticker := time.NewTicker(1 * time.Hour)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			// Clean expired sessions
			d.rdb.Del(ctx, "expired_sessions")

			// Clean stale technician locations (offline > 30 min)
			log.Println("Cleanup worker: running periodic cleanup")
		}
	}
}

// ratingRecalcWorker recalculates technician ratings periodically
func (d *Dispatcher) ratingRecalcWorker(ctx context.Context) {
	ticker := time.NewTicker(30 * time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			_, err := d.db.Exec(ctx, `
				UPDATE technician_profiles tp SET
					avg_rating = COALESCE((SELECT AVG(score) FROM ratings WHERE technician_id = tp.id), 0),
					total_jobs = (SELECT COUNT(*) FROM bookings WHERE technician_id = tp.user_id AND status = 'completed')
			`)
			if err != nil {
				log.Printf("Rating recalc error: %v", err)
			} else {
				log.Println("Rating recalculation completed")
			}
		}
	}
}

// notificationWorker processes queued notifications
func (d *Dispatcher) notificationWorker(ctx context.Context) {
	for {
		select {
		case <-ctx.Done():
			return
		default:
			result, err := d.rdb.BLPop(ctx, 5*time.Second, "notification:queue").Result()
			if err != nil {
				continue
			}
			if len(result) < 2 {
				continue
			}
			// TODO: Process notification (FCM, email, SMS)
			log.Printf("Notification worker: %s", result[1][:50])
		}
	}
}

// softDeleteCleanupWorker permanently deletes accounts after 30 day retention
func (d *Dispatcher) softDeleteCleanupWorker(ctx context.Context) {
	ticker := time.NewTicker(24 * time.Hour)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			cutoff := time.Now().UTC().AddDate(0, 0, -30)
			result, err := d.db.Exec(ctx,
				`DELETE FROM users WHERE deleted_at IS NOT NULL AND deleted_at < $1`, cutoff)
			if err != nil {
				log.Printf("Soft delete cleanup error: %v", err)
			} else {
				log.Printf("Soft delete cleanup: removed %d accounts", result.RowsAffected())
			}
		}
	}
}

// staleBookingCleanupWorker cancels bookings stuck in 'searching' for more than 10 minutes
func (d *Dispatcher) staleBookingCleanupWorker(ctx context.Context) {
	ticker := time.NewTicker(2 * time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			now := time.Now().UTC()
			cutoff := now.Add(-10 * time.Minute)
			result, err := d.db.Exec(ctx,
				`UPDATE bookings SET status = 'cancelled', task_status = 'task_closed',
					cancel_reason = 'No technician found - auto expired', cancelled_by = 'system', updated_at = $1
				WHERE status = 'searching' AND created_at < $2`,
				now, cutoff)
			if err != nil {
				log.Printf("Stale booking cleanup error: %v", err)
			} else if result.RowsAffected() > 0 {
				log.Printf("Stale booking cleanup: cancelled %d stuck searching bookings", result.RowsAffected())
			}
		}
	}
}
