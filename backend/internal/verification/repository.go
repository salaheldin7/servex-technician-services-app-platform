package verification

import (
	"context"
	"encoding/base64"
	"fmt"
	"os"
	"path/filepath"
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

// GetTechnicianIDByUserID returns the technician_profiles.id for a user
func (r *Repository) GetTechnicianIDByUserID(ctx context.Context, userID uuid.UUID) (uuid.UUID, error) {
	var techID uuid.UUID
	err := r.db.QueryRow(ctx, `SELECT id FROM technician_profiles WHERE user_id = $1`, userID).Scan(&techID)
	return techID, err
}

// --- Face Verification ---

func (r *Repository) SaveFaceVerification(ctx context.Context, v *FaceVerification) error {
	// Decode and save base64 images to uploads folder
	uploadDir := "uploads/faces"
	os.MkdirAll(uploadDir, 0755)

	frontPath, _ := saveBase64Image(v.FaceFrontURL, uploadDir, v.TechnicianID.String()+"_front")
	rightPath, _ := saveBase64Image(v.FaceRightURL, uploadDir, v.TechnicianID.String()+"_right")
	leftPath, _ := saveBase64Image(v.FaceLeftURL, uploadDir, v.TechnicianID.String()+"_left")

	v.ID = uuid.New()
	now := time.Now().UTC()
	query := `INSERT INTO technician_verifications (id, technician_id, face_front_url, face_right_url, face_left_url, status, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, 'pending', $6, $6)
		ON CONFLICT (technician_id) DO UPDATE SET
			face_front_url = $3, face_right_url = $4, face_left_url = $5,
			status = 'pending', updated_at = $6`
	_, err := r.db.Exec(ctx, query, v.ID, v.TechnicianID, frontPath, rightPath, leftPath, now)
	if err != nil {
		return err
	}

	// Update verification_status on profile
	_, err = r.db.Exec(ctx,
		`UPDATE technician_profiles SET verification_status = 'face_done', updated_at = $1 WHERE id = $2`,
		now, v.TechnicianID)
	return err
}

func (r *Repository) GetFaceVerification(ctx context.Context, techID uuid.UUID) (*FaceVerification, error) {
	query := `SELECT id, technician_id, face_front_url, face_right_url, face_left_url, status, created_at
		FROM technician_verifications WHERE technician_id = $1 ORDER BY created_at DESC LIMIT 1`
	v := &FaceVerification{}
	err := r.db.QueryRow(ctx, query, techID).Scan(&v.ID, &v.TechnicianID, &v.FaceFrontURL, &v.FaceRightURL, &v.FaceLeftURL, &v.Status, &v.CreatedAt)
	if err != nil {
		return nil, err
	}
	return v, nil
}

// --- ID Documents ---

func (r *Repository) SaveIDDocument(ctx context.Context, doc *IDDocument) error {
	doc.ID = uuid.New()
	now := time.Now().UTC()
	query := `INSERT INTO technician_documents (id, technician_id, doc_type, file_url, file_type, status, created_at)
		VALUES ($1, $2, $3, $4, $5, 'pending', $6)`
	_, err := r.db.Exec(ctx, query, doc.ID, doc.TechnicianID, doc.DocType, doc.FileURL, doc.FileType, now)
	if err != nil {
		return err
	}
	// Update verification status
	_, err = r.db.Exec(ctx,
		`UPDATE technician_profiles SET verification_status = 'docs_done', updated_at = $1 WHERE id = $2`,
		now, doc.TechnicianID)
	return err
}

func (r *Repository) GetIDDocuments(ctx context.Context, techID uuid.UUID) ([]IDDocument, error) {
	query := `SELECT id, technician_id, doc_type, file_url, file_type, status, created_at
		FROM technician_documents WHERE technician_id = $1 ORDER BY created_at DESC`
	rows, err := r.db.Query(ctx, query, techID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var docs []IDDocument
	for rows.Next() {
		var d IDDocument
		if err := rows.Scan(&d.ID, &d.TechnicianID, &d.DocType, &d.FileURL, &d.FileType, &d.Status, &d.CreatedAt); err != nil {
			return nil, err
		}
		docs = append(docs, d)
	}
	return docs, nil
}

// --- Technician Services ---

func (r *Repository) AddServices(ctx context.Context, techID uuid.UUID, services []AddServiceRequest) error {
	now := time.Now().UTC()
	for _, s := range services {
		catID, err := uuid.Parse(s.CategoryID)
		if err != nil {
			return fmt.Errorf("invalid category_id: %s", s.CategoryID)
		}
		query := `INSERT INTO technician_services (id, technician_id, category_id, hourly_rate, is_active, created_at, updated_at)
			VALUES ($1, $2, $3, $4, true, $5, $5)
			ON CONFLICT (technician_id, category_id) DO UPDATE SET hourly_rate = $4, is_active = true, updated_at = $5`
		_, err = r.db.Exec(ctx, query, uuid.New(), techID, catID, s.HourlyRate, now)
		if err != nil {
			return err
		}
	}
	return nil
}

func (r *Repository) GetServices(ctx context.Context, techID uuid.UUID) ([]TechnicianService, error) {
	query := `SELECT ts.id, ts.technician_id, ts.category_id, ts.hourly_rate, ts.is_active, ts.created_at,
			c.name_en, c.name_ar, c.icon
		FROM technician_services ts
		JOIN categories c ON c.id = ts.category_id
		WHERE ts.technician_id = $1 AND ts.is_active = true
		ORDER BY c.sort_order ASC`
	rows, err := r.db.Query(ctx, query, techID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var services []TechnicianService
	for rows.Next() {
		var s TechnicianService
		if err := rows.Scan(&s.ID, &s.TechnicianID, &s.CategoryID, &s.HourlyRate, &s.IsActive, &s.CreatedAt,
			&s.CategoryNameEN, &s.CategoryNameAR, &s.CategoryIcon); err != nil {
			return nil, err
		}
		services = append(services, s)
	}
	return services, nil
}

func (r *Repository) RemoveService(ctx context.Context, techID, serviceID uuid.UUID) error {
	_, err := r.db.Exec(ctx,
		`UPDATE technician_services SET is_active = false, updated_at = $1 WHERE id = $2 AND technician_id = $3`,
		time.Now().UTC(), serviceID, techID)
	return err
}

// --- Service Locations ---

func (r *Repository) AddLocations(ctx context.Context, techID uuid.UUID, locs []AddLocationRequest) error {
	now := time.Now().UTC()
	for _, l := range locs {
		countryID, err := uuid.Parse(l.CountryID)
		if err != nil {
			return fmt.Errorf("invalid country_id: %s", l.CountryID)
		}

		// Build the query dynamically based on which fields are provided.
		// This avoids any potential type-nil or NULL-encoding issues with pgx.
		hasGov := false
		hasCity := false
		var govID uuid.UUID
		var cityID uuid.UUID

		if l.GovernorateID != "" {
			parsed, err := uuid.Parse(l.GovernorateID)
			if err == nil {
				govID = parsed
				hasGov = true
			}
		}

		if l.CityID != nil && *l.CityID != "" {
			parsed, err := uuid.Parse(*l.CityID)
			if err == nil {
				cityID = parsed
				hasCity = true
			}
		}

		var queryErr error
		if hasGov && hasCity {
			_, queryErr = r.db.Exec(ctx,
				`INSERT INTO technician_service_locations (id, technician_id, country_id, governorate_id, city_id, created_at)
				VALUES ($1, $2, $3, $4, $5, $6)
				ON CONFLICT DO NOTHING`,
				uuid.New(), techID, countryID, govID, cityID, now)
		} else if hasGov {
			_, queryErr = r.db.Exec(ctx,
				`INSERT INTO technician_service_locations (id, technician_id, country_id, governorate_id, city_id, created_at)
				VALUES ($1, $2, $3, $4, NULL, $5)
				ON CONFLICT DO NOTHING`,
				uuid.New(), techID, countryID, govID, now)
		} else {
			// Country only — no governorate, no city
			_, queryErr = r.db.Exec(ctx,
				`INSERT INTO technician_service_locations (id, technician_id, country_id, governorate_id, city_id, created_at)
				VALUES ($1, $2, $3, NULL, NULL, $4)
				ON CONFLICT DO NOTHING`,
				uuid.New(), techID, countryID, now)
		}
		if queryErr != nil {
			return queryErr
		}
	}
	return nil
}

func (r *Repository) GetLocations(ctx context.Context, techID uuid.UUID) ([]ServiceLocation, error) {
	query := `SELECT sl.id, sl.technician_id, sl.country_id, sl.governorate_id, sl.city_id, sl.created_at,
			co.name_en, COALESCE(g.name_en, ''), COALESCE(ci.name_en, ''),
			co.name_ar, COALESCE(g.name_ar, ''), COALESCE(ci.name_ar, '')
		FROM technician_service_locations sl
		JOIN countries co ON co.id = sl.country_id
		LEFT JOIN governorates g ON g.id = sl.governorate_id
		LEFT JOIN cities ci ON ci.id = sl.city_id
		WHERE sl.technician_id = $1
		ORDER BY co.name_en, g.name_en, ci.name_en`
	rows, err := r.db.Query(ctx, query, techID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var locs []ServiceLocation
	for rows.Next() {
		var l ServiceLocation
		if err := rows.Scan(&l.ID, &l.TechnicianID, &l.CountryID, &l.GovernorateID, &l.CityID, &l.CreatedAt,
			&l.CountryNameEN, &l.GovernorateNameEN, &l.CityNameEN,
			&l.CountryNameAR, &l.GovernorateNameAR, &l.CityNameAR); err != nil {
			return nil, err
		}
		locs = append(locs, l)
	}
	return locs, nil
}

func (r *Repository) RemoveLocation(ctx context.Context, techID, locID uuid.UUID) error {
	_, err := r.db.Exec(ctx, `DELETE FROM technician_service_locations WHERE id = $1 AND technician_id = $2`, locID, techID)
	return err
}

// --- Verification Status ---

func (r *Repository) GetVerificationStatus(ctx context.Context, techID uuid.UUID) (*VerificationStatus, error) {
	var status string
	var rejectionReason string
	err := r.db.QueryRow(ctx, `SELECT COALESCE(verification_status, 'none'), COALESCE(rejection_reason, '') FROM technician_profiles WHERE id = $1`, techID).Scan(&status, &rejectionReason)
	if err != nil {
		return nil, err
	}
	return &VerificationStatus{
		FaceVerified:    status == "face_done" || status == "docs_done" || status == "verified",
		DocsUploaded:    status == "docs_done" || status == "verified",
		Status:          status,
		RejectionReason: rejectionReason,
	}, nil
}

// Helper: save base64 encoded image to disk
func saveBase64Image(b64data, dir, name string) (string, error) {
	data, err := base64.StdEncoding.DecodeString(b64data)
	if err != nil {
		// Try URL-safe base64
		data, err = base64.URLEncoding.DecodeString(b64data)
		if err != nil {
			return "", err
		}
	}
	filename := name + ".jpg"
	path := filepath.Join(dir, filename)
	if err := os.WriteFile(path, data, 0644); err != nil {
		return "", err
	}
	return path, nil
}
