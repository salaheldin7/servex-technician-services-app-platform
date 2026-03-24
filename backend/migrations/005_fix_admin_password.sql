-- ============================================
-- MIGRATION 005: Fix admin password hash
-- ============================================

-- Update admin user password hash to correct bcrypt hash for 'admin123456'
UPDATE users
SET password_hash = '$2a$10$pc0YVxkphDiB00zGRgcLge.stJVno5Gup9Qn4C3aKSts9Qnwoqu6m',
    updated_at = NOW()
WHERE email = 'admin@techapp.com';
