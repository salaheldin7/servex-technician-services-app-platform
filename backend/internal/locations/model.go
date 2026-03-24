package locations

import (
	"time"

	"github.com/google/uuid"
)

type Country struct {
	ID             uuid.UUID `json:"id"`
	NameEN         string    `json:"name_en"`
	NameAR         string    `json:"name_ar"`
	Code           string    `json:"code"`
	PhoneCode      string    `json:"phone_code"`
	CurrencyCode   string    `json:"currency_code"`
	CurrencySymbol string    `json:"currency_symbol"`
	IsActive       bool      `json:"is_active"`
	CreatedAt      time.Time `json:"created_at"`
}

type Governorate struct {
	ID        uuid.UUID `json:"id"`
	CountryID uuid.UUID `json:"country_id"`
	NameEN    string    `json:"name_en"`
	NameAR    string    `json:"name_ar"`
	Code      string    `json:"code"`
	IsActive  bool      `json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
}

type City struct {
	ID            uuid.UUID `json:"id"`
	GovernorateID uuid.UUID `json:"governorate_id"`
	NameEN        string    `json:"name_en"`
	NameAR        string    `json:"name_ar"`
	Code          string    `json:"code"`
	IsActive      bool      `json:"is_active"`
	CreatedAt     time.Time `json:"created_at"`
}
