-- ============================================
-- MIGRATION 004: Usernames, Notifications, User Addresses, Task Tracking
-- ============================================

-- ============================================
-- ADD USERNAME TO USERS
-- ============================================
ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(50);

-- Generate random usernames for existing users (name + random 4 digits)
DO $$
DECLARE
    r RECORD;
    base_name TEXT;
    new_username TEXT;
    suffix INT;
BEGIN
    FOR r IN SELECT id, full_name FROM users WHERE username IS NULL OR username = '' LOOP
        -- Clean the name: lowercase, remove spaces, take first part
        base_name := lower(regexp_replace(split_part(r.full_name, ' ', 1), '[^a-zA-Z0-9]', '', 'g'));
        IF base_name = '' THEN
            base_name := 'user';
        END IF;

        -- Generate unique username with random suffix
        LOOP
            suffix := floor(random() * 9000 + 1000)::INT;
            new_username := base_name || suffix;
            -- Check uniqueness
            IF NOT EXISTS (SELECT 1 FROM users WHERE username = new_username) THEN
                UPDATE users SET username = new_username WHERE id = r.id;
                EXIT;
            END IF;
        END LOOP;
    END LOOP;
END $$;

-- Now make it NOT NULL and UNIQUE
ALTER TABLE users ALTER COLUMN username SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username ON users(username) WHERE deleted_at IS NULL;

-- ============================================
-- NOTIFICATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL DEFAULT '',
    type VARCHAR(50) NOT NULL DEFAULT 'general',
    -- Types: verification_approved, verification_rejected, booking_request,
    --        booking_accepted, booking_cancelled, booking_completed,
    --        support_reply, payment, general
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = false;
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);

-- ============================================
-- USER ADDRESSES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS user_addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    label VARCHAR(100) NOT NULL DEFAULT 'Home',
    country_id UUID REFERENCES countries(id),
    governorate_id UUID REFERENCES governorates(id),
    city_id UUID REFERENCES cities(id),
    street_name VARCHAR(255) NOT NULL DEFAULT '',
    building_name VARCHAR(255) DEFAULT '',
    building_number VARCHAR(50) NOT NULL DEFAULT '',
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    full_address TEXT DEFAULT '',
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_addresses_user ON user_addresses(user_id);
CREATE INDEX idx_user_addresses_default ON user_addresses(user_id, is_default) WHERE is_default = true;

-- ============================================
-- ADD ADDRESS FIELDS TO BOOKINGS
-- ============================================
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS address_id UUID REFERENCES user_addresses(id);
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS street_name VARCHAR(255) DEFAULT '';
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS building_name VARCHAR(255) DEFAULT '';
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS building_number VARCHAR(50) DEFAULT '';
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS full_address TEXT DEFAULT '';
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS task_status VARCHAR(30) DEFAULT 'searching'
    CHECK (task_status IN ('searching', 'technician_coming', 'technician_working', 'technician_finished', 'task_closed'));

-- ============================================
-- ADD REJECTION REASON TO TECHNICIAN PROFILES
-- ============================================
ALTER TABLE technician_profiles ADD COLUMN IF NOT EXISTS rejection_reason TEXT DEFAULT '';

-- ============================================
-- ENSURE UNIQUE CONSTRAINTS ON ACTIVE ACCOUNTS
-- ============================================
-- Ensure unique email for active (non-deleted) accounts
DROP INDEX IF EXISTS idx_users_email_unique_active;
CREATE UNIQUE INDEX idx_users_email_unique_active ON users(email) WHERE deleted_at IS NULL;

-- Ensure unique phone for active (non-deleted) accounts
DROP INDEX IF EXISTS idx_users_phone_unique_active;
CREATE UNIQUE INDEX idx_users_phone_unique_active ON users(phone) WHERE deleted_at IS NULL;

-- ============================================
-- ADD ADMIN REPLY SUPPORT FOR TICKETS
-- ============================================
ALTER TABLE support_ticket_messages ADD COLUMN IF NOT EXISTS sender_name VARCHAR(255) DEFAULT '';

