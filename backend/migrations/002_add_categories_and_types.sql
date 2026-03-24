-- Migration 002: Add category types, property types, and new seed data
-- Run: psql -U techapp -d techapp -h localhost -f 002_add_categories_and_types.sql

-- ============================================
-- SCHEMA CHANGES
-- ============================================

-- Add type column to categories (customer_type or technician_role)
ALTER TABLE categories ADD COLUMN IF NOT EXISTS type VARCHAR(30) DEFAULT 'technician_role';

-- Add property_type column to users
ALTER TABLE users ADD COLUMN IF NOT EXISTS property_type VARCHAR(50) DEFAULT '';

-- ============================================
-- CLEAR OLD SEED DATA
-- ============================================
DELETE FROM technician_categories;
DELETE FROM categories;

-- ============================================
-- SEED: Customer Property Types (14)
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

-- ============================================
-- SEED: Technician Service Roles (20)
-- ============================================
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
