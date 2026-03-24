-- ============================================
-- COUNTRIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS countries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_en VARCHAR(255) NOT NULL,
    name_ar VARCHAR(255) NOT NULL,
    code VARCHAR(5) NOT NULL UNIQUE,
    phone_code VARCHAR(10) NOT NULL DEFAULT '',
    currency_code VARCHAR(5) NOT NULL DEFAULT '',
    currency_symbol VARCHAR(10) NOT NULL DEFAULT '',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_countries_code ON countries(code);
CREATE INDEX idx_countries_active ON countries(is_active) WHERE is_active = true;

-- ============================================
-- GOVERNORATES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS governorates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    country_id UUID NOT NULL REFERENCES countries(id) ON DELETE CASCADE,
    name_en VARCHAR(255) NOT NULL,
    name_ar VARCHAR(255) NOT NULL,
    code VARCHAR(10) NOT NULL DEFAULT '',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_governorates_country ON governorates(country_id);
CREATE INDEX idx_governorates_active ON governorates(is_active) WHERE is_active = true;

-- ============================================
-- CITIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS cities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    governorate_id UUID NOT NULL REFERENCES governorates(id) ON DELETE CASCADE,
    name_en VARCHAR(255) NOT NULL,
    name_ar VARCHAR(255) NOT NULL,
    code VARCHAR(10) NOT NULL DEFAULT '',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cities_governorate ON cities(governorate_id);
CREATE INDEX idx_cities_active ON cities(is_active) WHERE is_active = true;

-- ============================================
-- TECHNICIAN FACE VERIFICATION
-- ============================================
CREATE TABLE IF NOT EXISTS technician_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL REFERENCES technician_profiles(id) ON DELETE CASCADE,
    face_front_url TEXT DEFAULT '',
    face_right_url TEXT DEFAULT '',
    face_left_url TEXT DEFAULT '',
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_tech_verify_tech ON technician_verifications(technician_id);
CREATE INDEX idx_tech_verify_status ON technician_verifications(status);

-- ============================================
-- TECHNICIAN ID DOCUMENTS
-- ============================================
CREATE TABLE IF NOT EXISTS technician_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL REFERENCES technician_profiles(id) ON DELETE CASCADE,
    doc_type VARCHAR(20) NOT NULL DEFAULT 'id_card' CHECK (doc_type IN ('id_card_front', 'id_card_back', 'id_pdf')),
    file_url TEXT NOT NULL,
    file_type VARCHAR(10) NOT NULL DEFAULT 'jpeg' CHECK (file_type IN ('jpeg', 'jpg', 'png', 'pdf')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tech_docs_tech ON technician_documents(technician_id);

-- ============================================
-- TECHNICIAN SERVICES (with wage per service)
-- ============================================
CREATE TABLE IF NOT EXISTS technician_services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL REFERENCES technician_profiles(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    hourly_rate DECIMAL(10,2) NOT NULL DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(technician_id, category_id)
);

CREATE INDEX idx_tech_services_tech ON technician_services(technician_id);
CREATE INDEX idx_tech_services_cat ON technician_services(category_id);

-- ============================================
-- TECHNICIAN SERVICE LOCATIONS
-- ============================================
CREATE TABLE IF NOT EXISTS technician_service_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    technician_id UUID NOT NULL REFERENCES technician_profiles(id) ON DELETE CASCADE,
    country_id UUID NOT NULL REFERENCES countries(id) ON DELETE CASCADE,
    governorate_id UUID NOT NULL REFERENCES governorates(id) ON DELETE CASCADE,
    city_id UUID REFERENCES cities(id) ON DELETE CASCADE, -- NULL means all cities in governorate
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Unique index for specific city entries
CREATE UNIQUE INDEX idx_tech_locs_unique_city ON technician_service_locations(technician_id, country_id, governorate_id, city_id) WHERE city_id IS NOT NULL;
-- Unique index for whole-governorate entries (city_id IS NULL)
CREATE UNIQUE INDEX idx_tech_locs_unique_gov ON technician_service_locations(technician_id, country_id, governorate_id) WHERE city_id IS NULL;

CREATE INDEX idx_tech_locs_tech ON technician_service_locations(technician_id);
CREATE INDEX idx_tech_locs_country ON technician_service_locations(country_id);
CREATE INDEX idx_tech_locs_gov ON technician_service_locations(governorate_id);
CREATE INDEX idx_tech_locs_city ON technician_service_locations(city_id);

-- ============================================
-- ADD LOCATION FIELDS TO BOOKINGS
-- ============================================
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS country_id UUID REFERENCES countries(id);
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS governorate_id UUID REFERENCES governorates(id);
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS city_id UUID REFERENCES cities(id);

-- ============================================
-- ADD VERIFICATION STATUS TO TECHNICIAN PROFILES
-- ============================================
ALTER TABLE technician_profiles ADD COLUMN IF NOT EXISTS verification_status VARCHAR(20) DEFAULT 'none' CHECK (verification_status IN ('none', 'pending', 'face_done', 'docs_done', 'verified', 'rejected'));

-- ============================================
-- SEED: Egypt + Giza cities
-- ============================================
DO $$
DECLARE
    egypt_id UUID;
    giza_id UUID;
    cairo_id UUID;
BEGIN
    -- Insert Egypt
    INSERT INTO countries (id, name_en, name_ar, code, phone_code, currency_code, currency_symbol)
    VALUES (uuid_generate_v4(), 'Egypt', 'مصر', 'EG', '+20', 'EGP', 'ج.م')
    ON CONFLICT (code) DO NOTHING
    RETURNING id INTO egypt_id;

    IF egypt_id IS NULL THEN
        SELECT id INTO egypt_id FROM countries WHERE code = 'EG';
    END IF;

    -- Insert Egyptian Governorates
    INSERT INTO governorates (id, country_id, name_en, name_ar, code) VALUES
        (uuid_generate_v4(), egypt_id, 'Cairo', 'القاهرة', 'CAI'),
        (uuid_generate_v4(), egypt_id, 'Alexandria', 'الإسكندرية', 'ALX'),
        (uuid_generate_v4(), egypt_id, 'Giza', 'الجيزة', 'GIZ'),
        (uuid_generate_v4(), egypt_id, 'Qalyubia', 'القليوبية', 'QLY'),
        (uuid_generate_v4(), egypt_id, 'Port Said', 'بورسعيد', 'PTS'),
        (uuid_generate_v4(), egypt_id, 'Suez', 'السويس', 'SUZ'),
        (uuid_generate_v4(), egypt_id, 'Luxor', 'الأقصر', 'LXR'),
        (uuid_generate_v4(), egypt_id, 'Aswan', 'أسوان', 'ASN'),
        (uuid_generate_v4(), egypt_id, 'Asyut', 'أسيوط', 'AST'),
        (uuid_generate_v4(), egypt_id, 'Beheira', 'البحيرة', 'BHR'),
        (uuid_generate_v4(), egypt_id, 'Beni Suef', 'بني سويف', 'BNS'),
        (uuid_generate_v4(), egypt_id, 'Dakahlia', 'الدقهلية', 'DKH'),
        (uuid_generate_v4(), egypt_id, 'Damietta', 'دمياط', 'DMT'),
        (uuid_generate_v4(), egypt_id, 'Fayyum', 'الفيوم', 'FYM'),
        (uuid_generate_v4(), egypt_id, 'Gharbia', 'الغربية', 'GHR'),
        (uuid_generate_v4(), egypt_id, 'Ismailia', 'الإسماعيلية', 'ISM'),
        (uuid_generate_v4(), egypt_id, 'Kafr el-Sheikh', 'كفر الشيخ', 'KFS'),
        (uuid_generate_v4(), egypt_id, 'Matrouh', 'مطروح', 'MTR'),
        (uuid_generate_v4(), egypt_id, 'Minya', 'المنيا', 'MNY'),
        (uuid_generate_v4(), egypt_id, 'Monufia', 'المنوفية', 'MNF'),
        (uuid_generate_v4(), egypt_id, 'New Valley', 'الوادي الجديد', 'WAD'),
        (uuid_generate_v4(), egypt_id, 'North Sinai', 'شمال سيناء', 'NSI'),
        (uuid_generate_v4(), egypt_id, 'Qena', 'قنا', 'QNA'),
        (uuid_generate_v4(), egypt_id, 'Red Sea', 'البحر الأحمر', 'SEA'),
        (uuid_generate_v4(), egypt_id, 'Sharqia', 'الشرقية', 'SHR'),
        (uuid_generate_v4(), egypt_id, 'Sohag', 'سوهاج', 'SOH'),
        (uuid_generate_v4(), egypt_id, 'South Sinai', 'جنوب سيناء', 'SSI'),
        (uuid_generate_v4(), egypt_id, 'New Administrative Capital', 'العاصمة الإدارية الجديدة', 'NAC')
    ON CONFLICT DO NOTHING;

    -- Get Giza ID for cities
    SELECT id INTO giza_id FROM governorates WHERE code = 'GIZ' AND country_id = egypt_id;

    IF giza_id IS NOT NULL THEN
        INSERT INTO cities (governorate_id, name_en, name_ar, code) VALUES
            (giza_id, '6th of October', '6 أكتوبر', '6OCT'),
            (giza_id, 'Sheikh Zayed', 'الشيخ زايد', 'SZ'),
            (giza_id, 'Hadayek October', 'حدائق أكتوبر', 'HDO'),
            (giza_id, 'Smart Village', 'القرية الذكية', 'SMV'),
            (giza_id, 'Dokki', 'الدقي', 'DOK'),
            (giza_id, 'Mohandessin', 'المهندسين', 'MHN'),
            (giza_id, 'Agouza', 'العجوزة', 'AGZ'),
            (giza_id, 'Giza', 'الجيزة', 'GIZ'),
            (giza_id, 'Omraneya', 'العمرانية', 'OMR'),
            (giza_id, 'Haram', 'الهرم', 'HRM'),
            (giza_id, 'Faisal', 'فيصل', 'FSL'),
            (giza_id, 'Imbaba', 'إمبابة', 'IMB'),
            (giza_id, 'Bulaq Al Dakrour', 'بولاق الدكرور', 'BLD'),
            (giza_id, 'Warraq', 'الوراق', 'WRQ'),
            (giza_id, 'Ard El Lewa', 'أرض اللواء', 'ADL'),
            (giza_id, 'Palm Hills', 'بالم هيلز', 'PLM'),
            (giza_id, 'Dreamland', 'دريم لاند', 'DRM'),
            (giza_id, 'Beverly Hills', 'بيفرلي هيلز', 'BVH'),
            (giza_id, 'Pyramids Gardens', 'حدائق الأهرام', 'PYG'),
            (giza_id, 'Marioteya', 'المريوطية', 'MRY'),
            (giza_id, 'Abu Nomros', 'أبو النمرس', 'ABN'),
            (giza_id, 'Kerdasa', 'كرداسة', 'KRD'),
            (giza_id, 'Ausim', 'أوسيم', 'AUS'),
            (giza_id, 'Badrasheen', 'البدرشين', 'BDS'),
            (giza_id, 'El Saff', 'الصف', 'SFF'),
            (giza_id, 'Ayat', 'العياط', 'AYT'),
            (giza_id, 'Atfih', 'أطفيح', 'ATF'),
            (giza_id, 'Kit Kat', 'كيت كات', 'KTK'),
            (giza_id, 'El Munib', 'المنيب', 'MNB'),
            (giza_id, 'Talbeya', 'الطالبية', 'TLB'),
            (giza_id, 'Saft El Laban', 'صفط اللبن', 'SFL'),
            (giza_id, 'Boulaq', 'بولاق', 'BLQ'),
            (giza_id, 'Bashtil', 'البشتيل', 'BSH'),
            (giza_id, 'Nahya', 'النهضة', 'NHY'),
            (giza_id, 'Mansoureya', 'المنصورية', 'MNS'),
            (giza_id, 'Dahshour', 'دهشور', 'DHS'),
            (giza_id, 'Saqqara', 'سقارة', 'SQR')
        ON CONFLICT DO NOTHING;
    END IF;

    -- Get Cairo ID for cities
    SELECT id INTO cairo_id FROM governorates WHERE code = 'CAI' AND country_id = egypt_id;

    IF cairo_id IS NOT NULL THEN
        INSERT INTO cities (governorate_id, name_en, name_ar, code) VALUES
            (cairo_id, 'New Cairo', 'القاهرة الجديدة', 'NC'),
            (cairo_id, '5th Settlement', 'التجمع الخامس', '5TH'),
            (cairo_id, 'Rehab', 'الرحاب', 'RHB'),
            (cairo_id, 'Madinaty', 'مدينتي', 'MDN'),
            (cairo_id, 'Shorouk', 'الشروق', 'SHR'),
            (cairo_id, 'Obour', 'العبور', 'OBR'),
            (cairo_id, 'Heliopolis', 'مصر الجديدة', 'HLP'),
            (cairo_id, 'Nasr City', 'مدينة نصر', 'NSR'),
            (cairo_id, 'Maadi', 'المعادي', 'MAD'),
            (cairo_id, 'Downtown Cairo', 'وسط البلد', 'DT'),
            (cairo_id, 'Zamalek', 'الزمالك', 'ZAM'),
            (cairo_id, 'Garden City', 'جاردن سيتي', 'GC'),
            (cairo_id, 'Mokattam', 'المقطم', 'MOK'),
            (cairo_id, 'Ain Shams', 'عين شمس', 'ASH'),
            (cairo_id, 'Shubra', 'شبرا', 'SHB'),
            (cairo_id, 'Helwan', 'حلوان', 'HLW'),
            (cairo_id, 'Hadayek El Maadi', 'حدائق المعادي', 'HDM'),
            (cairo_id, 'Katameya', 'القطامية', 'KTM'),
            (cairo_id, 'Badr City', 'مدينة بدر', 'BDR'),
            (cairo_id, 'El Salam City', 'مدينة السلام', 'SLM'),
            (cairo_id, 'Abbasiya', 'العباسية', 'ABS'),
            (cairo_id, 'Ramses', 'رمسيس', 'RMS'),
            (cairo_id, 'Sayeda Zeinab', 'السيدة زينب', 'SZN'),
            (cairo_id, 'Basateen', 'البساتين', 'BST'),
            (cairo_id, 'Dar El Salam', 'دار السلام', 'DSL'),
            (cairo_id, 'Zeitoun', 'الزيتون', 'ZTN'),
            (cairo_id, 'Matariya', 'المطرية', 'MTR'),
            (cairo_id, 'El Marg', 'المرج', 'MRJ'),
            (cairo_id, 'Future City', 'مدينة المستقبل', 'FTC'),
            (cairo_id, '15th May City', 'مدينة 15 مايو', '15M')
        ON CONFLICT DO NOTHING;
    END IF;

END $$;
