-- Migration: Google user role selection
-- Adds role_finalized and is_owner_eligible, backfills data, updates handle_new_user, creates RPCs and protects columns

-- 1. Add new columns
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS role_finalized BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS is_owner_eligible BOOLEAN NOT NULL DEFAULT FALSE;

-- 2. Back-fill existing rows
UPDATE public.profiles
    SET role_finalized = TRUE,
        is_owner_eligible = FALSE;

-- 3. Update handle_new_user to set defaults for new Google users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles
        (id, email, full_name, phone_number, role, role_finalized, is_owner_eligible)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name',''),
        COALESCE(NEW.raw_user_meta_data->>'phone_number',''),
        'customer'::user_role,
        FALSE,
        FALSE
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- 4. RPC for a user to finalize their role
CREATE OR REPLACE FUNCTION public.set_user_role(p_role user_role)
RETURNS VOID AS $$
DECLARE
    v_profile public.profiles;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = auth.uid();
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Profile not found';
    END IF;

    IF v_profile.role_finalized THEN
        RAISE EXCEPTION 'Role already finalized';
    END IF;

    IF p_role = 'customer' THEN
        UPDATE public.profiles
        SET role = p_role,
            role_finalized = TRUE
        WHERE id = auth.uid();
    ELSIF p_role = 'pg_owner' THEN
        IF v_profile.is_owner_eligible THEN
            UPDATE public.profiles
            SET role = p_role,
                role_finalized = TRUE
            WHERE id = auth.uid();
        ELSE
            RAISE EXCEPTION 'User not eligible to become pg_owner';
        END IF;
    ELSE
        RAISE EXCEPTION 'Invalid role selection';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- 5. RPC for admin to set owner eligibility
CREATE OR REPLACE FUNCTION public.set_owner_eligibility(p_user_id UUID, p_eligible BOOLEAN)
RETURNS VOID AS $$
DECLARE
    v_caller public.profiles;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT * INTO v_caller FROM public.profiles WHERE id = auth.uid();
    IF NOT FOUND OR v_caller.role <> 'admin' THEN
        RAISE EXCEPTION 'Only admin can set owner eligibility';
    END IF;

    UPDATE public.profiles
    SET is_owner_eligible = p_eligible
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- 6. Updated trigger to protect role, role_finalized, is_owner_eligible, is_verified, is_suspended
CREATE OR REPLACE FUNCTION public.check_profile_updates()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.role IS DISTINCT FROM NEW.role
       OR OLD.role_finalized IS DISTINCT FROM NEW.role_finalized
       OR OLD.is_owner_eligible IS DISTINCT FROM NEW.is_owner_eligible
       OR OLD.is_verified IS DISTINCT FROM NEW.is_verified
       OR OLD.is_suspended IS DISTINCT FROM NEW.is_suspended THEN

        -- Allow legitimate role finalization via set_user_role()
        IF auth.uid() = NEW.id
           AND OLD.role_finalized = FALSE
           AND NEW.role_finalized = TRUE
           AND NEW.role IN ('customer','pg_owner') THEN
            RETURN NEW;
        END IF;

        -- Allow admin to modify any of these columns
        IF EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin') THEN
            RETURN NEW;
        END IF;

        -- Revert changes
        NEW.role := OLD.role;
        NEW.role_finalized := OLD.role_finalized;
        NEW.is_owner_eligible := OLD.is_owner_eligible;
        NEW.is_verified := OLD.is_verified;
        NEW.is_suspended := OLD.is_suspended;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS before_profile_updated ON public.profiles;
CREATE TRIGGER before_profile_updated
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.check_profile_updates();

-- 7. Revoke column-level UPDATE from normal authenticated users
REVOKE UPDATE (role, role_finalized, is_owner_eligible)
ON public.profiles
FROM authenticated;

-- 8. Grant EXECUTE on the new RPCs to authenticated role
GRANT EXECUTE ON FUNCTION public.set_user_role(user_role) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_owner_eligibility(uuid, boolean) TO authenticated;
