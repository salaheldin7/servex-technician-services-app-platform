package addresses

import (
	"time"

	"github.com/google/uuid"
)

type Address struct {
	ID             uuid.UUID  `json:"id"`
	UserID         uuid.UUID  `json:"user_id"`
	Label          string     `json:"label"`
	CountryID      *uuid.UUID `json:"country_id,omitempty"`
	GovernorateID  *uuid.UUID `json:"governorate_id,omitempty"`
	CityID         *uuid.UUID `json:"city_id,omitempty"`
	StreetName     string     `json:"street_name"`
	BuildingName   string     `json:"building_name"`
	BuildingNumber string     `json:"building_number"`
	Floor          string     `json:"floor"`
	Apartment      string     `json:"apartment"`
	Latitude       *float64   `json:"latitude,omitempty"`
	Longitude      *float64   `json:"longitude,omitempty"`
	FullAddress    string     `json:"full_address"`
	IsDefault      bool       `json:"is_default"`
	CreatedAt      time.Time  `json:"created_at"`
	UpdatedAt      time.Time  `json:"updated_at"`

	// Joined fields for display
	CountryName     string `json:"country_name,omitempty"`
	GovernorateName string `json:"governorate_name,omitempty"`
	CityName        string `json:"city_name,omitempty"`
}

type CreateAddressRequest struct {
	Label          string   `json:"label" binding:"required"`
	CountryID      string   `json:"country_id"`
	GovernorateID  string   `json:"governorate_id"`
	CityID         string   `json:"city_id"`
	StreetName     string   `json:"street_name"`
	BuildingName   string   `json:"building_name"`
	BuildingNumber string   `json:"building_number" binding:"required"`
	Floor          string   `json:"floor"`
	Apartment      string   `json:"apartment"`
	Latitude       *float64 `json:"latitude"`
	Longitude      *float64 `json:"longitude"`
	FullAddress    string   `json:"full_address"`
	IsDefault      bool     `json:"is_default"`
}

type UpdateAddressRequest struct {
	Label          *string  `json:"label"`
	StreetName     *string  `json:"street_name"`
	BuildingName   *string  `json:"building_name"`
	BuildingNumber *string  `json:"building_number"`
	Latitude       *float64 `json:"latitude"`
	Longitude      *float64 `json:"longitude"`
	FullAddress    *string  `json:"full_address"`
	IsDefault      *bool    `json:"is_default"`
}
