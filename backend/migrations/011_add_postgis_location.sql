-- Migration 011: Add PostGIS location column to technician_profiles
-- The code references tp.location but the column was never created.

-- Enable PostGIS extension (already available in postgis/postgis Docker image)
CREATE EXTENSION IF NOT EXISTS postgis;

-- Add geometry column for spatial queries
ALTER TABLE technician_profiles ADD COLUMN IF NOT EXISTS location geometry(Point, 4326);

-- Populate location from existing lat/lng data
UPDATE technician_profiles
SET location = ST_SetSRID(ST_MakePoint(current_lng, current_lat), 4326)
WHERE current_lat != 0 AND current_lng != 0 AND location IS NULL;

-- Create spatial index for fast proximity queries
CREATE INDEX IF NOT EXISTS idx_technician_location_gist ON technician_profiles USING GIST (location);

-- Also add a geography-cast index for ST_DWithin queries
CREATE INDEX IF NOT EXISTS idx_technician_location_geog ON technician_profiles USING GIST ((location::geography));
