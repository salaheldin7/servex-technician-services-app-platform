-- ============================================
-- MAKE governorate_id NULLABLE in technician_service_locations
-- This allows technicians to select only a country without specifying a governorate
-- ============================================

ALTER TABLE technician_service_locations ALTER COLUMN governorate_id DROP NOT NULL;

-- Drop old unique indexes that assume governorate_id is always present
DROP INDEX IF EXISTS idx_tech_locs_unique_city;
DROP INDEX IF EXISTS idx_tech_locs_unique_gov;

-- Recreate unique indexes that handle nullable governorate_id
-- When both governorate and city are specified
CREATE UNIQUE INDEX IF NOT EXISTS idx_tech_locs_unique_city ON technician_service_locations(technician_id, country_id, governorate_id, city_id)
    WHERE governorate_id IS NOT NULL AND city_id IS NOT NULL;

-- When only governorate is specified (no city)
CREATE UNIQUE INDEX IF NOT EXISTS idx_tech_locs_unique_gov ON technician_service_locations(technician_id, country_id, governorate_id)
    WHERE governorate_id IS NOT NULL AND city_id IS NULL;

-- When only country is specified (no governorate, no city)
CREATE UNIQUE INDEX IF NOT EXISTS idx_tech_locs_unique_country ON technician_service_locations(technician_id, country_id)
    WHERE governorate_id IS NULL AND city_id IS NULL;
