-- Migration: Fix PG Profiles Schema & Setup Food Images Storage Bucket
-- Date: 2026-09-13

-- =============================================================================
-- 1. pg_profiles Schema Alignment
-- =============================================================================

ALTER TABLE public.pg_profiles
    ADD COLUMN IF NOT EXISTS is_rejected BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS rejection_reason TEXT DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS image_url TEXT DEFAULT NULL;

-- Backfill any existing nulls if columns were previously added without defaults
UPDATE public.pg_profiles
SET is_rejected = FALSE
WHERE is_rejected IS NULL;

-- =============================================================================
-- 2. Storage Bucket Creation
-- =============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'food-images',
    'food-images',
    true,
    5242880, -- 5 MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO UPDATE SET 
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- =============================================================================
-- 3. Storage Security Policies for food-images
-- =============================================================================

DO $$
BEGIN
    -- Drop existing policies if present
    DROP POLICY IF EXISTS "Public Read Access for Food Images" ON storage.objects;
    DROP POLICY IF EXISTS "PG Owners Upload Food Images" ON storage.objects;
    DROP POLICY IF EXISTS "PG Owners Update Food Images" ON storage.objects;
    DROP POLICY IF EXISTS "PG Owners Delete Food Images" ON storage.objects;

    -- 3a. Public Read: Anyone can view food images
    CREATE POLICY "Public Read Access for Food Images"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'food-images');

    -- 3b. Authenticated Insert: Verified PG Owners & Admins
    CREATE POLICY "PG Owners Upload Food Images"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'food-images' AND
        auth.role() = 'authenticated' AND
        (storage.foldername(name))[1] = auth.uid()::text AND
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND (role = 'pg_owner' OR role = 'admin')
        )
    );

    -- 3c. Authenticated Update: Owners own folder
    CREATE POLICY "PG Owners Update Food Images"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'food-images' AND
        auth.role() = 'authenticated' AND
        (
            (storage.foldername(name))[1] = auth.uid()::text OR
            EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
        )
    );

    -- 3d. Authenticated Delete: Owners own folder
    CREATE POLICY "PG Owners Delete Food Images"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'food-images' AND
        auth.role() = 'authenticated' AND
        (
            (storage.foldername(name))[1] = auth.uid()::text OR
            EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
        )
    );
EXCEPTION
    WHEN insufficient_privilege THEN
        -- If running in an environment where storage.objects policies are managed via Dashboard
        RAISE NOTICE 'Skipping direct policy creation on storage.objects due to table ownership. Policies can be managed in Supabase Dashboard > Storage > Policies.';
END $$;
