-- Migration: Fix Customer RLS policy on food_listings
-- Date: 2026-08-12

DROP POLICY IF EXISTS "Customers view active approved listings" ON public.food_listings;

CREATE POLICY "Customers view active approved listings" ON public.food_listings
    FOR SELECT USING (
        status = 'active' AND
        available_portions > 0 AND
        pickup_end_time > NOW() AND
        pg_id IN (
            SELECT id FROM public.pg_profiles WHERE is_approved = true AND is_active = true
        )
    );
