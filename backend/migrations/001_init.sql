-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    avatar_url TEXT DEFAULT '',
    role VARCHAR(20) NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'technician', 'admin', 'super_admin', 'operations_admin', 'support_admin')),
    is_active BOOLEAN DEFAULT true,
    language VARCHAR(10) DEFAULT 'en',
    property_type VARCHAR(50) DEFAULT '',
    device_token TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_users_email ON users(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_phone ON users(phone) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_role ON users(role) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_deleted_at ON users(deleted_at) WHERE deleted_at IS NOT NULL;

-- ============================================
-- TECHNICIAN PROFILES (Extension table)
-- ============================================
CREATE TABLE technician_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    bio TEXT DEFAULT '',
    hourly_rate DECIMAL(10,2) DEFAULT 0,
    is_verified BOOLEAN DEFAULT false,
    is_online BOOLEAN DEFAULT false,
    current_lat DOUBLE PRECISION DEFAULT 0,
    current_lng DOUBLE PRECISION DEFAULT 0,
    acceptance_rate DECIMAL(5,4) DEFAULT 0,
    cancel_rate DECIMAL(5,4) DEFAULT 0,
    strike_count INTEGER DEFAULT 0,
    avg_rating DECIMAL(3,2) DEFAULT 0,
    total_jobs INTEGER DEFAULT 0,
    national_id VARCHAR(255) DEFAULT '', -- encrypted
    device_fingerprint VARCHAR(255) DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for location-based queries
CREATE INDEX idx_technician_lat ON technician_profiles(current_lat);
CREATE INDEX idx_technician_lng ON technician_profiles(current_lng);
CREATE INDEX idx_technician_online ON technician_profiles(is_online) WHERE is_online = true;
CREATE INDEX idx_technician_verified ON technician_profiles(is_verified);
CREATE INDEX idx_technician_user_id ON technician_profiles(user_id);

-- ============================================
-- CATEGORIES (Parent-child tree)
-- ============================================
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    type VARCHAR(30) NOT NULL DEFAULT 'technician_role',
    name_en VARCHAR(255) NOT NULL,
    name_ar VARCHAR(255) NOT NULL,
    icon VARCHAR(100) DEFAULT '',
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_categories_parent ON categories(parent_id);
CREATE INDEX idx_categories_active ON categories(is_active) WHERE is_active = true;

-- ============================================
-- TECHNICIAN CATEGORIES (Many-to-Many)
-- ============================================
CREATE TABLE technician_categories (
    technician_id UUID NOT NULL REFERENCES technician_profiles(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    PRIMARY KEY (technician_id, category_id)
);

-- ============================================
-- BOOKINGS
-- ============================================
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    technician_id UUID REFERENCES users(id),
    category_id UUID NOT NULL REFERENCES categories(id),
    status VARCHAR(20) NOT NULL DEFAULT 'searching' CHECK (status IN ('searching', 'assigned', 'driving', 'arrived', 'active', 'completed', 'cancelled')),
    description TEXT NOT NULL,
    address TEXT NOT NULL,
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    scheduled_at TIMESTAMPTZ,
    arrival_code VARCHAR(4) DEFAULT '',
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    duration_minutes INTEGER DEFAULT 0,
    estimated_cost DECIMAL(10,2) DEFAULT 0,
    final_cost DECIMAL(10,2) DEFAULT 0,
    payment_method VARCHAR(10) NOT NULL DEFAULT 'card' CHECK (payment_method IN ('card', 'cash')),
    cancel_reason TEXT DEFAULT '',
    cancelled_by VARCHAR(20) DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_bookings_user ON bookings(user_id);
CREATE INDEX idx_bookings_technician ON bookings(technician_id) WHERE technician_id IS NOT NULL;
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_created ON bookings(created_at DESC);
CREATE INDEX idx_bookings_active ON bookings(technician_id, status) WHERE status IN ('assigned', 'driving', 'arrived', 'active');

-- ============================================
-- CHAT MESSAGES
-- ============================================
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id),
    content TEXT NOT NULL,
    type VARCHAR(20) DEFAULT 'text' CHECK (type IN ('text', 'image', 'system')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_chat_booking ON chat_messages(booking_id, created_at DESC);

-- ============================================
-- WALLET TRANSACTIONS (Ledger model)
-- ============================================
CREATE TABLE wallet_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    booking_id UUID REFERENCES bookings(id),
    type VARCHAR(20) NOT NULL CHECK (type IN ('job_credit', 'commission', 'withdrawal', 'penalty', 'debt', 'debt_payment')),
    amount DECIMAL(12,2) NOT NULL, -- positive = credit, negative = debit
    description TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_wallet_user ON wallet_transactions(user_id);
CREATE INDEX idx_wallet_type ON wallet_transactions(user_id, type);
CREATE INDEX idx_wallet_created ON wallet_transactions(created_at DESC);

-- ============================================
-- PAYMENTS
-- ============================================
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id),
    user_id UUID NOT NULL REFERENCES users(id),
    technician_id UUID NOT NULL REFERENCES users(id),
    amount DECIMAL(10,2) NOT NULL,
    commission DECIMAL(10,2) NOT NULL,
    technician_pay DECIMAL(10,2) NOT NULL,
    method VARCHAR(10) NOT NULL CHECK (method IN ('card', 'cash')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    gateway_ref VARCHAR(255) DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payments_booking ON payments(booking_id);
CREATE INDEX idx_payments_user ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_created ON payments(created_at DESC);

-- ============================================
-- RATINGS
-- ============================================
CREATE TABLE ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id),
    user_id UUID NOT NULL REFERENCES users(id),
    technician_id UUID NOT NULL REFERENCES technician_profiles(id),
    score INTEGER NOT NULL CHECK (score >= 1 AND score <= 5),
    comment TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(booking_id, user_id)
);

CREATE INDEX idx_ratings_technician ON ratings(technician_id);
CREATE INDEX idx_ratings_booking ON ratings(booking_id);

-- ============================================
-- SUPPORT TICKETS
-- ============================================
CREATE TABLE support_tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    assigned_to UUID REFERENCES users(id),
    subject VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    priority VARCHAR(10) NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_support_user ON support_tickets(user_id);
CREATE INDEX idx_support_status ON support_tickets(status);
CREATE INDEX idx_support_assigned ON support_tickets(assigned_to) WHERE assigned_to IS NOT NULL;

-- ============================================
-- SUPPORT TICKET MESSAGES
-- ============================================
CREATE TABLE support_ticket_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id),
    content TEXT NOT NULL,
    is_admin BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_support_msg_ticket ON support_ticket_messages(ticket_id, created_at ASC);

-- ============================================
-- AUDIT LOG
-- ============================================
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID,
    details JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_admin ON audit_logs(admin_id);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_created ON audit_logs(created_at DESC);

-- ============================================
-- SEED DATA: Default categories
-- ============================================
INSERT INTO categories (id, type, name_en, name_ar, icon, sort_order) VALUES
    (uuid_generate_v4(), 'customer_type', 'Personal Residential', 'سكني شخصي', 'home', 1),
    (uuid_generate_v4(), 'customer_type', 'Residential Compounds', 'مجمعات سكنية', 'apartment', 2),
    (uuid_generate_v4(), 'customer_type', 'Offices', 'مكاتب', 'business', 3),
    (uuid_generate_v4(), 'customer_type', 'Banks', 'بنوك', 'account_balance', 4),
    (uuid_generate_v4(), 'customer_type', 'Government Buildings', 'مباني حكومية', 'domain', 5),
    (uuid_generate_v4(), 'customer_type', 'Schools & Universities', 'مدارس وجامعات', 'school', 6),
    (uuid_generate_v4(), 'customer_type', 'Hospitals & Clinics', 'مستشفيات وعيادات', 'local_hospital', 7),
    (uuid_generate_v4(), 'customer_type', 'Hotels', 'فنادق', 'hotel', 8),
    (uuid_generate_v4(), 'customer_type', 'Retail Shops', 'محلات تجارية', 'store', 9),
    (uuid_generate_v4(), 'customer_type', 'Factories & Warehouses', 'مصانع ومستودعات', 'factory', 10),
    (uuid_generate_v4(), 'customer_type', 'Restaurants & Cafes', 'مطاعم ومقاهي', 'restaurant', 11),
    (uuid_generate_v4(), 'customer_type', 'Community Centers', 'مراكز مجتمعية', 'groups', 12),
    (uuid_generate_v4(), 'customer_type', 'Religious Buildings', 'مباني دينية (مساجد/كنائس)', 'mosque', 13),
    (uuid_generate_v4(), 'customer_type', 'Car Owners / Garages', 'سيارات / ورش سيارات', 'directions_car', 14);

INSERT INTO categories (id, type, name_en, name_ar, icon, sort_order) VALUES
    (uuid_generate_v4(), 'technician_role', 'Electrician', 'كهربائي', 'electrical_services', 1),
    (uuid_generate_v4(), 'technician_role', 'Plumber', 'سباك', 'plumbing', 2),
    (uuid_generate_v4(), 'technician_role', 'Carpenter', 'نجار', 'carpenter', 3),
    (uuid_generate_v4(), 'technician_role', 'Painter', 'دهان', 'format_paint', 4),
    (uuid_generate_v4(), 'technician_role', 'AC & HVAC Technician', 'فني تكييف وتبريد', 'ac_unit', 5),
    (uuid_generate_v4(), 'technician_role', 'Cleaner / Janitorial', 'عامل نظافة', 'cleaning_services', 6),
    (uuid_generate_v4(), 'technician_role', 'Appliance Repair Technician', 'صيانة الأجهزة المنزلية', 'kitchen', 7),
    (uuid_generate_v4(), 'technician_role', 'Security Systems Installer', 'تركيب أنظمة الأمن', 'security', 8),
    (uuid_generate_v4(), 'technician_role', 'IT / Networking Technician', 'فني شبكات وحواسيب', 'computer', 9),
    (uuid_generate_v4(), 'technician_role', 'Pest Control Technician', 'مكافحة الحشرات', 'pest_control', 10),
    (uuid_generate_v4(), 'technician_role', 'Gardener / Landscaping', 'بستاني / تنسيق حدائق', 'yard', 11),
    (uuid_generate_v4(), 'technician_role', 'Pool Maintenance Technician', 'صيانة مسابح', 'pool', 12),
    (uuid_generate_v4(), 'technician_role', 'Locksmith', 'صانع مفاتيح', 'lock', 13),
    (uuid_generate_v4(), 'technician_role', 'Interior Designer / Decorator', 'مصمم داخلي / ديكور', 'design_services', 14),
    (uuid_generate_v4(), 'technician_role', 'General Handyman', 'عامل صيانة متعدد', 'handyman', 15),
    (uuid_generate_v4(), 'technician_role', 'Car Mechanic / Auto Repair', 'ميكانيكي سيارات / صيانة سيارات', 'car_repair', 16),
    (uuid_generate_v4(), 'technician_role', 'Car Electrician', 'كهربائي سيارات', 'electric_car', 17),
    (uuid_generate_v4(), 'technician_role', 'Car Wash & Detailing', 'غسيل وتلميع سيارات', 'local_car_wash', 18),
    (uuid_generate_v4(), 'technician_role', 'Tire & Wheel Specialist', 'فني إطارات وعجلات', 'tire_repair', 19),
    (uuid_generate_v4(), 'technician_role', 'Car AC Technician', 'فني تكييف سيارات', 'air', 20);

-- ============================================
-- SEED DATA: Admin user (password: admin123456)
-- ============================================
INSERT INTO users (id, email, phone, password_hash, full_name, role, is_active)
VALUES (
    uuid_generate_v4(),
    'admin@techapp.com',
    '+1000000000',
    '$2a$10$pc0YVxkphDiB00zGRgcLge.stJVno5Gup9Qn4C3aKSts9Qnwoqu6m',
    'System Admin',
    'super_admin',
    true
);
