package technicians

import (
	"time"

	"github.com/google/uuid"
)

type TechnicianProfile struct {
	ID                 uuid.UUID `json:"id"`
	UserID             uuid.UUID `json:"user_id"`
	Bio                string    `json:"bio"`
	HourlyRate         float64   `json:"hourly_rate"`
	IsVerified         bool      `json:"is_verified"`
	VerificationStatus string    `json:"verification_status"`
	RejectionReason    string    `json:"rejection_reason,omitempty"`
	IsOnline           bool      `json:"is_online"`
	CurrentLat         float64   `json:"current_lat"`
	CurrentLng         float64   `json:"current_lng"`
	AcceptanceRate     float64   `json:"acceptance_rate"`
	CancelRate         float64   `json:"cancel_rate"`
	StrikeCount        int       `json:"strike_count"`
	AvgRating          float64   `json:"avg_rating"`
	TotalJobs          int       `json:"total_jobs"`
	NationalID         string    `json:"-"` // encrypted, never exposed
	DeviceFingerprint  string    `json:"-"`
	CreatedAt          time.Time `json:"created_at"`
	UpdatedAt          time.Time `json:"updated_at"`

	// Joined fields
	FullName  string `json:"full_name,omitempty"`
	Email     string `json:"email,omitempty"`
	Phone     string `json:"phone,omitempty"`
	AvatarURL string `json:"avatar_url,omitempty"`
}

type RegisterRequest struct {
	Bio         string      `json:"bio" binding:"required"`
	HourlyRate  float64     `json:"hourly_rate" binding:"required,gt=0"`
	NationalID  string      `json:"national_id" binding:"required"`
	CategoryIDs []uuid.UUID `json:"category_ids" binding:"required"`
}

type UpdateProfileRequest struct {
	Bio        string  `json:"bio"`
	HourlyRate float64 `json:"hourly_rate"`
}

type LocationUpdate struct {
	Lat float64 `json:"lat" binding:"required"`
	Lng float64 `json:"lng" binding:"required"`
}

type OnlineStatus struct {
	IsOnline bool `json:"is_online"`
}

type NearbyQuery struct {
	Lat        float64 `form:"latitude" json:"lat" binding:"required"`
	Lng        float64 `form:"longitude" json:"lng" binding:"required"`
	Radius     int     `form:"radius" json:"radius"` // meters
	CategoryID string  `form:"category_id" json:"category_id"`
}

type EarningsResponse struct {
	TotalEarnings  float64 `json:"total_earnings"`
	MonthEarnings  float64 `json:"month_earnings"`
	WeekEarnings   float64 `json:"week_earnings"`
	TodayEarnings  float64 `json:"today_earnings"`
	PendingBalance float64 `json:"pending_balance"`
}

type StatsResponse struct {
	TotalJobs      int     `json:"total_jobs"`
	CompletedJobs  int     `json:"completed_jobs"`
	CancelledJobs  int     `json:"cancelled_jobs"`
	AvgRating      float64 `json:"avg_rating"`
	AcceptanceRate float64 `json:"acceptance_rate"`
	ResponseTime   float64 `json:"avg_response_time_seconds"`
}

type SearchByServiceQuery struct {
	CategoryID    string `json:"category_id" form:"category_id" binding:"required"`
	CountryID     string `json:"country_id" form:"country_id" binding:"required"`
	GovernorateID string `json:"governorate_id" form:"governorate_id"`
	CityID        string `json:"city_id" form:"city_id"`
}

type AutoAssignRequest struct {
	CategoryID    string `json:"category_id" binding:"required"`
	CountryID     string `json:"country_id" binding:"required"`
	GovernorateID string `json:"governorate_id" binding:"required"`
	CityID        string `json:"city_id" binding:"required"`
}
