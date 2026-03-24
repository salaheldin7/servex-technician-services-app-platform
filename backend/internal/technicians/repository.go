package technicians

import (
	"context"
	"fmt"
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

func (r *Repository) Create(ctx context.Context, profile *TechnicianProfile) error {
	query := `
		INSERT INTO technician_profiles (id, user_id, bio, hourly_rate, national_id, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`
	profile.ID = uuid.New()
	now := time.Now().UTC()
	_, err := r.db.Exec(ctx, query,
		profile.ID, profile.UserID, profile.Bio, profile.HourlyRate,
		profile.NationalID, now, now,
	)
	return err
}

func (r *Repository) GetByUserID(ctx context.Context, userID uuid.UUID) (*TechnicianProfile, error) {
	query := `
		SELECT tp.id, tp.user_id, tp.bio, tp.hourly_rate, tp.is_verified, COALESCE(tp.verification_status, 'none'), tp.is_online,
			tp.current_lat, tp.current_lng, tp.acceptance_rate, tp.cancel_rate, tp.strike_count,
			tp.avg_rating, tp.total_jobs, tp.created_at, tp.updated_at,
			u.full_name, u.email, u.phone, u.avatar_url,
			COALESCE(tp.rejection_reason, '')
		FROM technician_profiles tp
		JOIN users u ON u.id = tp.user_id
		WHERE tp.user_id = $1
	`
	p := &TechnicianProfile{}
	err := r.db.QueryRow(ctx, query, userID).Scan(
		&p.ID, &p.UserID, &p.Bio, &p.HourlyRate, &p.IsVerified, &p.VerificationStatus, &p.IsOnline,
		&p.CurrentLat, &p.CurrentLng, &p.AcceptanceRate, &p.CancelRate, &p.StrikeCount,
		&p.AvgRating, &p.TotalJobs, &p.CreatedAt, &p.UpdatedAt,
		&p.FullName, &p.Email, &p.Phone, &p.AvatarURL,
		&p.RejectionReason,
	)
	if err != nil {
		return nil, fmt.Errorf("technician not found: %w", err)
	}
	return p, nil
}

func (r *Repository) GetByID(ctx context.Context, id uuid.UUID) (*TechnicianProfile, error) {
	query := `
		SELECT tp.id, tp.user_id, tp.bio, tp.hourly_rate, tp.is_verified, COALESCE(tp.verification_status, 'none'), tp.is_online,
			tp.current_lat, tp.current_lng, tp.acceptance_rate, tp.cancel_rate, tp.strike_count,
			tp.avg_rating, tp.total_jobs, tp.created_at, tp.updated_at,
			u.full_name, u.email, u.phone, u.avatar_url,
			COALESCE(tp.rejection_reason, '')
		FROM technician_profiles tp
		JOIN users u ON u.id = tp.user_id
		WHERE tp.id = $1
	`
	p := &TechnicianProfile{}
	err := r.db.QueryRow(ctx, query, id).Scan(
		&p.ID, &p.UserID, &p.Bio, &p.HourlyRate, &p.IsVerified, &p.VerificationStatus, &p.IsOnline,
		&p.CurrentLat, &p.CurrentLng, &p.AcceptanceRate, &p.CancelRate, &p.StrikeCount,
		&p.AvgRating, &p.TotalJobs, &p.CreatedAt, &p.UpdatedAt,
		&p.FullName, &p.Email, &p.Phone, &p.AvatarURL,
		&p.RejectionReason,
	)
	if err != nil {
		return nil, fmt.Errorf("technician not found: %w", err)
	}
	return p, nil
}

func (r *Repository) Update(ctx context.Context, userID uuid.UUID, req *UpdateProfileRequest) error {
	query := `
		UPDATE technician_profiles
		SET bio = COALESCE(NULLIF($1, ''), bio),
			hourly_rate = CASE WHEN $2 > 0 THEN $2 ELSE hourly_rate END,
			updated_at = $3
		WHERE user_id = $4
	`
	_, err := r.db.Exec(ctx, query, req.Bio, req.HourlyRate, time.Now().UTC(), userID)
	return err
}

func (r *Repository) UpdateLocation(ctx context.Context, userID uuid.UUID, lat, lng float64) error {
	query := `
		UPDATE technician_profiles
		SET current_lat = $1, current_lng = $2,
			location = ST_SetSRID(ST_MakePoint($2, $1), 4326),
			updated_at = $3
		WHERE user_id = $4
	`
	_, err := r.db.Exec(ctx, query, lat, lng, time.Now().UTC(), userID)
	return err
}

func (r *Repository) SetOnline(ctx context.Context, userID uuid.UUID, online bool) error {
	query := `UPDATE technician_profiles SET is_online = $1, updated_at = $2 WHERE user_id = $3`
	_, err := r.db.Exec(ctx, query, online, time.Now().UTC(), userID)
	return err
}

func (r *Repository) FindNearby(ctx context.Context, lat, lng float64, radiusMeters int, categoryID string) ([]TechnicianProfile, error) {
	query := `
		SELECT tp.id, tp.user_id, tp.bio, tp.hourly_rate, tp.is_verified, COALESCE(tp.verification_status, 'none'), tp.is_online,
			tp.current_lat, tp.current_lng, tp.acceptance_rate, tp.cancel_rate, tp.strike_count,
			tp.avg_rating, tp.total_jobs, tp.created_at, tp.updated_at,
			u.full_name, u.email, u.phone, u.avatar_url,
			ST_Distance(tp.location, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography) as distance
		FROM technician_profiles tp
		JOIN users u ON u.id = tp.user_id
		WHERE tp.is_online = true
			AND tp.is_verified = true
			AND u.is_active = true
			AND ST_DWithin(tp.location::geography, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography, $3)
	`
	args := []interface{}{lat, lng, radiusMeters}

	if categoryID != "" {
		query += ` AND tp.id IN (SELECT technician_id FROM technician_categories WHERE category_id = $4)`
		args = append(args, categoryID)
	}

	query += ` ORDER BY distance ASC LIMIT 20`

	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var technicians []TechnicianProfile
	for rows.Next() {
		var t TechnicianProfile
		var distance float64
		err := rows.Scan(
			&t.ID, &t.UserID, &t.Bio, &t.HourlyRate, &t.IsVerified, &t.VerificationStatus, &t.IsOnline,
			&t.CurrentLat, &t.CurrentLng, &t.AcceptanceRate, &t.CancelRate, &t.StrikeCount,
			&t.AvgRating, &t.TotalJobs, &t.CreatedAt, &t.UpdatedAt,
			&t.FullName, &t.Email, &t.Phone, &t.AvatarURL,
			&distance,
		)
		if err != nil {
			return nil, err
		}
		technicians = append(technicians, t)
	}
	return technicians, nil
}

func (r *Repository) FindAvailableForMatching(ctx context.Context, lat, lng float64, radiusMeters int, categoryID string) ([]TechnicianProfile, error) {
	query := `
		SELECT tp.id, tp.user_id, tp.bio, tp.hourly_rate, tp.is_verified, COALESCE(tp.verification_status, 'none'), tp.is_online,
			tp.current_lat, tp.current_lng, tp.acceptance_rate, tp.cancel_rate, tp.strike_count,
			tp.avg_rating, tp.total_jobs, tp.created_at, tp.updated_at,
			u.full_name, u.email, u.phone, u.avatar_url,
			ST_Distance(tp.location, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography) as distance
		FROM technician_profiles tp
		JOIN users u ON u.id = tp.user_id
		WHERE tp.is_online = true
			AND tp.is_verified = true
			AND u.is_active = true
			AND ST_DWithin(tp.location::geography, ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography, $3)
			AND tp.user_id NOT IN (
				SELECT technician_id FROM bookings
				WHERE status IN ('assigned', 'driving', 'arrived', 'active')
				AND technician_id IS NOT NULL
			)
	`
	args := []interface{}{lat, lng, radiusMeters}

	if categoryID != "" {
		query += ` AND tp.id IN (SELECT technician_id FROM technician_categories WHERE category_id = $4)`
		args = append(args, categoryID)
	}

	query += ` ORDER BY distance ASC LIMIT 10`

	rows, err := r.db.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var technicians []TechnicianProfile
	for rows.Next() {
		var t TechnicianProfile
		var distance float64
		err := rows.Scan(
			&t.ID, &t.UserID, &t.Bio, &t.HourlyRate, &t.IsVerified, &t.VerificationStatus, &t.IsOnline,
			&t.CurrentLat, &t.CurrentLng, &t.AcceptanceRate, &t.CancelRate, &t.StrikeCount,
			&t.AvgRating, &t.TotalJobs, &t.CreatedAt, &t.UpdatedAt,
			&t.FullName, &t.Email, &t.Phone, &t.AvatarURL,
			&distance,
		)
		if err != nil {
			return nil, err
		}
		technicians = append(technicians, t)
	}
	return technicians, nil
}

func (r *Repository) UpdateRating(ctx context.Context, techID uuid.UUID, avgRating float64) error {
	query := `UPDATE technician_profiles SET avg_rating = $1, updated_at = $2 WHERE id = $3`
	_, err := r.db.Exec(ctx, query, avgRating, time.Now().UTC(), techID)
	return err
}

func (r *Repository) IncrementJobs(ctx context.Context, techID uuid.UUID) error {
	query := `UPDATE technician_profiles SET total_jobs = total_jobs + 1, updated_at = $1 WHERE id = $2`
	_, err := r.db.Exec(ctx, query, time.Now().UTC(), techID)
	return err
}

func (r *Repository) AddStrike(ctx context.Context, userID uuid.UUID) error {
	query := `UPDATE technician_profiles SET strike_count = strike_count + 1, updated_at = $1 WHERE user_id = $2`
	_, err := r.db.Exec(ctx, query, time.Now().UTC(), userID)
	return err
}

func (r *Repository) List(ctx context.Context, page, pageSize int, verified *bool, statuses ...string) ([]TechnicianProfile, int, error) {
	offset := (page - 1) * pageSize

	countQuery := `SELECT COUNT(*) FROM technician_profiles`
	args := []interface{}{}
	argIdx := 1
	whereAdded := false

	addWhere := func() string {
		if !whereAdded {
			whereAdded = true
			return " WHERE "
		}
		return " AND "
	}

	if verified != nil {
		countQuery += addWhere() + fmt.Sprintf("is_verified = $%d", argIdx)
		args = append(args, *verified)
		argIdx++
	}

	// Filter by verification_status(es) if provided
	if len(statuses) > 0 && statuses[0] != "" {
		placeholders := ""
		for i, s := range statuses {
			if i > 0 {
				placeholders += ", "
			}
			placeholders += fmt.Sprintf("$%d", argIdx)
			args = append(args, s)
			argIdx++
		}
		countQuery += addWhere() + fmt.Sprintf("COALESCE(verification_status, 'none') IN (%s)", placeholders)
	}

	var total int
	err := r.db.QueryRow(ctx, countQuery, args...).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	query := `
		SELECT tp.id, tp.user_id, tp.bio, tp.hourly_rate, tp.is_verified, COALESCE(tp.verification_status, 'none'), tp.is_online,
			tp.current_lat, tp.current_lng, tp.acceptance_rate, tp.cancel_rate, tp.strike_count,
			tp.avg_rating, tp.total_jobs, tp.created_at, tp.updated_at,
			u.full_name, u.email, u.phone, u.avatar_url,
			COALESCE(tp.rejection_reason, '')
		FROM technician_profiles tp
		JOIN users u ON u.id = tp.user_id
	`
	queryArgs := []interface{}{}
	queryArgIdx := 1
	queryWhereAdded := false

	addQueryWhere := func() string {
		if !queryWhereAdded {
			queryWhereAdded = true
			return " WHERE "
		}
		return " AND "
	}

	if verified != nil {
		query += addQueryWhere() + fmt.Sprintf("tp.is_verified = $%d", queryArgIdx)
		queryArgs = append(queryArgs, *verified)
		queryArgIdx++
	}

	if len(statuses) > 0 && statuses[0] != "" {
		placeholders := ""
		for i, s := range statuses {
			if i > 0 {
				placeholders += ", "
			}
			placeholders += fmt.Sprintf("$%d", queryArgIdx)
			queryArgs = append(queryArgs, s)
			queryArgIdx++
		}
		query += addQueryWhere() + fmt.Sprintf("COALESCE(tp.verification_status, 'none') IN (%s)", placeholders)
	}

	query += fmt.Sprintf(" ORDER BY tp.created_at DESC LIMIT $%d OFFSET $%d", queryArgIdx, queryArgIdx+1)
	queryArgs = append(queryArgs, pageSize, offset)

	rows, err := r.db.Query(ctx, query, queryArgs...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var profiles []TechnicianProfile
	for rows.Next() {
		var p TechnicianProfile
		err := rows.Scan(
			&p.ID, &p.UserID, &p.Bio, &p.HourlyRate, &p.IsVerified, &p.VerificationStatus, &p.IsOnline,
			&p.CurrentLat, &p.CurrentLng, &p.AcceptanceRate, &p.CancelRate, &p.StrikeCount,
			&p.AvgRating, &p.TotalJobs, &p.CreatedAt, &p.UpdatedAt,
			&p.FullName, &p.Email, &p.Phone, &p.AvatarURL,
			&p.RejectionReason,
		)
		if err != nil {
			return nil, 0, err
		}
		profiles = append(profiles, p)
	}

	return profiles, total, nil
}

// SearchByServiceAndLocation finds online, verified technicians that offer the given
// category within the customer's country/governorate/city.
func (r *Repository) SearchByServiceAndLocation(ctx context.Context, categoryID string, countryID, governorateID, cityID string) ([]TechnicianProfile, error) {
	query := `
		SELECT DISTINCT tp.id, tp.user_id, tp.bio, tp.hourly_rate, tp.is_verified,
			COALESCE(tp.verification_status, 'none'), tp.is_online,
			tp.current_lat, tp.current_lng, tp.acceptance_rate, tp.cancel_rate, tp.strike_count,
			tp.avg_rating, tp.total_jobs, tp.created_at, tp.updated_at,
			u.full_name, u.email, u.phone, u.avatar_url,
			COALESCE(tp.rejection_reason, ''),
			COALESCE(ts.hourly_rate, tp.hourly_rate) as service_rate
		FROM technician_profiles tp
		JOIN users u ON u.id = tp.user_id
		JOIN technician_services ts ON ts.technician_id = tp.id AND ts.category_id = $1 AND ts.is_active = true
		JOIN technician_service_locations tsl ON tsl.technician_id = tp.id
		WHERE tp.is_online = true
			AND tp.is_verified = true
			AND u.is_active = true
			AND tsl.country_id = $2
			AND (tsl.governorate_id IS NULL OR tsl.governorate_id = $3)
			AND (tsl.city_id IS NULL OR tsl.city_id = $4)
			AND tp.user_id NOT IN (
				SELECT technician_id FROM bookings
				WHERE status IN ('assigned', 'driving', 'arrived', 'active')
				AND technician_id IS NOT NULL
			)
		ORDER BY tp.avg_rating DESC, tp.total_jobs DESC
		LIMIT 20
	`

	rows, err := r.db.Query(ctx, query, categoryID, countryID, governorateID, cityID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var technicians []TechnicianProfile
	for rows.Next() {
		var t TechnicianProfile
		var serviceRate float64
		err := rows.Scan(
			&t.ID, &t.UserID, &t.Bio, &t.HourlyRate, &t.IsVerified, &t.VerificationStatus, &t.IsOnline,
			&t.CurrentLat, &t.CurrentLng, &t.AcceptanceRate, &t.CancelRate, &t.StrikeCount,
			&t.AvgRating, &t.TotalJobs, &t.CreatedAt, &t.UpdatedAt,
			&t.FullName, &t.Email, &t.Phone, &t.AvatarURL,
			&t.RejectionReason,
			&serviceRate,
		)
		if err != nil {
			return nil, err
		}
		t.HourlyRate = serviceRate // Use the service-specific rate
		technicians = append(technicians, t)
	}
	return technicians, nil
}

// AutoAssign picks the best technician (highest rating, lowest price, good trip count).
func (r *Repository) AutoAssign(ctx context.Context, categoryID string, countryID, governorateID, cityID string) (*TechnicianProfile, error) {
	query := `
		SELECT DISTINCT tp.id, tp.user_id, tp.bio, tp.hourly_rate, tp.is_verified,
			COALESCE(tp.verification_status, 'none'), tp.is_online,
			tp.current_lat, tp.current_lng, tp.acceptance_rate, tp.cancel_rate, tp.strike_count,
			tp.avg_rating, tp.total_jobs, tp.created_at, tp.updated_at,
			u.full_name, u.email, u.phone, u.avatar_url,
			COALESCE(tp.rejection_reason, ''),
			COALESCE(ts.hourly_rate, tp.hourly_rate) as service_rate
		FROM technician_profiles tp
		JOIN users u ON u.id = tp.user_id
		JOIN technician_services ts ON ts.technician_id = tp.id AND ts.category_id = $1 AND ts.is_active = true
		JOIN technician_service_locations tsl ON tsl.technician_id = tp.id
		WHERE tp.is_online = true
			AND tp.is_verified = true
			AND u.is_active = true
			AND tsl.country_id = $2
			AND (tsl.governorate_id IS NULL OR tsl.governorate_id = $3)
			AND (tsl.city_id IS NULL OR tsl.city_id = $4)
			AND tp.user_id NOT IN (
				SELECT technician_id FROM bookings
				WHERE status IN ('assigned', 'driving', 'arrived', 'active')
				AND technician_id IS NOT NULL
			)
		ORDER BY tp.avg_rating DESC, COALESCE(ts.hourly_rate, tp.hourly_rate) ASC, tp.total_jobs DESC
		LIMIT 1
	`

	t := &TechnicianProfile{}
	var serviceRate float64
	err := r.db.QueryRow(ctx, query, categoryID, countryID, governorateID, cityID).Scan(
		&t.ID, &t.UserID, &t.Bio, &t.HourlyRate, &t.IsVerified, &t.VerificationStatus, &t.IsOnline,
		&t.CurrentLat, &t.CurrentLng, &t.AcceptanceRate, &t.CancelRate, &t.StrikeCount,
		&t.AvgRating, &t.TotalJobs, &t.CreatedAt, &t.UpdatedAt,
		&t.FullName, &t.Email, &t.Phone, &t.AvatarURL,
		&t.RejectionReason,
		&serviceRate,
	)
	if err != nil {
		return nil, fmt.Errorf("no available technician found: %w", err)
	}
	t.HourlyRate = serviceRate
	return t, nil
}

func (r *Repository) Verify(ctx context.Context, techID uuid.UUID, verified bool) error {
	status := "rejected"
	if verified {
		status = "verified"
	}
	query := `UPDATE technician_profiles SET is_verified = $1, verification_status = $2, updated_at = $3 WHERE id = $4`
	_, err := r.db.Exec(ctx, query, verified, status, time.Now().UTC(), techID)
	return err
}

func (r *Repository) SetRejectionReason(ctx context.Context, techID uuid.UUID, reason string) error {
	query := `UPDATE technician_profiles SET rejection_reason = $1, updated_at = $2 WHERE id = $3`
	_, err := r.db.Exec(ctx, query, reason, time.Now().UTC(), techID)
	return err
}
