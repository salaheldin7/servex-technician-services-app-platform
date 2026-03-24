package admin

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

type DashboardStats struct {
	TotalUsers       int     `json:"total_users"`
	TotalTechnicians int     `json:"total_technicians"`
	TotalBookings    int     `json:"total_bookings"`
	ActiveBookings   int     `json:"active_bookings"`
	TodayBookings    int     `json:"today_bookings"`
	TotalRevenue     float64 `json:"total_revenue"`
	MonthRevenue     float64 `json:"month_revenue"`
	PendingVerify    int     `json:"pending_verifications"`
}

func (r *Repository) GetDashboardStats(ctx context.Context) (*DashboardStats, error) {
	stats := &DashboardStats{}

	r.db.QueryRow(ctx, `SELECT COUNT(*) FROM users WHERE role = 'customer' AND deleted_at IS NULL`).Scan(&stats.TotalUsers)
	r.db.QueryRow(ctx, `SELECT COUNT(*) FROM technician_profiles`).Scan(&stats.TotalTechnicians)
	r.db.QueryRow(ctx, `SELECT COUNT(*) FROM bookings`).Scan(&stats.TotalBookings)
	r.db.QueryRow(ctx, `SELECT COUNT(*) FROM bookings WHERE status IN ('assigned','driving','arrived','active')`).Scan(&stats.ActiveBookings)
	r.db.QueryRow(ctx, `SELECT COUNT(*) FROM bookings WHERE created_at >= $1`, time.Now().UTC().Truncate(24*time.Hour)).Scan(&stats.TodayBookings)
	r.db.QueryRow(ctx, `SELECT COALESCE(SUM(commission), 0) FROM payments WHERE status = 'completed'`).Scan(&stats.TotalRevenue)
	r.db.QueryRow(ctx, `SELECT COALESCE(SUM(commission), 0) FROM payments WHERE status = 'completed' AND created_at >= $1`,
		time.Now().UTC().AddDate(0, -1, 0)).Scan(&stats.MonthRevenue)
	r.db.QueryRow(ctx, `SELECT COUNT(*) FROM technician_profiles WHERE is_verified = false`).Scan(&stats.PendingVerify)

	return stats, nil
}

type RevenueData struct {
	Date    string  `json:"date"`
	Revenue float64 `json:"revenue"`
	Count   int     `json:"count"`
}

func (r *Repository) GetRevenueReport(ctx context.Context, days int) ([]RevenueData, error) {
	query := `
		SELECT DATE(created_at) as date, SUM(commission) as revenue, COUNT(*) as count
		FROM payments
		WHERE status = 'completed' AND created_at >= $1
		GROUP BY DATE(created_at)
		ORDER BY date DESC
	`
	rows, err := r.db.Query(ctx, query, time.Now().UTC().AddDate(0, 0, -days))
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var data []RevenueData
	for rows.Next() {
		var d RevenueData
		rows.Scan(&d.Date, &d.Revenue, &d.Count)
		data = append(data, d)
	}
	return data, nil
}

type BookingReportData struct {
	Date      string `json:"date"`
	Total     int    `json:"total"`
	Completed int    `json:"completed"`
	Cancelled int    `json:"cancelled"`
}

func (r *Repository) GetBookingReport(ctx context.Context, days int) ([]BookingReportData, error) {
	query := `
		SELECT DATE(created_at) as date,
			COUNT(*) as total,
			COUNT(*) FILTER (WHERE status = 'completed') as completed,
			COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled
		FROM bookings
		WHERE created_at >= $1
		GROUP BY DATE(created_at)
		ORDER BY date DESC
	`
	rows, err := r.db.Query(ctx, query, time.Now().UTC().AddDate(0, 0, -days))
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var data []BookingReportData
	for rows.Next() {
		var d BookingReportData
		rows.Scan(&d.Date, &d.Total, &d.Completed, &d.Cancelled)
		data = append(data, d)
	}
	return data, nil
}

func (r *Repository) BanUser(ctx context.Context, userID uuid.UUID) error {
	_, err := r.db.Exec(ctx, `UPDATE users SET is_active = false, updated_at = $1 WHERE id = $2`, time.Now().UTC(), userID)
	return err
}

func (r *Repository) UnbanUser(ctx context.Context, userID uuid.UUID) error {
	_, err := r.db.Exec(ctx, `UPDATE users SET is_active = true, updated_at = $1 WHERE id = $2`, time.Now().UTC(), userID)
	return err
}

func (r *Repository) DeleteUser(ctx context.Context, userID uuid.UUID) error {
	now := time.Now().UTC()
	_, err := r.db.Exec(ctx, `UPDATE users SET deleted_at = $1, is_active = false, updated_at = $1 WHERE id = $2`, now, userID)
	return err
}

func (r *Repository) ResetUserPassword(ctx context.Context, userID uuid.UUID, hashedPassword string) error {
	_, err := r.db.Exec(ctx, `UPDATE users SET password_hash = $1, updated_at = $2 WHERE id = $3`, hashedPassword, time.Now().UTC(), userID)
	return err
}

// TechnicianVerificationDetail holds all verification info for admin review
type TechnicianVerificationDetail struct {
	TechnicianID       string                 `json:"technician_id"`
	UserID             string                 `json:"user_id"`
	FullName           string                 `json:"full_name"`
	Email              string                 `json:"email"`
	Phone              string                 `json:"phone"`
	VerificationStatus string                 `json:"verification_status"`
	IsVerified         bool                   `json:"is_verified"`
	RejectionReason    string                 `json:"rejection_reason,omitempty"`
	FaceFrontURL       string                 `json:"face_front_url"`
	FaceRightURL       string                 `json:"face_right_url"`
	FaceLeftURL        string                 `json:"face_left_url"`
	FaceStatus         string                 `json:"face_status"`
	Documents          []VerificationDocument `json:"documents"`
}

type VerificationDocument struct {
	ID       string `json:"id"`
	DocType  string `json:"doc_type"`
	FileURL  string `json:"file_url"`
	FileType string `json:"file_type"`
	Status   string `json:"status"`
}

func (r *Repository) GetTechnicianVerificationDetail(ctx context.Context, techID uuid.UUID) (*TechnicianVerificationDetail, error) {
	detail := &TechnicianVerificationDetail{}

	// Get profile info
	err := r.db.QueryRow(ctx, `
		SELECT tp.id, tp.user_id, u.full_name, u.email, u.phone, 
			COALESCE(tp.verification_status, 'none'), tp.is_verified,
			COALESCE(tp.rejection_reason, '')
		FROM technician_profiles tp
		JOIN users u ON u.id = tp.user_id
		WHERE tp.id = $1
	`, techID).Scan(&detail.TechnicianID, &detail.UserID, &detail.FullName,
		&detail.Email, &detail.Phone, &detail.VerificationStatus, &detail.IsVerified,
		&detail.RejectionReason)
	if err != nil {
		return nil, err
	}

	// Get face verification
	err = r.db.QueryRow(ctx, `
		SELECT COALESCE(face_front_url, ''), COALESCE(face_right_url, ''), COALESCE(face_left_url, ''), COALESCE(status, 'none')
		FROM technician_verifications
		WHERE technician_id = $1
		ORDER BY created_at DESC LIMIT 1
	`, techID).Scan(&detail.FaceFrontURL, &detail.FaceRightURL, &detail.FaceLeftURL, &detail.FaceStatus)
	if err != nil {
		// No face verification yet
		detail.FaceStatus = "none"
	}

	// Get documents
	rows, err := r.db.Query(ctx, `
		SELECT id, doc_type, file_url, file_type, COALESCE(status, 'pending')
		FROM technician_documents
		WHERE technician_id = $1
		ORDER BY created_at DESC
	`, techID)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var doc VerificationDocument
			rows.Scan(&doc.ID, &doc.DocType, &doc.FileURL, &doc.FileType, &doc.Status)
			detail.Documents = append(detail.Documents, doc)
		}
	}

	return detail, nil
}
