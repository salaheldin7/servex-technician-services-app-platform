package addresses

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

func (r *Repository) Create(ctx context.Context, addr *Address) error {
	query := `
		INSERT INTO user_addresses (id, user_id, label, country_id, governorate_id, city_id,
			street_name, building_name, building_number, floor, apartment,
			latitude, longitude, full_address, is_default, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $16)
	`
	addr.ID = uuid.New()
	now := time.Now().UTC()
	addr.CreatedAt = now
	addr.UpdatedAt = now

	// If setting as default, unset other defaults first
	if addr.IsDefault {
		r.db.Exec(ctx, "UPDATE user_addresses SET is_default = false WHERE user_id = $1", addr.UserID)
	}

	_, err := r.db.Exec(ctx, query,
		addr.ID, addr.UserID, addr.Label, addr.CountryID, addr.GovernorateID, addr.CityID,
		addr.StreetName, addr.BuildingName, addr.BuildingNumber, addr.Floor, addr.Apartment,
		addr.Latitude, addr.Longitude,
		addr.FullAddress, addr.IsDefault, now,
	)
	return err
}

func (r *Repository) GetByUser(ctx context.Context, userID uuid.UUID) ([]Address, error) {
	query := `
		SELECT a.id, a.user_id, a.label, a.country_id, a.governorate_id, a.city_id,
			a.street_name, COALESCE(a.building_name,''), a.building_number,
			COALESCE(a.floor,''), COALESCE(a.apartment,''),
			a.latitude, a.longitude, COALESCE(a.full_address,''), a.is_default, a.created_at, a.updated_at,
			COALESCE(c.name_en,''), COALESCE(g.name_en,''), COALESCE(ci.name_en,'')
		FROM user_addresses a
		LEFT JOIN countries c ON c.id = a.country_id
		LEFT JOIN governorates g ON g.id = a.governorate_id
		LEFT JOIN cities ci ON ci.id = a.city_id
		WHERE a.user_id = $1
		ORDER BY a.is_default DESC, a.created_at DESC
	`
	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var addresses []Address
	for rows.Next() {
		var a Address
		if err := rows.Scan(
			&a.ID, &a.UserID, &a.Label, &a.CountryID, &a.GovernorateID, &a.CityID,
			&a.StreetName, &a.BuildingName, &a.BuildingNumber,
			&a.Floor, &a.Apartment,
			&a.Latitude, &a.Longitude, &a.FullAddress, &a.IsDefault, &a.CreatedAt, &a.UpdatedAt,
			&a.CountryName, &a.GovernorateName, &a.CityName,
		); err != nil {
			return nil, err
		}
		addresses = append(addresses, a)
	}
	return addresses, nil
}

func (r *Repository) GetByID(ctx context.Context, id uuid.UUID) (*Address, error) {
	query := `
		SELECT a.id, a.user_id, a.label, a.country_id, a.governorate_id, a.city_id,
			a.street_name, COALESCE(a.building_name,''), a.building_number,
			COALESCE(a.floor,''), COALESCE(a.apartment,''),
			a.latitude, a.longitude, COALESCE(a.full_address,''), a.is_default, a.created_at, a.updated_at,
			COALESCE(c.name_en,''), COALESCE(g.name_en,''), COALESCE(ci.name_en,'')
		FROM user_addresses a
		LEFT JOIN countries c ON c.id = a.country_id
		LEFT JOIN governorates g ON g.id = a.governorate_id
		LEFT JOIN cities ci ON ci.id = a.city_id
		WHERE a.id = $1
	`
	var a Address
	err := r.db.QueryRow(ctx, query, id).Scan(
		&a.ID, &a.UserID, &a.Label, &a.CountryID, &a.GovernorateID, &a.CityID,
		&a.StreetName, &a.BuildingName, &a.BuildingNumber,
		&a.Floor, &a.Apartment,
		&a.Latitude, &a.Longitude, &a.FullAddress, &a.IsDefault, &a.CreatedAt, &a.UpdatedAt,
		&a.CountryName, &a.GovernorateName, &a.CityName,
	)
	if err != nil {
		return nil, fmt.Errorf("address not found: %w", err)
	}
	return &a, nil
}

func (r *Repository) GetDefault(ctx context.Context, userID uuid.UUID) (*Address, error) {
	query := `
		SELECT a.id, a.user_id, a.label, a.country_id, a.governorate_id, a.city_id,
			a.street_name, COALESCE(a.building_name,''), a.building_number,
			COALESCE(a.floor,''), COALESCE(a.apartment,''),
			a.latitude, a.longitude, COALESCE(a.full_address,''), a.is_default, a.created_at, a.updated_at,
			COALESCE(c.name_en,''), COALESCE(g.name_en,''), COALESCE(ci.name_en,'')
		FROM user_addresses a
		LEFT JOIN countries c ON c.id = a.country_id
		LEFT JOIN governorates g ON g.id = a.governorate_id
		LEFT JOIN cities ci ON ci.id = a.city_id
		WHERE a.user_id = $1 AND a.is_default = true
		LIMIT 1
	`
	var a Address
	err := r.db.QueryRow(ctx, query, userID).Scan(
		&a.ID, &a.UserID, &a.Label, &a.CountryID, &a.GovernorateID, &a.CityID,
		&a.StreetName, &a.BuildingName, &a.BuildingNumber,
		&a.Floor, &a.Apartment,
		&a.Latitude, &a.Longitude, &a.FullAddress, &a.IsDefault, &a.CreatedAt, &a.UpdatedAt,
		&a.CountryName, &a.GovernorateName, &a.CityName,
	)
	if err != nil {
		return nil, fmt.Errorf("no default address: %w", err)
	}
	return &a, nil
}

func (r *Repository) SetDefault(ctx context.Context, userID, addressID uuid.UUID) error {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	// Unset current default
	tx.Exec(ctx, "UPDATE user_addresses SET is_default = false WHERE user_id = $1", userID)
	// Set new default
	tx.Exec(ctx, "UPDATE user_addresses SET is_default = true WHERE id = $1 AND user_id = $2", addressID, userID)

	return tx.Commit(ctx)
}

func (r *Repository) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.Exec(ctx, "DELETE FROM user_addresses WHERE id = $1", id)
	return err
}
