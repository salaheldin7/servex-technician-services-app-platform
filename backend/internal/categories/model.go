package categories

import (
	"time"

	"github.com/google/uuid"
)

type Category struct {
	ID        uuid.UUID  `json:"id"`
	ParentID  *uuid.UUID `json:"parent_id,omitempty"`
	Type      string     `json:"type"`
	NameEN    string     `json:"name_en"`
	NameAR    string     `json:"name_ar"`
	Icon      string     `json:"icon,omitempty"`
	SortOrder int        `json:"sort_order"`
	IsActive  bool       `json:"is_active"`
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`

	Children []Category `json:"children,omitempty"`
}

type CreateCategoryRequest struct {
	ParentID  *uuid.UUID `json:"parent_id"`
	Type      string     `json:"type"`
	NameEN    string     `json:"name_en" binding:"required"`
	NameAR    string     `json:"name_ar" binding:"required"`
	Icon      string     `json:"icon"`
	SortOrder int        `json:"sort_order"`
}

type UpdateCategoryRequest struct {
	NameEN    string `json:"name_en"`
	NameAR    string `json:"name_ar"`
	Icon      string `json:"icon"`
	SortOrder int    `json:"sort_order"`
	IsActive  *bool  `json:"is_active"`
}
