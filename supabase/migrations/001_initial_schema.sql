-- ============================================================
-- ElliMate Supabase Database Migration
-- Production-Ready Schema, Hardened RLS, Race-Safe Bookings
-- ============================================================

-- ============================================================
-- 0. EXTENSIONS & PRIVATE SCHEMAS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- Private schema for internal security definer functions (avoids RLS recursion and public exposure)
CREATE SCHEMA IF NOT EXISTS app_security;

-- Restrict direct access to private security schema
REVOKE ALL ON SCHEMA app_security FROM PUBLIC;
REVOKE ALL ON SCHEMA app_security FROM anon;
GRANT USAGE ON SCHEMA app_security TO authenticated, service_role;

-- ============================================================
-- 1. IMMUTABLE HELPERS FOR CONSTRAINTS
-- ============================================================
-- Immutable function to construct a timestamp range from date + start/end time.
-- Used by the GiST exclusion constraint to prevent overlapping laundry slots.
CREATE OR REPLACE FUNCTION public.make_booking_tsrange(d DATE, s TIME, e TIME)
RETURNS tsrange
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
  SELECT tsrange((d + s), (d + e), '[)');
$$;

-- ============================================================
-- 2. TABLE DEFINITIONS (CREATED IN STRICT DEPENDENCY ORDER)
-- ============================================================

-- ------------------------------------------------------------
-- 2.1 PROFILES
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 2.2 APARTMENTS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.apartments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL CHECK (length(trim(name)) > 0),
  description TEXT,
  invite_code TEXT NOT NULL UNIQUE CHECK (length(trim(invite_code)) >= 4),
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 2.3 APARTMENT MEMBERS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.apartment_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  apartment_id UUID NOT NULL REFERENCES public.apartments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT apartment_members_user_unique UNIQUE (apartment_id, user_id)
);

-- ------------------------------------------------------------
-- 2.4 LAUNDRY BOOKINGS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.laundry_bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  apartment_id UUID NOT NULL REFERENCES public.apartments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  booking_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  status TEXT NOT NULL DEFAULT 'upcoming'
    CHECK (status IN ('upcoming', 'current', 'completed', 'cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT laundry_bookings_valid_duration CHECK (end_time > start_time)
);

-- ------------------------------------------------------------
-- 2.5 CHAT MESSAGES
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  apartment_id UUID NOT NULL REFERENCES public.apartments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  message TEXT NOT NULL CHECK (length(trim(message)) > 0 AND length(message) <= 5000),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- ------------------------------------------------------------
-- 2.6 APARTMENT UPDATES
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.apartment_updates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  apartment_id UUID NOT NULL REFERENCES public.apartments(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (length(trim(title)) > 0 AND length(title) <= 200),
  description TEXT NOT NULL CHECK (length(trim(description)) > 0),
  category TEXT NOT NULL DEFAULT 'general'
    CHECK (category IN ('general','maintenance','cleaning','water','electricity','parcel','security','other')),
  scheduled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- ------------------------------------------------------------
-- 2.7 NOTIFICATION PREFERENCES
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  laundry_reminders BOOLEAN NOT NULL DEFAULT TRUE,
  chat_messages BOOLEAN NOT NULL DEFAULT TRUE,
  apartment_updates BOOLEAN NOT NULL DEFAULT TRUE,
  booking_confirmations BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 2.8 DEVICE TOKENS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL CHECK (length(trim(token)) > 0),
  platform TEXT NOT NULL DEFAULT 'android' CHECK (platform IN ('android', 'ios', 'web')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT device_tokens_user_token_unique UNIQUE (user_id, token)
);

-- ------------------------------------------------------------
-- 2.9 NOTIFICATIONS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('chat', 'laundry', 'update', 'system', 'general')),
  title TEXT NOT NULL CHECK (length(trim(title)) > 0),
  message TEXT NOT NULL CHECK (length(trim(message)) > 0),
  data JSONB,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 3. INDEXES & CONSTRAINTS
-- ============================================================

-- Apartments indexes
CREATE UNIQUE INDEX IF NOT EXISTS apartments_invite_code_idx ON public.apartments(invite_code);
CREATE INDEX IF NOT EXISTS apartments_created_by_idx ON public.apartments(created_by);

-- Apartment members indexes (membership lookup)
CREATE INDEX IF NOT EXISTS apartment_members_user_id_idx ON public.apartment_members(user_id);

-- Laundry bookings: Exclusion constraint preventing overlapping active bookings
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'laundry_bookings_no_overlap'
  ) THEN
    ALTER TABLE public.laundry_bookings
      ADD CONSTRAINT laundry_bookings_no_overlap
      EXCLUDE USING gist (
        apartment_id WITH =,
        public.make_booking_tsrange(booking_date, start_time, end_time) WITH &&
      )
      WHERE (status != 'cancelled');
  END IF;
END $$;

-- Laundry bookings query indexes
CREATE INDEX IF NOT EXISTS laundry_bookings_apt_date_status_idx
  ON public.laundry_bookings(apartment_id, booking_date, status);
CREATE INDEX IF NOT EXISTS laundry_bookings_user_idx
  ON public.laundry_bookings(user_id);

-- Chat messages index (ordered feed pagination)
CREATE INDEX IF NOT EXISTS chat_messages_apartment_created_idx
  ON public.chat_messages(apartment_id, created_at DESC);

-- Apartment updates index (ordered announcement feed)
CREATE INDEX IF NOT EXISTS apartment_updates_apartment_created_idx
  ON public.apartment_updates(apartment_id, created_at DESC);

-- Notifications indexes
CREATE INDEX IF NOT EXISTS notifications_user_created_idx
  ON public.notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS notifications_user_unread_idx
  ON public.notifications(user_id) WHERE (is_read = FALSE);

-- ============================================================
-- 4. NON-RECURSIVE RLS HELPER FUNCTIONS (IN app_security)
-- ============================================================

-- Check if current authenticated user belongs to an apartment
CREATE OR REPLACE FUNCTION app_security.is_apartment_member(p_apartment_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.apartment_members
    WHERE apartment_id = p_apartment_id
      AND user_id = (SELECT auth.uid())
  );
$$;

-- Check if current authenticated user is an admin of an apartment
CREATE OR REPLACE FUNCTION app_security.is_apartment_admin(p_apartment_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.apartment_members
    WHERE apartment_id = p_apartment_id
      AND user_id = (SELECT auth.uid())
      AND role = 'admin'
  );
$$;

-- Check if current authenticated user shares an apartment with target user
CREATE OR REPLACE FUNCTION app_security.shares_apartment_with(p_target_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.apartment_members m1
    JOIN public.apartment_members m2 ON m1.apartment_id = m2.apartment_id
    WHERE m1.user_id = (SELECT auth.uid())
      AND m2.user_id = p_target_user_id
  );
$$;

REVOKE ALL ON ALL FUNCTIONS IN SCHEMA app_security FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA app_security FROM anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA app_security TO authenticated, service_role;

-- ============================================================
-- 5. ROW LEVEL SECURITY POLICIES
-- ============================================================

-- ------------------------------------------------------------
-- 5.1 PROFILES POLICIES
-- ------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view self or shared apartment profiles" ON public.profiles;
CREATE POLICY "Users can view self or shared apartment profiles"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (
    (SELECT auth.uid()) = id
    OR app_security.shares_apartment_with(id)
  );

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = id)
  WITH CHECK ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = id);

-- ------------------------------------------------------------
-- 5.2 APARTMENTS POLICIES
-- (No USING(true) - invite codes & apartments are not leaked)
-- ------------------------------------------------------------
ALTER TABLE public.apartments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view their apartment" ON public.apartments;
CREATE POLICY "Members can view their apartment"
  ON public.apartments FOR SELECT
  TO authenticated
  USING (app_security.is_apartment_member(id));

DROP POLICY IF EXISTS "Admins can update their apartment" ON public.apartments;
CREATE POLICY "Admins can update their apartment"
  ON public.apartments FOR UPDATE
  TO authenticated
  USING (app_security.is_apartment_admin(id))
  WITH CHECK (app_security.is_apartment_admin(id));

-- ------------------------------------------------------------
-- 5.3 APARTMENT MEMBERS POLICIES & UPDATE TRIGGER
-- ------------------------------------------------------------
ALTER TABLE public.apartment_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view apartment membership" ON public.apartment_members;
CREATE POLICY "Members can view apartment membership"
  ON public.apartment_members FOR SELECT
  TO authenticated
  USING (
    user_id = (SELECT auth.uid())
    OR app_security.is_apartment_member(apartment_id)
  );

DROP POLICY IF EXISTS "Admins can add members directly" ON public.apartment_members;
CREATE POLICY "Admins can add members directly"
  ON public.apartment_members FOR INSERT
  TO authenticated
  WITH CHECK (app_security.is_apartment_admin(apartment_id));

DROP POLICY IF EXISTS "Admins can update member roles" ON public.apartment_members;
CREATE POLICY "Admins can update member roles"
  ON public.apartment_members FOR UPDATE
  TO authenticated
  USING (app_security.is_apartment_admin(apartment_id))
  WITH CHECK (app_security.is_apartment_admin(apartment_id));

DROP POLICY IF EXISTS "Members can leave or admins remove members" ON public.apartment_members;
CREATE POLICY "Members can leave or admins remove members"
  ON public.apartment_members FOR DELETE
  TO authenticated
  USING (
    user_id = (SELECT auth.uid())
    OR app_security.is_apartment_admin(apartment_id)
  );

-- Trigger to prevent admins from arbitrarily changing apartment_id or user_id during role update
CREATE OR REPLACE FUNCTION public.check_apartment_member_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF OLD.apartment_id != NEW.apartment_id OR OLD.user_id != NEW.user_id THEN
    RAISE EXCEPTION 'Cannot modify apartment_id or user_id of an existing membership.';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_apartment_member_update ON public.apartment_members;
CREATE TRIGGER trg_check_apartment_member_update
  BEFORE UPDATE ON public.apartment_members
  FOR EACH ROW
  EXECUTE FUNCTION public.check_apartment_member_update();

-- ------------------------------------------------------------
-- 5.4 LAUNDRY BOOKINGS POLICIES & UPDATE TRIGGER
-- ------------------------------------------------------------
ALTER TABLE public.laundry_bookings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view apartment laundry bookings" ON public.laundry_bookings;
CREATE POLICY "Members can view apartment laundry bookings"
  ON public.laundry_bookings FOR SELECT
  TO authenticated
  USING (app_security.is_apartment_member(apartment_id));

DROP POLICY IF EXISTS "Members can create own bookings" ON public.laundry_bookings;
CREATE POLICY "Members can create own bookings"
  ON public.laundry_bookings FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = (SELECT auth.uid())
    AND app_security.is_apartment_member(apartment_id)
  );

-- Users can only cancel their own active/upcoming bookings
DROP POLICY IF EXISTS "Users can cancel their own bookings" ON public.laundry_bookings;
CREATE POLICY "Users can cancel their own bookings"
  ON public.laundry_bookings FOR UPDATE
  TO authenticated
  USING (
    user_id = (SELECT auth.uid())
    AND status IN ('upcoming', 'current')
  )
  WITH CHECK (
    user_id = (SELECT auth.uid())
    AND status = 'cancelled'
  );

-- Trigger to prevent any modification to schedule/dates/apartment during cancellation
CREATE OR REPLACE FUNCTION public.check_laundry_booking_update()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.apartment_id != NEW.apartment_id OR
     OLD.user_id != NEW.user_id OR
     OLD.booking_date != NEW.booking_date OR
     OLD.start_time != NEW.start_time OR
     OLD.end_time != NEW.end_time THEN
    RAISE EXCEPTION 'Cannot modify booking schedule details. Cancel and rebook instead.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_laundry_booking_update ON public.laundry_bookings;
CREATE TRIGGER trg_check_laundry_booking_update
  BEFORE UPDATE ON public.laundry_bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.check_laundry_booking_update();

-- ------------------------------------------------------------
-- 5.5 CHAT MESSAGES POLICIES
-- ------------------------------------------------------------
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view apartment chat" ON public.chat_messages;
CREATE POLICY "Members can view apartment chat"
  ON public.chat_messages FOR SELECT
  TO authenticated
  USING (app_security.is_apartment_member(apartment_id));

DROP POLICY IF EXISTS "Members can send messages" ON public.chat_messages;
CREATE POLICY "Members can send messages"
  ON public.chat_messages FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = (SELECT auth.uid())
    AND app_security.is_apartment_member(apartment_id)
  );

DROP POLICY IF EXISTS "Users can delete own messages or admin can delete" ON public.chat_messages;
CREATE POLICY "Users can delete own messages or admin can delete"
  ON public.chat_messages FOR DELETE
  TO authenticated
  USING (
    user_id = (SELECT auth.uid())
    OR app_security.is_apartment_admin(apartment_id)
  );

-- ------------------------------------------------------------
-- 5.6 APARTMENT UPDATES POLICIES
-- ------------------------------------------------------------
ALTER TABLE public.apartment_updates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view apartment updates" ON public.apartment_updates;
CREATE POLICY "Members can view apartment updates"
  ON public.apartment_updates FOR SELECT
  TO authenticated
  USING (app_security.is_apartment_member(apartment_id));

DROP POLICY IF EXISTS "Admins can create updates" ON public.apartment_updates;
CREATE POLICY "Admins can create updates"
  ON public.apartment_updates FOR INSERT
  TO authenticated
  WITH CHECK (
    created_by = (SELECT auth.uid())
    AND app_security.is_apartment_admin(apartment_id)
  );

DROP POLICY IF EXISTS "Admins can update announcements" ON public.apartment_updates;
CREATE POLICY "Admins can update announcements"
  ON public.apartment_updates FOR UPDATE
  TO authenticated
  USING (app_security.is_apartment_admin(apartment_id))
  WITH CHECK (
    created_by = (SELECT auth.uid())
    AND app_security.is_apartment_admin(apartment_id)
  );

DROP POLICY IF EXISTS "Admins can delete updates" ON public.apartment_updates;
CREATE POLICY "Admins can delete updates"
  ON public.apartment_updates FOR DELETE
  TO authenticated
  USING (app_security.is_apartment_admin(apartment_id));

-- ------------------------------------------------------------
-- 5.7 NOTIFICATION PREFERENCES POLICIES
-- ------------------------------------------------------------
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own notification preferences" ON public.notification_preferences;
CREATE POLICY "Users can view own notification preferences"
  ON public.notification_preferences FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can insert own notification preferences" ON public.notification_preferences;
CREATE POLICY "Users can insert own notification preferences"
  ON public.notification_preferences FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can update own notification preferences" ON public.notification_preferences;
CREATE POLICY "Users can update own notification preferences"
  ON public.notification_preferences FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

-- ------------------------------------------------------------
-- 5.8 DEVICE TOKENS POLICIES
-- ------------------------------------------------------------
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own device tokens" ON public.device_tokens;
CREATE POLICY "Users can view own device tokens"
  ON public.device_tokens FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can insert own device tokens" ON public.device_tokens;
CREATE POLICY "Users can insert own device tokens"
  ON public.device_tokens FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can update own device tokens" ON public.device_tokens;
CREATE POLICY "Users can update own device tokens"
  ON public.device_tokens FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can delete own device tokens" ON public.device_tokens;
CREATE POLICY "Users can delete own device tokens"
  ON public.device_tokens FOR DELETE
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- ------------------------------------------------------------
-- 5.9 NOTIFICATIONS POLICIES
-- ------------------------------------------------------------
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications"
  ON public.notifications FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can delete own notifications" ON public.notifications;
CREATE POLICY "Users can delete own notifications"
  ON public.notifications FOR DELETE
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can insert own notifications" ON public.notifications;
CREATE POLICY "Users can insert own notifications"
  ON public.notifications FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

-- ============================================================
-- 6. TRIGGERS: AUTOMATIC SIGNUP PROFILES
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email)
  VALUES (
    NEW.id,
    COALESCE(NULLIF(trim(NEW.raw_user_meta_data->>'name'), ''), split_part(NEW.email, '@', 1)),
    COALESCE(NEW.email, '')
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.notification_preferences (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 7. SECURE RPC FUNCTIONS
-- ============================================================

-- ------------------------------------------------------------
-- 7.1 CREATE APARTMENT WITH ADMIN
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_apartment_with_admin(
  p_name TEXT,
  p_description TEXT,
  p_invite_code TEXT,
  p_user_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller_id UUID;
  v_apartment public.apartments;
  v_clean_name TEXT;
  v_clean_code TEXT;
BEGIN
  v_caller_id := (SELECT auth.uid());
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  -- Verify caller identity: client cannot create for another user
  IF p_user_id IS NOT NULL AND p_user_id != v_caller_id THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  v_clean_name := trim(p_name);
  IF v_clean_name IS NULL OR length(v_clean_name) = 0 THEN
    RAISE EXCEPTION 'invalid_apartment_name';
  END IF;

  v_clean_code := upper(trim(p_invite_code));
  IF v_clean_code IS NULL OR length(v_clean_code) < 4 THEN
    RAISE EXCEPTION 'invalid_invite_code';
  END IF;

  -- Ensure caller profile exists
  INSERT INTO public.profiles (id, name, email)
  VALUES (v_caller_id, 'Resident', '')
  ON CONFLICT (id) DO NOTHING;

  -- Create apartment
  INSERT INTO public.apartments (name, description, invite_code, created_by)
  VALUES (v_clean_name, trim(p_description), v_clean_code, v_caller_id)
  RETURNING * INTO v_apartment;

  -- Create admin membership
  INSERT INTO public.apartment_members (apartment_id, user_id, role)
  VALUES (v_apartment.id, v_caller_id, 'admin');

  RETURN row_to_json(v_apartment)::JSONB;
EXCEPTION WHEN unique_violation THEN
  RAISE EXCEPTION 'invite_code_conflict';
END;
$$;

-- ------------------------------------------------------------
-- 7.2 JOIN APARTMENT BY INVITE CODE
-- (Eliminates the insecure SELECT policy on apartments)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.join_apartment_by_code(
  p_invite_code TEXT,
  p_user_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller_id UUID;
  v_clean_code TEXT;
  v_apartment public.apartments;
BEGIN
  v_caller_id := (SELECT auth.uid());
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  IF p_user_id IS NOT NULL AND p_user_id != v_caller_id THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  v_clean_code := upper(trim(p_invite_code));
  IF v_clean_code IS NULL OR length(v_clean_code) = 0 THEN
    RAISE EXCEPTION 'invalid_invite_code';
  END IF;

  -- Find apartment by invite code
  SELECT * INTO v_apartment
  FROM public.apartments
  WHERE invite_code = v_clean_code;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_invite_code';
  END IF;

  -- Check if already a member
  IF EXISTS (
    SELECT 1 FROM public.apartment_members
    WHERE apartment_id = v_apartment.id
      AND user_id = v_caller_id
  ) THEN
    RAISE EXCEPTION 'already_member';
  END IF;

  -- Ensure profile exists
  INSERT INTO public.profiles (id, name, email)
  VALUES (v_caller_id, 'Resident', '')
  ON CONFLICT (id) DO NOTHING;

  -- Join as member
  INSERT INTO public.apartment_members (apartment_id, user_id, role)
  VALUES (v_apartment.id, v_caller_id, 'member');

  RETURN row_to_json(v_apartment)::JSONB;
END;
$$;

-- ------------------------------------------------------------
-- 7.3 ATOMIC & RACE-CONDITION SAFE LAUNDRY BOOKING
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.book_laundry_slot(
  p_apartment_id UUID,
  p_user_id UUID,
  p_booking_date DATE,
  p_start_time TIME,
  p_end_time TIME
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller_id UUID;
  v_booking public.laundry_bookings;
BEGIN
  v_caller_id := (SELECT auth.uid());
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  -- Cannot book on behalf of another user
  IF p_user_id != v_caller_id THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  -- Validate time range
  IF p_end_time <= p_start_time THEN
    RAISE EXCEPTION 'invalid_time_range';
  END IF;

  -- Validate date (cannot book past dates)
  IF p_booking_date < CURRENT_DATE THEN
    RAISE EXCEPTION 'invalid_booking_date';
  END IF;

  -- Verify membership in apartment
  IF NOT EXISTS (
    SELECT 1 FROM public.apartment_members
    WHERE apartment_id = p_apartment_id
      AND user_id = v_caller_id
  ) THEN
    RAISE EXCEPTION 'not_member';
  END IF;

  -- Insert booking; protected by GiST exclusion constraint against concurrent overlap
  INSERT INTO public.laundry_bookings
    (apartment_id, user_id, booking_date, start_time, end_time, status)
  VALUES
    (p_apartment_id, v_caller_id, p_booking_date, p_start_time, p_end_time, 'upcoming')
  RETURNING * INTO v_booking;

  RETURN row_to_json(v_booking)::JSONB;
EXCEPTION
  WHEN exclusion_violation THEN
    RAISE EXCEPTION 'slot_taken';
  WHEN unique_violation THEN
    RAISE EXCEPTION 'slot_taken';
END;
$$;

-- ------------------------------------------------------------
-- 7.4 CANCEL LAUNDRY BOOKING RPC
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cancel_laundry_booking(
  p_booking_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller_id UUID;
BEGIN
  v_caller_id := (SELECT auth.uid());
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  UPDATE public.laundry_bookings
  SET status = 'cancelled',
      updated_at = NOW()
  WHERE id = p_booking_id
    AND user_id = v_caller_id
    AND status IN ('upcoming', 'current');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'booking_not_found_or_cannot_cancel';
  END IF;
END;
$$;

-- ------------------------------------------------------------
-- 7.5 SECURE ACCOUNT DELETION (HISTORICAL DATA PRESERVED)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.delete_user_account(uid UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller_id UUID;
  v_apt RECORD;
  v_other_member_count INT;
  v_successor_id UUID;
BEGIN
  v_caller_id := (SELECT auth.uid());
  IF v_caller_id IS NULL OR v_caller_id != uid THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  -- Handle all apartments where user is an admin
  FOR v_apt IN
    SELECT am.apartment_id
    FROM public.apartment_members am
    WHERE am.user_id = v_caller_id AND am.role = 'admin'
  LOOP
    SELECT COUNT(*) INTO v_other_member_count
    FROM public.apartment_members
    WHERE apartment_id = v_apt.apartment_id
      AND user_id != v_caller_id;

    IF v_other_member_count > 0 THEN
      -- Promote the oldest member to admin
      SELECT user_id INTO v_successor_id
      FROM public.apartment_members
      WHERE apartment_id = v_apt.apartment_id
        AND user_id != v_caller_id
      ORDER BY joined_at ASC
      LIMIT 1;

      UPDATE public.apartment_members
      SET role = 'admin'
      WHERE apartment_id = v_apt.apartment_id
        AND user_id = v_successor_id;

      -- Transfer apartment created_by reference if applicable
      UPDATE public.apartments
      SET created_by = v_successor_id
      WHERE id = v_apt.apartment_id AND created_by = v_caller_id;
    ELSE
      -- No other members remain: cleanly remove empty apartment
      DELETE FROM public.apartments WHERE id = v_apt.apartment_id;
    END IF;
  END LOOP;

  -- Cancel all active/upcoming laundry slots so roommates can book them
  UPDATE public.laundry_bookings
  SET status = 'cancelled',
      updated_at = NOW()
  WHERE user_id = v_caller_id
    AND status = 'upcoming';

  -- Remove all apartment memberships
  DELETE FROM public.apartment_members WHERE user_id = v_caller_id;

  -- Clean up user personal data
  DELETE FROM public.device_tokens WHERE user_id = v_caller_id;
  DELETE FROM public.notification_preferences WHERE user_id = v_caller_id;
  DELETE FROM public.notifications WHERE user_id = v_caller_id;

  -- Anonymize profile to preserve historical integrity for roommates
  -- (chat messages, updates, and past laundry logs display 'Former Resident')
  UPDATE public.profiles
  SET name = 'Former Resident',
      email = '',
      avatar_url = NULL,
      updated_at = NOW()
  WHERE id = v_caller_id;

  -- Delete auth user (if executing with auth admin privileges or direct auth rights)
  BEGIN
    DELETE FROM auth.users WHERE id = v_caller_id;
  EXCEPTION WHEN OTHERS THEN
    -- If auth.users deletion is handled via Auth Admin API/Edge Function,
    -- data cleanup and profile anonymization are already complete.
    NULL;
  END;
END;
$$;

-- Restrict RPC permissions
REVOKE ALL ON FUNCTION public.create_apartment_with_admin(TEXT, TEXT, TEXT, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.join_apartment_by_code(TEXT, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.book_laundry_slot(UUID, UUID, DATE, TIME, TIME) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.cancel_laundry_booking(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_user_account(UUID) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.create_apartment_with_admin(TEXT, TEXT, TEXT, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.join_apartment_by_code(TEXT, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.book_laundry_slot(UUID, UUID, DATE, TIME, TIME) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.cancel_laundry_booking(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.delete_user_account(UUID) TO authenticated, service_role;

-- ============================================================
-- 8. REALTIME CONFIGURATION
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'chat_messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
  END IF;
END $$;

-- Set replica identity to FULL so realtime events contain all row data
ALTER TABLE public.chat_messages REPLICA IDENTITY FULL;

-- ============================================================
-- 9. STORAGE: PROFILE-IMAGES BUCKET & POLICIES
-- ============================================================
DO $$
BEGIN
  -- Check if storage schema exists (standard in Supabase)
  IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'storage') THEN

    -- Create bucket if not present
    INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    VALUES (
      'profile-images',
      'profile-images',
      true,
      5242880, -- 5 MB limit
      ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
    )
    ON CONFLICT (id) DO UPDATE SET public = true;

    -- Public read policy
    DROP POLICY IF EXISTS "Profile images are publicly viewable" ON storage.objects;
    CREATE POLICY "Profile images are publicly viewable"
      ON storage.objects FOR SELECT
      USING (bucket_id = 'profile-images');

    -- Restrict upload to own folder: /<user_id>/...
    DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
    CREATE POLICY "Users can upload own avatar"
      ON storage.objects FOR INSERT
      TO authenticated
      WITH CHECK (
        bucket_id = 'profile-images'
        AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
      );

    -- Restrict update to own avatar
    DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
    CREATE POLICY "Users can update own avatar"
      ON storage.objects FOR UPDATE
      TO authenticated
      USING (
        bucket_id = 'profile-images'
        AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
      )
      WITH CHECK (
        bucket_id = 'profile-images'
        AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
      );

    -- Restrict delete to own avatar
    DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;
    CREATE POLICY "Users can delete own avatar"
      ON storage.objects FOR DELETE
      TO authenticated
      USING (
        bucket_id = 'profile-images'
        AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
      );

  END IF;
END $$;
