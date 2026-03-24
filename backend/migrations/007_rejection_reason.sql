-- ============================================
-- Add rejection_reason column to technician_profiles
-- Stores the reason when admin rejects a technician
-- ============================================

ALTER TABLE technician_profiles ADD COLUMN IF NOT EXISTS rejection_reason TEXT DEFAULT '';
