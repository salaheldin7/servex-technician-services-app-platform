package users

import (
	"time"

	"github.com/google/uuid"
)

type User struct {
	ID           uuid.UUID  `json:"id"`
	Email        string     `json:"email"`
	Phone        string     `json:"phone"`
	Username     string     `json:"username"`
	FullName     string     `json:"full_name"`
	AvatarURL    string     `json:"avatar_url,omitempty"`
	Role         string     `json:"role"`
	IsActive     bool       `json:"is_active"`
	Language     string     `json:"language"`
	PropertyType string     `json:"property_type,omitempty"`
	DeviceToken  string     `json:"-"`
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`
	DeletedAt    *time.Time `json:"-"`
}

type UpdateProfileRequest struct {
	FullName     string `json:"full_name"`
	AvatarURL    string `json:"avatar_url"`
	Language     string `json:"language"`
	PropertyType string `json:"property_type"`
}

type UserListResponse struct {
	Users      []User `json:"users"`
	TotalCount int    `json:"total_count"`
	Page       int    `json:"page"`
	PageSize   int    `json:"page_size"`
}
