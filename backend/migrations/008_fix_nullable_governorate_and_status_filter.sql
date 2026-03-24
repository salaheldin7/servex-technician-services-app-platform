-- ============================================
-- 008: Ensure governorate_id is nullable & add verification_status index
-- Idempotent - safe to run multiple times
-- ============================================

-- 1. Make governorate_id nullable (idempotent)
DO $$
BEGIN
    -- Check if the column is still NOT NULL and fix it
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'technician_service_locations'
        AND column_name = 'governorate_id'
        AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE technician_service_locations ALTER COLUMN governorate_id DROP NOT NULL;
        RAISE NOTICE 'Made governorate_id nullable';
    END IF;
END $$;

-- 2. Also make city_id explicitly nullable (should already be, just ensure)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'technician_service_locations'
        AND column_name = 'city_id'
        AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE technician_service_locations ALTER COLUMN city_id DROP NOT NULL;
        RAISE NOTICE 'Made city_id nullable';
    END IF;
END $$;

-- 3. Recreate unique indexes to properly handle nullable columns
DROP INDEX IF EXISTS idx_tech_locs_unique_city;
DROP INDEX IF EXISTS idx_tech_locs_unique_gov;
DROP INDEX IF EXISTS idx_tech_locs_unique_country;

-- When both governorate and city are specified
CREATE UNIQUE INDEX IF NOT EXISTS idx_tech_locs_unique_city ON technician_service_locations(technician_id, country_id, governorate_id, city_id)
    WHERE governorate_id IS NOT NULL AND city_id IS NOT NULL;

-- When only governorate is specified (no city)
CREATE UNIQUE INDEX IF NOT EXISTS idx_tech_locs_unique_gov ON technician_service_locations(technician_id, country_id, governorate_id)
    WHERE governorate_id IS NOT NULL AND city_id IS NULL;

-- When only country is specified (no governorate, no city)
CREATE UNIQUE INDEX IF NOT EXISTS idx_tech_locs_unique_country ON technician_service_locations(technician_id, country_id)
    WHERE governorate_id IS NULL AND city_id IS NULL;

-- 4. Add index on verification_status for admin filtering
CREATE INDEX IF NOT EXISTS idx_tech_profiles_verification_status ON technician_profiles(verification_status);
