-- ExtraBite Supabase PostgreSQL Schema
-- Surplus Food Discovery & Reservation Platform for PGs and Hostels

-- 1. Custom Types
CREATE TYPE user_role AS ENUM ('customer', 'pg_owner', 'admin');
CREATE TYPE dietary_type AS ENUM ('vegetarian', 'non_vegetarian', 'vegan', 'egg');
CREATE TYPE listing_status AS ENUM ('active', 'paused', 'sold_out', 'expired', 'removed');
CREATE TYPE reservation_status AS ENUM ('draft', 'confirmed', 'ready_for_pickup', 'picked_up', 'cancelled', 'expired', 'no_show', 'rejected');

-- 2. Profiles Table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone_number TEXT,
    role user_role NOT NULL DEFAULT 'customer',
    avatar_url TEXT,
    dietary_preferences TEXT[] DEFAULT '{}',
    is_verified BOOLEAN DEFAULT false,
    is_suspended BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. PG / Hostel Profiles Table
CREATE TABLE IF NOT EXISTS pg_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    pg_name TEXT NOT NULL,
    description TEXT,
    address TEXT NOT NULL,
    neighborhood TEXT NOT NULL,
    city TEXT NOT NULL DEFAULT 'Bengaluru',
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    contact_phone TEXT NOT NULL,
    fssai_license_number TEXT,
    is_approved BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    rating DOUBLE PRECISION DEFAULT 4.8,
    total_reviews INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Food Listings Table
CREATE TABLE IF NOT EXISTS food_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pg_id UUID NOT NULL REFERENCES pg_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL, -- Lunch, Dinner, Breakfast, Snacks
    image_url TEXT,
    original_price DECIMAL(10,2) NOT NULL,
    discounted_price DECIMAL(10,2) NOT NULL, -- ExtraBite Price (Pay at pickup)
    total_portions INTEGER NOT NULL CHECK (total_portions > 0),
    available_portions INTEGER NOT NULL CHECK (available_portions >= 0),
    dietary_type dietary_type NOT NULL DEFAULT 'vegetarian',
    allergens TEXT[] DEFAULT '{}',
    pickup_start_time TIMESTAMPTZ NOT NULL,
    pickup_end_time TIMESTAMPTZ NOT NULL,
    pickup_instructions TEXT,
    status listing_status NOT NULL DEFAULT 'active',
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Reservations Table (Strictly Pay at Pickup)
CREATE TABLE IF NOT EXISTS reservations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    readable_id TEXT UNIQUE NOT NULL, -- e.g. EB-84920
    listing_id UUID NOT NULL REFERENCES food_listings(id) ON DELETE RESTRICT,
    customer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    portions_count INTEGER NOT NULL CHECK (portions_count > 0),
    unit_price DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    payment_method TEXT NOT NULL DEFAULT 'pay_at_pickup', -- Invariant: 'pay_at_pickup' only
    status reservation_status NOT NULL DEFAULT 'confirmed',
    pickup_token TEXT NOT NULL,
    qr_payload TEXT NOT NULL,
    pickup_deadline TIMESTAMPTZ NOT NULL,
    picked_up_at TIMESTAMPTZ,
    cancellation_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Reports Table
CREATE TABLE IF NOT EXISTS listing_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    listing_id UUID REFERENCES food_listings(id) ON DELETE SET NULL,
    pg_id UUID REFERENCES pg_profiles(id) ON DELETE SET NULL,
    reason TEXT NOT NULL,
    description TEXT,
    image_evidence_url TEXT,
    status TEXT NOT NULL DEFAULT 'pending', -- pending, resolved, dismissed
    admin_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

-- 7. Audit Log Table
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    actor_role user_role NOT NULL,
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    details JSONB DEFAULT '{}',
    ip_address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Row Level Security (RLS) Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE pg_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE food_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE listing_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Profiles: Public read, self update
CREATE POLICY "Profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update their own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Food Listings: Viewable by anyone if active, manageable by PG owner
CREATE POLICY "Active listings are viewable by everyone" ON food_listings FOR SELECT USING (status != 'removed');
CREATE POLICY "PG owners can manage their listings" ON food_listings FOR ALL USING (
    pg_id IN (SELECT id FROM pg_profiles WHERE owner_id = auth.uid())
);

-- Reservations: Viewable by customer and PG owner
CREATE POLICY "Customers view own reservations" ON reservations FOR SELECT USING (customer_id = auth.uid());
CREATE POLICY "Owners view reservations for their listings" ON reservations FOR SELECT USING (
    listing_id IN (
        SELECT fl.id FROM food_listings fl
        JOIN pg_profiles pg ON fl.pg_id = pg.id
        WHERE pg.owner_id = auth.uid()
    )
);

-- 9. Automatic Inventory Trigger on Reservation Cancellation
CREATE OR REPLACE FUNCTION restore_listing_portions_on_cancellation()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.status = 'confirmed' OR OLD.status = 'ready_for_pickup') AND NEW.status = 'cancelled' THEN
        UPDATE food_listings
        SET available_portions = available_portions + OLD.portions_count,
            status = CASE WHEN status = 'sold_out' THEN 'active'::listing_status ELSE status END
        WHERE id = OLD.listing_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_restore_portions_on_cancel
AFTER UPDATE ON reservations
FOR EACH ROW
EXECUTE FUNCTION restore_listing_portions_on_cancellation();
