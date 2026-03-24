-- 010: Add floor and apartment columns to bookings and user_addresses
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS floor VARCHAR(20) DEFAULT '';
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS apartment VARCHAR(50) DEFAULT '';
ALTER TABLE user_addresses ADD COLUMN IF NOT EXISTS floor VARCHAR(20) DEFAULT '';
ALTER TABLE user_addresses ADD COLUMN IF NOT EXISTS apartment VARCHAR(50) DEFAULT '';
