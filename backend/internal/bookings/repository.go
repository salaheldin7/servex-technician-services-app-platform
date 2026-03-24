package bookings

import (
	"context"
	"crypto/rand"
	"fmt"
	"math/big"
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

func (r *Repository) Create(ctx context.Context, booking *Booking) error {
	booking.ID = uuid.New()
	booking.Status = StatusSearching
	booking.TaskStatus = TaskSearching
	// NOTE: arrival code NOT generated here — only generated when technician accepts
	now := time.Now().UTC()
	booking.CreatedAt = now
	booking.UpdatedAt = now

	query := `
		INSERT INTO bookings (id, user_id, category_id, status, task_status, description, address, lat, lng,
			scheduled_at, estimated_cost, payment_method,
			country_id, governorate_id, city_id, address_id,
			street_name, building_name, building_number, floor, apartment, full_address,
			created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12,
			$13::uuid, $14::uuid, $15::uuid, $16::uuid,
			$17, $18, $19, $20, $21, $22, $23, $24)
	`

	// Convert *uuid.UUID to *string for pgx UUID cast compatibility
	uuidToStr := func(u *uuid.UUID) *string {
		if u == nil {
			return nil
		}
		s := u.String()
		return &s
	}

	_, err := r.db.Exec(ctx, query,
		booking.ID, booking.UserID, booking.CategoryID, booking.Status, booking.TaskStatus,
		booking.Description, booking.Address, booking.Lat, booking.Lng,
		booking.ScheduledAt, booking.EstimatedCost, booking.PaymentMethod,
		uuidToStr(booking.CountryID), uuidToStr(booking.GovernorateID), uuidToStr(booking.CityID), uuidToStr(booking.AddressID),
		booking.StreetName, booking.BuildingName, booking.BuildingNumber, booking.Floor, booking.Apartment, booking.FullAddress,
		booking.CreatedAt, booking.UpdatedAt,
	)
	return err
}

func (r *Repository) GetByID(ctx context.Context, id uuid.UUID) (*Booking, error) {
	query := `
		SELECT b.id, b.user_id, b.technician_id, b.category_id, b.status, b.task_status, b.description,
			b.address, b.lat, b.lng, b.scheduled_at, b.arrival_code, b.started_at,
			b.completed_at, b.duration_minutes, b.estimated_cost, b.final_cost,
			b.payment_method, b.cancel_reason, b.cancelled_by, b.created_at, b.updated_at,
			COALESCE(b.country_id::text, ''), COALESCE(b.governorate_id::text, ''),
			COALESCE(b.city_id::text, ''), COALESCE(b.address_id::text, ''),
			COALESCE(b.street_name, ''), COALESCE(b.building_name, ''),
			COALESCE(b.building_number, ''), COALESCE(b.floor, ''), COALESCE(b.apartment, ''),
			COALESCE(b.full_address, ''),
			u.full_name as user_name,
			COALESCE(u.phone, '') as customer_phone,
			COALESCE(tu.full_name, '') as technician_name,
			COALESCE(tu.phone, '') as technician_phone,
			COALESCE(tu.avatar_url, '') as technician_avatar,
			COALESCE(tp.avg_rating, 0) as technician_rating,
			c.name_en as category_name
		FROM bookings b
		JOIN users u ON u.id = b.user_id
		LEFT JOIN technician_profiles tp ON tp.user_id = b.technician_id
		LEFT JOIN users tu ON tu.id = b.technician_id
		JOIN categories c ON c.id = b.category_id
		WHERE b.id = $1
	`
	booking := &Booking{}
	var countryStr, govStr, cityStr, addrIDStr string
	err := r.db.QueryRow(ctx, query, id).Scan(
		&booking.ID, &booking.UserID, &booking.TechnicianID, &booking.CategoryID,
		&booking.Status, &booking.TaskStatus, &booking.Description, &booking.Address, &booking.Lat, &booking.Lng,
		&booking.ScheduledAt, &booking.ArrivalCode, &booking.StartedAt,
		&booking.CompletedAt, &booking.DurationMinutes, &booking.EstimatedCost,
		&booking.FinalCost, &booking.PaymentMethod, &booking.CancelReason,
		&booking.CancelledBy, &booking.CreatedAt, &booking.UpdatedAt,
		&countryStr, &govStr, &cityStr, &addrIDStr,
		&booking.StreetName, &booking.BuildingName,
		&booking.BuildingNumber, &booking.Floor, &booking.Apartment,
		&booking.FullAddress,
		&booking.UserName, &booking.CustomerPhone,
		&booking.TechnicianName, &booking.TechnicianPhone,
		&booking.TechnicianAvatar, &booking.TechnicianRating,
		&booking.CategoryName,
	)
	if err != nil {
		return nil, fmt.Errorf("booking not found: %w", err)
	}
	// Parse UUID strings back to *uuid.UUID
	if countryStr != "" {
		if id, err := uuid.Parse(countryStr); err == nil {
			booking.CountryID = &id
		}
	}
	if govStr != "" {
		if id, err := uuid.Parse(govStr); err == nil {
			booking.GovernorateID = &id
		}
	}
	if cityStr != "" {
		if id, err := uuid.Parse(cityStr); err == nil {
			booking.CityID = &id
		}
	}
	if addrIDStr != "" {
		if id, err := uuid.Parse(addrIDStr); err == nil {
			booking.AddressID = &id
		}
	}
	return booking, nil
}

func (r *Repository) UpdateStatus(ctx context.Context, id uuid.UUID, status BookingStatus) error {
	query := `UPDATE bookings SET status = $1, updated_at = $2 WHERE id = $3`
	_, err := r.db.Exec(ctx, query, status, time.Now().UTC(), id)
	return err
}

func (r *Repository) UpdateStatusAndTask(ctx context.Context, id uuid.UUID, status BookingStatus, taskStatus TaskStatus) error {
	query := `UPDATE bookings SET status = $1, task_status = $2, updated_at = $3 WHERE id = $4`
	_, err := r.db.Exec(ctx, query, status, taskStatus, time.Now().UTC(), id)
	return err
}

func (r *Repository) AssignTechnician(ctx context.Context, bookingID, technicianID uuid.UUID) error {
	// Generate arrival code when technician is assigned (not at booking creation)
	code := generateCode()
	query := `UPDATE bookings SET technician_id = $1, status = $2, task_status = $3, arrival_code = $4, updated_at = $5 WHERE id = $6`
	_, err := r.db.Exec(ctx, query, technicianID, StatusAssigned, TaskTechnicianComing, code, time.Now().UTC(), bookingID)
	return err
}

func (r *Repository) StartJob(ctx context.Context, id uuid.UUID) error {
	now := time.Now().UTC()
	query := `UPDATE bookings SET status = $1, task_status = $2, started_at = $3, updated_at = $3 WHERE id = $4`
	_, err := r.db.Exec(ctx, query, StatusActive, TaskTechnicianWorking, now, id)
	return err
}

func (r *Repository) CompleteJob(ctx context.Context, id uuid.UUID, finalCost float64) error {
	now := time.Now().UTC()
	query := `
		UPDATE bookings SET status = $1, task_status = $2, completed_at = $3, final_cost = $4,
			duration_minutes = EXTRACT(EPOCH FROM ($3 - started_at)) / 60,
			updated_at = $3
		WHERE id = $5
	`
	_, err := r.db.Exec(ctx, query, StatusCompleted, TaskTechnicianFinished, now, finalCost, id)
	return err
}

func (r *Repository) Cancel(ctx context.Context, id uuid.UUID, reason, cancelledBy string) error {
	query := `
		UPDATE bookings SET status = $1, task_status = $2, cancel_reason = $3, cancelled_by = $4, updated_at = $5
		WHERE id = $6
	`
	_, err := r.db.Exec(ctx, query, StatusCancelled, TaskClosed, reason, cancelledBy, time.Now().UTC(), id)
	return err
}

// Delete hard-deletes a booking from the database (only for searching state)
func (r *Repository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM bookings WHERE id = $1`
	_, err := r.db.Exec(ctx, query, id)
	return err
}

func (r *Repository) ListByUser(ctx context.Context, userID uuid.UUID, page, pageSize int) ([]Booking, int, error) {
	return r.listBookings(ctx, "b.user_id = $1", userID, page, pageSize)
}

func (r *Repository) ListByTechnician(ctx context.Context, techID uuid.UUID, page, pageSize int) ([]Booking, int, error) {
	return r.listBookings(ctx, "b.technician_id = $1", techID, page, pageSize)
}

func (r *Repository) ListAll(ctx context.Context, page, pageSize int, status string) ([]Booking, int, error) {
	if status != "" {
		return r.listBookings(ctx, "b.status = $1", status, page, pageSize)
	}
	return r.listBookings(ctx, "1=1", nil, page, pageSize)
}

func (r *Repository) listBookings(ctx context.Context, where string, arg interface{}, page, pageSize int) ([]Booking, int, error) {
	offset := (page - 1) * pageSize

	// Count
	countQuery := "SELECT COUNT(*) FROM bookings b WHERE " + where
	var total int
	var err error
	if arg != nil {
		err = r.db.QueryRow(ctx, countQuery, arg).Scan(&total)
	} else {
		err = r.db.QueryRow(ctx, countQuery).Scan(&total)
	}
	if err != nil {
		return nil, 0, err
	}

	// Fetch
	query := `
		SELECT b.id, b.user_id, b.technician_id, b.category_id, b.status, b.task_status, b.description,
			b.address, b.lat, b.lng, b.estimated_cost, b.final_cost,
			b.payment_method, b.scheduled_at, b.arrival_code, b.started_at,
			b.completed_at, b.duration_minutes, b.cancel_reason, b.cancelled_by,
			b.created_at, b.updated_at,
			u.full_name as user_name,
			COALESCE(tu.full_name, '') as technician_name,
			COALESCE(tu.phone, '') as technician_phone,
			c.name_en as category_name
		FROM bookings b
		JOIN users u ON u.id = b.user_id
		LEFT JOIN users tu ON tu.id = b.technician_id
		JOIN categories c ON c.id = b.category_id
		WHERE ` + where + `
		ORDER BY b.created_at DESC
	`

	var rows interface {
		Close()
		Next() bool
		Scan(...interface{}) error
	}
	if arg != nil {
		query += fmt.Sprintf(" LIMIT $2 OFFSET $3")
		rows2, err2 := r.db.Query(ctx, query, arg, pageSize, offset)
		if err2 != nil {
			return nil, 0, err2
		}
		rows = rows2
	} else {
		query += fmt.Sprintf(" LIMIT $1 OFFSET $2")
		rows2, err2 := r.db.Query(ctx, query, pageSize, offset)
		if err2 != nil {
			return nil, 0, err2
		}
		rows = rows2
	}
	defer rows.Close()

	var bookings []Booking
	for rows.Next() {
		var b Booking
		err := rows.Scan(
			&b.ID, &b.UserID, &b.TechnicianID, &b.CategoryID, &b.Status, &b.TaskStatus,
			&b.Description, &b.Address, &b.Lat, &b.Lng,
			&b.EstimatedCost, &b.FinalCost, &b.PaymentMethod,
			&b.ScheduledAt, &b.ArrivalCode, &b.StartedAt,
			&b.CompletedAt, &b.DurationMinutes, &b.CancelReason, &b.CancelledBy,
			&b.CreatedAt, &b.UpdatedAt,
			&b.UserName, &b.TechnicianName, &b.TechnicianPhone, &b.CategoryName,
		)
		if err != nil {
			return nil, 0, err
		}
		bookings = append(bookings, b)
	}

	return bookings, total, nil
}

func (r *Repository) CountByStatus(ctx context.Context, status BookingStatus) (int, error) {
	query := `SELECT COUNT(*) FROM bookings WHERE status = $1`
	var count int
	err := r.db.QueryRow(ctx, query, status).Scan(&count)
	return count, err
}

// CountActiveByUser returns the number of non-terminal bookings for a user
func (r *Repository) CountActiveByUser(ctx context.Context, userID uuid.UUID) (int, error) {
	query := `SELECT COUNT(*) FROM bookings WHERE user_id = $1 AND status IN ('searching', 'assigned', 'driving', 'arrived', 'active')`
	var count int
	err := r.db.QueryRow(ctx, query, userID).Scan(&count)
	return count, err
}

// CancelStaleSearching cancels bookings stuck in 'searching' for more than the given duration
func (r *Repository) CancelStaleSearching(ctx context.Context, olderThan time.Duration) (int, error) {
	query := `UPDATE bookings SET status = 'cancelled', task_status = 'task_closed', cancel_reason = 'No technician found - auto expired', cancelled_by = 'system', updated_at = $1
		WHERE status = 'searching' AND created_at < $2`
	now := time.Now().UTC()
	cutoff := now.Add(-olderThan)
	result, err := r.db.Exec(ctx, query, now, cutoff)
	if err != nil {
		return 0, err
	}
	return int(result.RowsAffected()), nil
}

// FindSearchingForTechnician finds bookings in 'searching' status that match
// the technician's registered services and service locations.
func (r *Repository) FindSearchingForTechnician(ctx context.Context, technicianUserID uuid.UUID) ([]Booking, error) {
	query := `
		SELECT b.id, b.user_id, b.technician_id, b.category_id, b.status, b.task_status,
			b.description, b.address, b.lat, b.lng, b.estimated_cost, b.final_cost,
			b.payment_method, b.scheduled_at, COALESCE(b.arrival_code, ''), b.started_at,
			b.completed_at, b.duration_minutes, COALESCE(b.cancel_reason, ''), COALESCE(b.cancelled_by, ''),
			b.created_at, b.updated_at,
			u.full_name as user_name,
			'' as technician_name,
			'' as technician_phone,
			c.name_en as category_name
		FROM bookings b
		JOIN users u ON u.id = b.user_id
		JOIN categories c ON c.id = b.category_id
		JOIN technician_profiles tp ON tp.user_id = $1
		JOIN technician_services ts ON ts.technician_id = tp.id AND ts.category_id = b.category_id AND ts.is_active = true
		WHERE b.status = 'searching'
			AND b.created_at > NOW() - INTERVAL '10 minutes'
		ORDER BY b.created_at DESC
		LIMIT 10
	`

	rows, err := r.db.Query(ctx, query, technicianUserID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var bookings []Booking
	for rows.Next() {
		var b Booking
		err := rows.Scan(
			&b.ID, &b.UserID, &b.TechnicianID, &b.CategoryID, &b.Status, &b.TaskStatus,
			&b.Description, &b.Address, &b.Lat, &b.Lng,
			&b.EstimatedCost, &b.FinalCost, &b.PaymentMethod,
			&b.ScheduledAt, &b.ArrivalCode, &b.StartedAt,
			&b.CompletedAt, &b.DurationMinutes, &b.CancelReason, &b.CancelledBy,
			&b.CreatedAt, &b.UpdatedAt,
			&b.UserName, &b.TechnicianName, &b.TechnicianPhone, &b.CategoryName,
		)
		if err != nil {
			return nil, err
		}
		bookings = append(bookings, b)
	}
	return bookings, nil
}

func generateCode() string {
	code := ""
	for i := 0; i < 4; i++ {
		n, _ := rand.Int(rand.Reader, big.NewInt(10))
		code += n.String()
	}
	return code
}

// GetBookingParticipants returns the user and technician IDs for a booking
func (r *Repository) GetBookingParticipants(ctx context.Context, bookingID string) (userID string, technicianID string, err error) {
	id, parseErr := uuid.Parse(bookingID)
	if parseErr != nil {
		return "", "", parseErr
	}
	query := `SELECT user_id::text, COALESCE(technician_id::text, '') FROM bookings WHERE id = $1`
	err = r.db.QueryRow(ctx, query, id).Scan(&userID, &technicianID)
	return
}

// GetActiveTechnicianBooking finds the active booking for a technician (assigned/driving/arrived/active)
func (r *Repository) GetActiveTechnicianBooking(ctx context.Context, technicianUserID string) (userID string, bookingID string, err error) {
	id, parseErr := uuid.Parse(technicianUserID)
	if parseErr != nil {
		return "", "", parseErr
	}
	query := `SELECT user_id::text, id::text FROM bookings WHERE technician_id = $1 AND status IN ('assigned', 'driving', 'arrived', 'active') ORDER BY updated_at DESC LIMIT 1`
	err = r.db.QueryRow(ctx, query, id).Scan(&userID, &bookingID)
	return
}
