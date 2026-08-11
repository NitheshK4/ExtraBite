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
    CONSTRAINT check_available_portions_bound CHECK (available_portions <= total_portions),
    dietary_type dietary_type NOT NULL DEFAULT 'vegetarian',
    ingredients TEXT[] DEFAULT '{}',
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

-- Profiles: Public read, self update (with trigger enforcing column protections)
CREATE POLICY "Profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update their own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- pg_profiles: Customers select active/approved, Owners manage own, Admins manage all
CREATE POLICY "Approved active PGs are viewable by everyone" ON pg_profiles 
    FOR SELECT USING (is_approved = true AND is_active = true);
CREATE POLICY "Owners view own PG profiles" ON pg_profiles 
    FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "Owners insert own PG profile" ON pg_profiles 
    FOR INSERT WITH CHECK (
        owner_id = auth.uid() AND 
        is_approved = false AND
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'pg_owner'
        )
    );
CREATE POLICY "Owners update own PG profile" ON pg_profiles 
    FOR UPDATE USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid() AND is_approved = OLD.is_approved);
CREATE POLICY "Owners delete own PG profile" ON pg_profiles 
    FOR DELETE USING (owner_id = auth.uid());
CREATE POLICY "Admins manage all PG profiles" ON pg_profiles 
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Food Listings: Customers view active approved, Owners manage own, Admins manage all
CREATE POLICY "Customers view active approved listings" ON food_listings
    FOR SELECT USING (
        status != 'removed' AND
        pg_id IN (
            SELECT id FROM pg_profiles WHERE is_approved = true AND is_active = true
        )
    );
CREATE POLICY "Owners view listings for their PGs" ON food_listings
    FOR SELECT USING (
        pg_id IN (SELECT id FROM pg_profiles WHERE owner_id = auth.uid())
    );
CREATE POLICY "Owners manage listings for their PGs" ON food_listings
    FOR ALL USING (
        pg_id IN (SELECT id FROM pg_profiles WHERE owner_id = auth.uid())
    ) WITH CHECK (
        pg_id IN (SELECT id FROM pg_profiles WHERE owner_id = auth.uid())
    );
CREATE POLICY "Admins manage all listings" ON food_listings
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Reservations: Customers view/create/cancel own, Owners view/update status for own listings, Admins manage all
CREATE POLICY "Customers view own reservations" ON reservations FOR SELECT USING (customer_id = auth.uid());
CREATE POLICY "Owners view reservations for their listings" ON reservations FOR SELECT USING (
    listing_id IN (
        SELECT fl.id FROM food_listings fl
        JOIN pg_profiles pg ON fl.pg_id = pg.id
        WHERE pg.owner_id = auth.uid()
    )
);
CREATE POLICY "Customers cancel own reservations" ON reservations
    FOR UPDATE USING (customer_id = auth.uid())
    WITH CHECK (
        customer_id = auth.uid() AND
        status = 'cancelled'::reservation_status AND
        OLD.status = 'confirmed'::reservation_status AND
        portions_count = OLD.portions_count AND
        listing_id = OLD.listing_id AND
        unit_price = OLD.unit_price AND
        total_amount = OLD.total_amount
    );
CREATE POLICY "Owners update status of reservations for their listings" ON reservations
    FOR UPDATE USING (
        listing_id IN (
            SELECT fl.id FROM food_listings fl
            JOIN pg_profiles pg ON fl.pg_id = pg.id
            WHERE pg.owner_id = auth.uid()
        )
    )
    WITH CHECK (
        customer_id = OLD.customer_id AND
        listing_id = OLD.listing_id AND
        portions_count = OLD.portions_count AND
        unit_price = OLD.unit_price AND
        total_amount = OLD.total_amount AND
        status IN ('ready_for_pickup'::reservation_status, 'picked_up'::reservation_status, 'no_show'::reservation_status, 'rejected'::reservation_status)
    );
CREATE POLICY "Admins manage all reservations" ON reservations
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- 9. Automatic Inventory Trigger on Reservation Cancellation
CREATE OR REPLACE FUNCTION restore_listing_portions_on_cancellation()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.status = 'confirmed' OR OLD.status = 'ready_for_pickup') AND NEW.status = 'cancelled' THEN
        UPDATE food_listings
        SET available_portions = least(available_portions + OLD.portions_count, total_portions),
            status = CASE WHEN status = 'sold_out' THEN 'active'::listing_status ELSE status END
        WHERE id = OLD.listing_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_restore_portions_on_cancel
AFTER UPDATE ON reservations
FOR EACH ROW
EXECUTE FUNCTION restore_listing_portions_on_cancellation();

-- 10. Profile Creation Trigger on Auth User Creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    input_role TEXT;
    final_role user_role;
BEGIN
    input_role := new.raw_user_meta_data->>'role';
    
    IF input_role = 'pg_owner' THEN
        final_role := 'pg_owner'::user_role;
    ELSE
        final_role := 'customer'::user_role;
    END IF;

    INSERT INTO public.profiles (id, email, full_name, phone_number, role)
    VALUES (
        new.id,
        new.email,
        coalesce(new.raw_user_meta_data->>'full_name', ''),
        coalesce(new.raw_user_meta_data->>'phone_number', ''),
        final_role
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

CREATE OR REPLACE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 11. Profile Role Update Protection Trigger
CREATE OR REPLACE FUNCTION public.check_profile_updates()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.role IS DISTINCT FROM NEW.role OR
       OLD.is_verified IS DISTINCT FROM NEW.is_verified OR
       OLD.is_suspended IS DISTINCT FROM NEW.is_suspended THEN
        
        IF NOT EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        ) THEN
            NEW.role := OLD.role;
            NEW.is_verified := OLD.is_verified;
            NEW.is_suspended := OLD.is_suspended;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

CREATE OR REPLACE TRIGGER before_profile_updated
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.check_profile_updates();

-- 12. Atomic Reservation RPC Function
CREATE OR REPLACE FUNCTION public.reserve_food(
    p_listing_id UUID,
    p_quantity INTEGER
)
RETURNS public.reservations AS $$
DECLARE
    v_listing public.food_listings;
    v_pg public.pg_profiles;
    v_reservation public.reservations;
    v_readable_id TEXT;
BEGIN
    -- Verify customer is authenticated
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Verify customer role
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'customer'
    ) THEN
        RAISE EXCEPTION 'Only customers can reserve food';
    END IF;

    -- Verify quantity
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be greater than zero';
    END IF;

    -- Lock food listing row and retrieve details
    SELECT * INTO v_listing
    FROM public.food_listings
    WHERE id = p_listing_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Food listing not found';
    END IF;

    -- Verify listing status
    IF v_listing.status != 'active' THEN
        RAISE EXCEPTION 'Food listing is not active';
    END IF;

    -- Verify pickup window
    IF now() > v_listing.pickup_end_time THEN
        RAISE EXCEPTION 'Pickup window has already closed';
    END IF;

    -- Verify PG profile status
    SELECT * INTO v_pg
    FROM public.pg_profiles
    WHERE id = v_listing.pg_id;

    IF NOT FOUND OR NOT v_pg.is_approved OR NOT v_pg.is_active THEN
        RAISE EXCEPTION 'Associated PG is not approved or active';
    END IF;

    -- Verify portion availability
    IF v_listing.available_portions < p_quantity THEN
        RAISE EXCEPTION 'Insufficient portions available';
    END IF;

    -- Generate readable reservation ID
    v_readable_id := 'EB-' || floor(random() * 90000 + 10000)::TEXT;
    WHILE EXISTS (SELECT 1 FROM public.reservations WHERE readable_id = v_readable_id) LOOP
        v_readable_id := 'EB-' || floor(random() * 90000 + 10000)::TEXT;
    END LOOP;

    -- Decrement available portions and update listing status if sold out
    UPDATE public.food_listings
    SET available_portions = available_portions - p_quantity,
        status = CASE WHEN available_portions - p_quantity = 0 THEN 'sold_out'::listing_status ELSE status END
    WHERE id = p_listing_id;

    -- Insert reservation
    INSERT INTO public.reservations (
        readable_id,
        listing_id,
        customer_id,
        portions_count,
        unit_price,
        total_amount,
        payment_method,
        status,
        pickup_token,
        qr_payload,
        pickup_deadline
    )
    VALUES (
        v_readable_id,
        p_listing_id,
        auth.uid(),
        p_quantity,
        v_listing.discounted_price,
        v_listing.discounted_price * p_quantity,
        'pay_at_pickup',
        'confirmed'::reservation_status,
        md5(random()::text),
        v_readable_id || '|' || md5(random()::text),
        v_listing.pickup_end_time
    )
    RETURNING * INTO v_reservation;

    RETURN v_reservation;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- 13. Enable Supabase Realtime for food_listings
ALTER PUBLICATION supabase_realtime ADD TABLE public.food_listings;
