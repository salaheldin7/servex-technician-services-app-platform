-- Migration 009: Add search technicians by service + location, task_status usage

-- Ensure task_status column has proper default (already exists from migration 004)
-- Update existing bookings without task_status
UPDATE bookings SET task_status = 
    CASE 
        WHEN status = 'searching' THEN 'searching'
        WHEN status = 'assigned' THEN 'technician_coming'
        WHEN status = 'driving' THEN 'technician_coming'
        WHEN status = 'arrived' THEN 'technician_coming'
        WHEN status = 'active' THEN 'technician_working'
        WHEN status = 'completed' THEN 'task_closed'
        WHEN status = 'cancelled' THEN 'task_closed'
        ELSE 'searching'
    END
WHERE task_status IS NULL OR task_status = '';

-- Add index for technician service location matching
CREATE INDEX IF NOT EXISTS idx_technician_service_locations_lookup 
    ON technician_service_locations(country_id, governorate_id, city_id);

-- Add index for technician services category lookup
CREATE INDEX IF NOT EXISTS idx_technician_services_category 
    ON technician_services(category_id, is_active);

-- Add index for bookings task_status
CREATE INDEX IF NOT EXISTS idx_bookings_task_status ON bookings(task_status);

-- Add index for bookings active lookup
CREATE INDEX IF NOT EXISTS idx_bookings_active ON bookings(status) WHERE status NOT IN ('completed', 'cancelled');
