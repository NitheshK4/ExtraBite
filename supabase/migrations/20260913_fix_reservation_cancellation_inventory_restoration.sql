-- Migration: Fix Reservation Cancellation Food Quantity Restoration
-- Date: 2026-09-13
-- Description:
-- 1. Updates trigger function restore_listing_portions_on_cancellation to run with SECURITY DEFINER
--    and search_path = public, pg_temp, with FOR UPDATE row locking on food_listings.
-- 2. Creates atomic cancel_reservation RPC function with authorization, row locking, and idempotency.

-- 1. Update the inventory restoration trigger function on reservation cancellation
CREATE OR REPLACE FUNCTION public.restore_listing_portions_on_cancellation()
RETURNS TRIGGER AS $$
DECLARE
    v_listing public.food_listings;
BEGIN
    -- Only restore inventory if transitioning from an active holding state (confirmed or ready_for_pickup) to cancelled
    IF (OLD.status IN ('confirmed', 'ready_for_pickup')) AND NEW.status = 'cancelled' THEN
        -- Lock food listing row and retrieve current portions
        SELECT * INTO v_listing
        FROM public.food_listings
        WHERE id = OLD.listing_id
        FOR UPDATE;

        IF FOUND THEN
            -- Safely restore portions bounded by total_portions
            UPDATE public.food_listings
            SET available_portions = LEAST(available_portions + OLD.portions_count, total_portions),
                status = CASE 
                    WHEN status = 'sold_out' AND pickup_end_time > now() THEN 'active'::listing_status 
                    ELSE status 
                END,
                updated_at = now()
            WHERE id = OLD.listing_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- Ensure the trigger exists on reservations table
DROP TRIGGER IF EXISTS trigger_restore_portions_on_cancel ON public.reservations;
CREATE TRIGGER trigger_restore_portions_on_cancel
AFTER UPDATE ON public.reservations
FOR EACH ROW
EXECUTE FUNCTION public.restore_listing_portions_on_cancellation();

-- 2. Atomic cancel_reservation RPC
CREATE OR REPLACE FUNCTION public.cancel_reservation(
    p_reservation_id TEXT,
    p_reason TEXT DEFAULT 'Cancelled by customer'
)
RETURNS public.reservations AS $$
DECLARE
    v_res public.reservations;
    v_is_owner BOOLEAN;
    v_is_admin BOOLEAN;
BEGIN
    -- 1. Verify authentication
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- 2. Find and lock the reservation by UUID id or readable_id (e.g., EB-84920)
    SELECT * INTO v_res
    FROM public.reservations
    WHERE (id::TEXT = p_reservation_id OR readable_id = p_reservation_id)
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Reservation not found';
    END IF;

    -- 3. Authorization check: Caller must be the customer, the listing's PG owner, or an admin
    SELECT EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    ) INTO v_is_admin;

    SELECT EXISTS (
        SELECT 1 FROM public.food_listings fl
        JOIN public.pg_profiles pg ON fl.pg_id = pg.id
        WHERE fl.id = v_res.listing_id AND pg.owner_id = auth.uid()
    ) INTO v_is_owner;

    IF v_res.customer_id != auth.uid() AND NOT v_is_owner AND NOT v_is_admin THEN
        RAISE EXCEPTION 'Not authorized to cancel this reservation';
    END IF;

    -- 4. Idempotency: If already cancelled, return existing reservation record without re-restoring inventory
    IF v_res.status = 'cancelled' THEN
        RETURN v_res;
    END IF;

    -- 5. Only active/holding reservations can be cancelled
    IF v_res.status NOT IN ('confirmed', 'ready_for_pickup') THEN
        RAISE EXCEPTION 'Cannot cancel reservation in % status', v_res.status;
    END IF;

    -- 6. Update reservation status to cancelled
    -- (The trigger trigger_restore_portions_on_cancel executes within this atomic transaction to restore inventory)
    UPDATE public.reservations
    SET status = 'cancelled'::reservation_status,
        cancellation_reason = COALESCE(p_reason, cancellation_reason, 'Cancelled by user'),
        updated_at = now()
    WHERE id = v_res.id
    RETURNING * INTO v_res;

    RETURN v_res;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;
