package locations

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	db *pgxpool.Pool
}

func NewRepository(db *pgxpool.Pool) *Repository {
	return &Repository{db: db}
}

func (r *Repository) ListCountries(ctx context.Context) ([]Country, error) {
	query := `SELECT id, name_en, name_ar, code, phone_code, currency_code, currency_symbol, is_active, created_at
		FROM countries WHERE is_active = true ORDER BY name_en ASC`
	rows, err := r.db.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var countries []Country
	for rows.Next() {
		var c Country
		if err := rows.Scan(&c.ID, &c.NameEN, &c.NameAR, &c.Code, &c.PhoneCode, &c.CurrencyCode, &c.CurrencySymbol, &c.IsActive, &c.CreatedAt); err != nil {
			return nil, err
		}
		countries = append(countries, c)
	}
	return countries, nil
}

func (r *Repository) ListGovernorates(ctx context.Context, countryID uuid.UUID) ([]Governorate, error) {
	query := `SELECT id, country_id, name_en, name_ar, code, is_active, created_at
		FROM governorates WHERE country_id = $1 AND is_active = true ORDER BY name_en ASC`
	rows, err := r.db.Query(ctx, query, countryID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var govs []Governorate
	for rows.Next() {
		var g Governorate
		if err := rows.Scan(&g.ID, &g.CountryID, &g.NameEN, &g.NameAR, &g.Code, &g.IsActive, &g.CreatedAt); err != nil {
			return nil, err
		}
		govs = append(govs, g)
	}
	return govs, nil
}

func (r *Repository) ListCities(ctx context.Context, governorateID uuid.UUID) ([]City, error) {
	query := `SELECT id, governorate_id, name_en, name_ar, code, is_active, created_at
		FROM cities WHERE governorate_id = $1 AND is_active = true ORDER BY name_en ASC`
	rows, err := r.db.Query(ctx, query, governorateID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var cities []City
	for rows.Next() {
		var c City
		if err := rows.Scan(&c.ID, &c.GovernorateID, &c.NameEN, &c.NameAR, &c.Code, &c.IsActive, &c.CreatedAt); err != nil {
			return nil, err
		}
		cities = append(cities, c)
	}
	return cities, nil
}
