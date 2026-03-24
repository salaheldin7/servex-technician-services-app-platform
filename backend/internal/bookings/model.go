package bookings

import (
	"time"

	"github.com/google/uuid"
)

// Booking states: searching → assigned → driving → arrived → active → completed
// Cancellation allowed only in: searching, assigned, driving
type BookingStatus string

const (
	StatusSearching BookingStatus = "searching"
	StatusAssigned  BookingStatus = "assigned"
	StatusDriving   BookingStatus = "driving"
	StatusArrived   BookingStatus = "arrived"
	StatusActive    BookingStatus = "active"
	StatusCompleted BookingStatus = "completed"
	StatusCancelled BookingStatus = "cancelled"
)

// Valid state transitions
var ValidTransitions = map[BookingStatus][]BookingStatus{
	StatusSearching: {StatusAssigned, StatusCancelled},
	StatusAssigned:  {StatusDriving, StatusArrived, StatusCancelled},
	StatusDriving:   {StatusArrived, StatusCancelled},
	StatusArrived:   {StatusActive},
	StatusActive:    {StatusCompleted},
}

// CancellableStates defines which states allow cancellation
var CancellableStates = map[BookingStatus]bool{
	StatusSearching: true,
	StatusAssigned:  true,
	StatusDriving:   true,
}

type TaskStatus string

const (
	TaskSearching          TaskStatus = "searching"
	TaskTechnicianComing   TaskStatus = "technician_coming"
	TaskTechnicianWorking  TaskStatus = "technician_working"
	TaskTechnicianFinished TaskStatus = "technician_finished"
	TaskClosed             TaskStatus = "task_closed"
)

type Booking struct {
	ID              uuid.UUID     `json:"id"`
	UserID          uuid.UUID     `json:"user_id"`
	TechnicianID    *uuid.UUID    `json:"technician_id,omitempty"`
	CategoryID      uuid.UUID     `json:"category_id"`
	Status          BookingStatus `json:"status"`
	TaskStatus      TaskStatus    `json:"task_status"`
	Description     string        `json:"description"`
	Address         string        `json:"address"`
	Lat             float64       `json:"lat"`
	Lng             float64       `json:"lng"`
	ScheduledAt     *time.Time    `json:"scheduled_at,omitempty"`
	ArrivalCode     string        `json:"arrival_code,omitempty"`
	StartedAt       *time.Time    `json:"started_at,omitempty"`
	CompletedAt     *time.Time    `json:"completed_at,omitempty"`
	DurationMinutes int           `json:"duration_minutes,omitempty"`
	EstimatedCost   float64       `json:"estimated_cost"`
	FinalCost       float64       `json:"final_cost,omitempty"`
	PaymentMethod   string        `json:"payment_method"` // card, cash
	CancelReason    string        `json:"cancel_reason,omitempty"`
	CancelledBy     string        `json:"cancelled_by,omitempty"` // user, technician, system
	CountryID       *uuid.UUID    `json:"country_id,omitempty"`
	GovernorateID   *uuid.UUID    `json:"governorate_id,omitempty"`
	CityID          *uuid.UUID    `json:"city_id,omitempty"`
	AddressID       *uuid.UUID    `json:"address_id,omitempty"`
	StreetName      string        `json:"street_name,omitempty"`
	BuildingName    string        `json:"building_name,omitempty"`
	BuildingNumber  string        `json:"building_number,omitempty"`
	Floor           string        `json:"floor,omitempty"`
	Apartment       string        `json:"apartment,omitempty"`
	FullAddress     string        `json:"full_address,omitempty"`
	CreatedAt       time.Time     `json:"created_at"`
	UpdatedAt       time.Time     `json:"updated_at"`

	// Joined fields
	UserName         string  `json:"user_name,omitempty"`
	TechnicianName   string  `json:"technician_name,omitempty"`
	TechnicianPhone  string  `json:"technician_phone,omitempty"`
	TechnicianAvatar string  `json:"technician_avatar,omitempty"`
	TechnicianRating float64 `json:"technician_rating,omitempty"`
	CategoryName     string  `json:"category_name,omitempty"`
	CustomerPhone    string  `json:"customer_phone,omitempty"`
}

type CreateBookingRequest struct {
	CategoryID     uuid.UUID  `json:"category_id" binding:"required"`
	Description    string     `json:"description" binding:"required"`
	Address        string     `json:"address"`
	Lat            *float64   `json:"lat"`
	Lng            *float64   `json:"lng"`
	ScheduledAt    *time.Time `json:"scheduled_at"`
	PaymentMethod  string     `json:"payment_method" binding:"required,oneof=card cash"`
	CountryID      string     `json:"country_id"`
	GovernorateID  string     `json:"governorate_id"`
	CityID         string     `json:"city_id"`
	AddressID      string     `json:"address_id"`
	StreetName     string     `json:"street_name"`
	BuildingName   string     `json:"building_name"`
	BuildingNumber string     `json:"building_number"`
	Floor          string     `json:"floor"`
	Apartment      string     `json:"apartment"`
	FullAddress    string     `json:"full_address"`
	TechnicianID   string     `json:"technician_id"` // optional: manually chosen technician
	AutoAssign     bool       `json:"auto_assign"`   // auto-assign best technician
}

type CancelBookingRequest struct {
	Reason string `json:"reason" binding:"required"`
}

type ArrivalVerification struct {
	Code string  `json:"code" binding:"required,len=4"`
	Lat  float64 `json:"lat" binding:"required"`
	Lng  float64 `json:"lng" binding:"required"`
}

type BookingListResponse struct {
	Bookings   []Booking `json:"bookings"`
	TotalCount int       `json:"total_count"`
	Page       int       `json:"page"`
	PageSize   int       `json:"page_size"`
}

func CanTransition(from, to BookingStatus) bool {
	allowed, exists := ValidTransitions[from]
	if !exists {
		return false
	}
	for _, s := range allowed {
		if s == to {
			return true
		}
	}
	return false
}
