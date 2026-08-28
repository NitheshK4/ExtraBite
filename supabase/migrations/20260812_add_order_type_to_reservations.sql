-- Migration: Add order_type to reservations table and update reserve_food RPC with server validation
-- Date: 2026-08-12

-- 1. Add order_type column to reservations with check constraint (nullable for legacy backward compatibility)
ALTER TABLE public.reservations 
ADD COLUMN IF NOT EXISTS order_type TEXT CHECK (order_type IN ('dine_in', 'take_away') OR order_type IS NULL);

-- 2. Update reserve_food stored function to validate and record order_type
CREATE OR REPLACE FUNCTION public.reserve_food(
    p_listing_id UUID,
    p_quantity INTEGER,
    p_order_type TEXT DEFAULT 'take_away'
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

    -- SERVER-SIDE VALIDATION: Validate order_type
    IF p_order_type IS NULL OR p_order_type NOT IN ('dine_in', 'take_away') THEN
        RAISE EXCEPTION 'Order type must be specified as dine_in or take_away';
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
        order_type,
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
        p_order_type,
        'confirmed'::reservation_status,
        md5(random()::text),
        v_readable_id || '|' || md5(random()::text),
        v_listing.pickup_end_time
    )
    RETURNING * INTO v_reservation;

    RETURN v_reservation;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;
