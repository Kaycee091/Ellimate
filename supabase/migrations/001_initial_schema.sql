-- ============================================================
-- ElliMate Supabase Database Migration
-- Run this in the Supabase SQL editor or via Supabase CLI
-- ============================================================

-- ============================================================
-- PROFILES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Allow apartment members to see each other's profiles
CREATE POLICY "Apartment members can view each other profiles"
  ON public.profiles FOR SELECT
  USING (
    id IN (
      SELECT user_id FROM public.apartment_members
      WHERE apartment_id IN (
        SELECT apartment_id FROM public.apartment_members
        WHERE user_id = auth.uid()
      )
    )
  );

-- ============================================================
-- APARTMENTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.apartments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  invite_code TEXT NOT NULL UNIQUE,
  created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS apartments_invite_code_idx ON public.apartments(invite_code);
CREATE INDEX IF NOT EXISTS apartments_created_by_idx ON public.apartments(created_by);

ALTER TABLE public.apartments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view their apartment"
  ON public.apartments FOR SELECT
  USING (
    id IN (
      SELECT apartment_id FROM public.apartment_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can update their apartment"
  ON public.apartments FOR UPDATE
  USING (
    id IN (
      SELECT apartment_id FROM public.apartment_members
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Anyone can look up apartment by invite code"
  ON public.apartments FOR SELECT
  USING (true);

-- ============================================================
-- APARTMENT MEMBERS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.apartment_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  apartment_id UUID NOT NULL REFERENCES public.apartments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(apartment_id, user_id)
);

CREATE INDEX IF NOT EXISTS apartment_members_user_id_idx ON public.apartment_members(user_id);
CREATE INDEX IF NOT EXISTS apartment_members_apartment_id_idx ON public.apartment_members(apartment_id);

ALTER TABLE public.apartment_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view apartment membership"
  ON public.apartment_members FOR SELECT
  USING (
    apartment_id IN (
      SELECT apartment_id FROM public.apartment_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can insert members"
  ON public.apartment_members FOR INSERT
  WITH CHECK (
    apartment_id IN (
      SELECT apartment_id FROM public.apartment_members
      WHERE user_id = auth.uid() AND role = 'admin'
    )
    OR user_id = auth.uid() -- allow self-join
  );

CREATE POLICY "Admins can delete members"
  ON public.apartment_members FOR DELETE
  USING (
    apartment_id IN (
      SELECT apartment_id FROM public.apartment_members
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================
-- LAUNDRY BOOKINGS TABLE
-- ============================================================
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
  -- Prevent double-booking the same slot
  UNIQUE(apartment_id, booking_date, start_time)
);

CREATE INDEX IF NOT EXISTS laundry_bookings_apartment_date_idx
  ON public.laundry_bookings(apartment_id, booking_date);
CREATE INDEX IF NOT EXISTS laundry_bookings_user_idx
  ON public.laundry_bookings(user_id);

ALTER TABLE public.laundry_bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view apartment laundry bookings"
  ON public.laundry_bookings FOR SELECT
  USING (
    apartment_id IN (
      SELECT apartment_id FROM public.apartment_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Members can create their own bookings"
  ON public.laundry_bookings FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND apartment_id IN (
      SELECT apartment_id FROM public.apartment_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can cancel their own bookings"
  ON public.laundry_bookings FOR UPDATE
  USING (user_id = auth.uid());

-- ============================================================
-- CHAT MESSAGES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  apartment_id UUID NOT NULL REFERENCES public.apartments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  message TEXT NOT NULL CHECK (length(trim(message)) > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS chat_messages_apartment_created_idx
  ON public.chat_messages(apartment_id, created_at DESC);

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view apartment chat"
  ON public.chat_messages FOR SELECT
  USING (
    apartment_id IN (
      SELECT apartment_id FROM public.apartment_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Members can send messages to their apartment"
  ON public.chat_messages FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND apartment_id IN (
      SELECT apartment_id FROM public.apartment_members
      WHERE user_id = auth.uid()
    )
  );

-- ============================================================
-- APARTMENT UPDATES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.apartment_updates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  apartment_id UUID NOT NULL REFERENCES public.apartments(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'general'
    CHECK (category IN ('general','maintenance','cleaning','water','electricity','parcel','security','other')),
  scheduled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS apartment_updates_apartment_idx
  ON public.apartment_updates(apartment_id, created_at DESC);

ALTER TABLE public.apartment_updates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view apartment updates"
  ON public.apartment_updates FOR SELECT
  USING (
    apartment_id IN (
      SELECT apartment_id FROM public.apartment_members
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can create updates"
  ON public.apartment_updates FOR INSERT
  WITH CHECK (
    created_by = auth.uid()
    AND apartment_id IN (
      SELECT apartment_id FROM public.apartment_members
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can delete updates"
  ON public.apartment_updates FOR DELETE
  USING (
    apartment_id IN (
      SELECT apartment_id FROM public.apartment_members
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================
-- NOTIFICATION PREFERENCES TABLE
-- ============================================================
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

ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own notification preferences"
  ON public.notification_preferences FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ============================================================
-- DEVICE TOKENS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL DEFAULT 'android',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, token)
);

CREATE INDEX IF NOT EXISTS device_tokens_user_idx ON public.device_tokens(user_id);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own device tokens"
  ON public.device_tokens FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ============================================================
-- NOTIFICATIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data JSONB,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS notifications_user_idx
  ON public.notifications(user_id, created_at DESC);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own notifications"
  ON public.notifications FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ============================================================
-- TRIGGER: Auto-create profile on user signup
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.email
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.notification_preferences (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- RPC: Atomic apartment creation with admin membership
-- ============================================================
CREATE OR REPLACE FUNCTION public.create_apartment_with_admin(
  p_name TEXT,
  p_description TEXT,
  p_invite_code TEXT,
  p_user_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_apartment public.apartments;
BEGIN
  -- Create apartment
  INSERT INTO public.apartments (name, description, invite_code, created_by)
  VALUES (p_name, p_description, p_invite_code, p_user_id)
  RETURNING * INTO v_apartment;

  -- Create admin membership
  INSERT INTO public.apartment_members (apartment_id, user_id, role)
  VALUES (v_apartment.id, p_user_id, 'admin');

  RETURN row_to_json(v_apartment)::JSONB;
EXCEPTION WHEN unique_violation THEN
  RAISE EXCEPTION 'invite_code_conflict';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- RPC: Safe laundry booking (prevents race conditions)
-- ============================================================
CREATE OR REPLACE FUNCTION public.book_laundry_slot(
  p_apartment_id UUID,
  p_user_id UUID,
  p_booking_date DATE,
  p_start_time TIME,
  p_end_time TIME
)
RETURNS JSONB AS $$
DECLARE
  v_booking public.laundry_bookings;
BEGIN
  -- Check membership
  IF NOT EXISTS (
    SELECT 1 FROM public.apartment_members
    WHERE apartment_id = p_apartment_id AND user_id = p_user_id
  ) THEN
    RAISE EXCEPTION 'not_member';
  END IF;

  -- Insert (unique constraint on apartment_id + booking_date + start_time prevents race)
  INSERT INTO public.laundry_bookings
    (apartment_id, user_id, booking_date, start_time, end_time, status)
  VALUES
    (p_apartment_id, p_user_id, p_booking_date, p_start_time, p_end_time, 'upcoming')
  RETURNING * INTO v_booking;

  RETURN row_to_json(v_booking)::JSONB;
EXCEPTION WHEN unique_violation THEN
  RAISE EXCEPTION 'slot_taken';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- RPC: Delete user account safely
-- ============================================================
CREATE OR REPLACE FUNCTION public.delete_user_account(uid UUID)
RETURNS VOID AS $$
BEGIN
  -- Verify the calling user is deleting their own account
  IF auth.uid() != uid THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  -- Remove profile (cascades to memberships, bookings, etc.)
  DELETE FROM public.profiles WHERE id = uid;

  -- Delete auth user
  DELETE FROM auth.users WHERE id = uid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- REALTIME: Enable for chat_messages
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;

-- ============================================================
-- STORAGE: Create profile-images bucket
-- (Run this separately in the Supabase dashboard Storage section
--  or via Supabase CLI if storage management is not available via SQL)
-- ============================================================
-- INSERT INTO storage.buckets (id, name, public) VALUES ('profile-images', 'profile-images', true)
-- ON CONFLICT DO NOTHING;

-- Storage policy (run after creating the bucket):
-- CREATE POLICY "Users can upload own avatar"
--   ON storage.objects FOR INSERT
--   WITH CHECK (bucket_id = 'profile-images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- CREATE POLICY "Profile images are publicly viewable"
--   ON storage.objects FOR SELECT
--   USING (bucket_id = 'profile-images');
