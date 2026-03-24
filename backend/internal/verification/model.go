package verification

import (
	"time"

	"github.com/google/uuid"
)

type FaceVerification struct {
	ID           uuid.UUID  `json:"id"`
	TechnicianID uuid.UUID  `json:"technician_id"`
	FaceFrontURL string     `json:"face_front_url"`
	FaceRightURL string     `json:"face_right_url"`
	FaceLeftURL  string     `json:"face_left_url"`
	Status       string     `json:"status"`
	ReviewedBy   *uuid.UUID `json:"reviewed_by,omitempty"`
	ReviewedAt   *time.Time `json:"reviewed_at,omitempty"`
	CreatedAt    time.Time  `json:"created_at"`
}

type IDDocument struct {
	ID           uuid.UUID `json:"id"`
	TechnicianID uuid.UUID `json:"technician_id"`
	DocType      string    `json:"doc_type"`
	FileURL      string    `json:"file_url"`
	FileType     string    `json:"file_type"`
	Status       string    `json:"status"`
	CreatedAt    time.Time `json:"created_at"`
}

type VerificationStatus struct {
	FaceVerified    bool   `json:"face_verified"`
	DocsUploaded    bool   `json:"docs_uploaded"`
	Status          string `json:"status"`
	RejectionReason string `json:"rejection_reason,omitempty"`
}

type TechnicianService struct {
	ID           uuid.UUID `json:"id"`
	TechnicianID uuid.UUID `json:"technician_id"`
	CategoryID   uuid.UUID `json:"category_id"`
	HourlyRate   float64   `json:"hourly_rate"`
	IsActive     bool      `json:"is_active"`
	CreatedAt    time.Time `json:"created_at"`
	// Joined fields
	CategoryNameEN string `json:"category_name_en,omitempty"`
	CategoryNameAR string `json:"category_name_ar,omitempty"`
	CategoryIcon   string `json:"category_icon,omitempty"`
}

type ServiceLocation struct {
	ID            uuid.UUID  `json:"id"`
	TechnicianID  uuid.UUID  `json:"technician_id"`
	CountryID     uuid.UUID  `json:"country_id"`
	GovernorateID *uuid.UUID `json:"governorate_id,omitempty"`
	CityID        *uuid.UUID `json:"city_id,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
	// Joined fields
	CountryNameEN     string `json:"country_name_en,omitempty"`
	GovernorateNameEN string `json:"governorate_name_en,omitempty"`
	CityNameEN        string `json:"city_name_en,omitempty"`
	CountryNameAR     string `json:"country_name_ar,omitempty"`
	GovernorateNameAR string `json:"governorate_name_ar,omitempty"`
	CityNameAR        string `json:"city_name_ar,omitempty"`
}

// Request types
type UploadFaceRequest struct {
	FaceFrontBase64 string `json:"face_front" binding:"required"`
	FaceRightBase64 string `json:"face_right" binding:"required"`
	FaceLeftBase64  string `json:"face_left" binding:"required"`
}

type AddServiceRequest struct {
	CategoryID string  `json:"category_id" binding:"required"`
	HourlyRate float64 `json:"hourly_rate" binding:"required,gt=0"`
}

type AddServicesRequest struct {
	Services []AddServiceRequest `json:"services" binding:"required"`
}

type AddLocationRequest struct {
	CountryID     string  `json:"country_id" binding:"required"`
	GovernorateID string  `json:"governorate_id"`
	CityID        *string `json:"city_id"`
}

type AddLocationsRequest struct {
	Locations []AddLocationRequest `json:"locations" binding:"required"`
}
