-- ============================================================
-- ElliMate Security & RLS Policy Behavioral Test Suite
-- 002_security_rls_tests.sql
--
-- This test creates temporary test data and rolls everything
-- back automatically at the end.
-- ============================================================

BEGIN;

DO $$
DECLARE
  v_user_a UUID := gen_random_uuid();
  v_user_b UUID := gen_random_uuid();
  v_user_c UUID := gen_random_uuid();

  v_apt_1 UUID;
  v_booking_1 JSONB;

  v_booking_overlap_err BOOLEAN := FALSE;
  v_unauthorized_err BOOLEAN := FALSE;

  v_profile_count INT;
  v_chat_count INT;
  v_updates_count INT;
  v_count INT;
BEGIN

  RAISE NOTICE '==================================================';
  RAISE NOTICE 'STARTING ELLIMATE SECURITY & RLS TEST SUITE';
  RAISE NOTICE '==================================================';

  -- ==========================================================
  -- TEST SETUP
  -- ==========================================================

  INSERT INTO public.profiles (id, name, email)
  VALUES
    (v_user_a, 'Alice Admin', 'alice@test.com'),
    (v_user_b, 'Bob Roommate', 'bob@test.com'),
    (v_user_c, 'Charlie Outsider', 'charlie@test.com');

  -- ==========================================================
  -- TEST 1
  -- Apartment creation + automatic admin membership
  -- ==========================================================

  SET LOCAL ROLE authenticated;

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_user_a::TEXT,
      'role', 'authenticated',
      'aud', 'authenticated'
    )::TEXT,
    true
  );

  v_apt_1 := (
    public.create_apartment_with_admin(
      'Apartment 101',
      'Cozy flat',
      'APT101',
      v_user_a
    )->>'id'
  )::UUID;

  IF NOT EXISTS (
    SELECT 1
    FROM public.apartment_members
    WHERE apartment_id = v_apt_1
      AND user_id = v_user_a
      AND role = 'admin'
  ) THEN
    RAISE EXCEPTION
      'TEST 1 FAILED: Alice admin membership was not created.';
  END IF;

  RAISE NOTICE
    'PASS [TEST 1]: Apartment creation and admin membership verified.';

  -- ==========================================================
  -- TEST 2
  -- Apartment isolation
  -- Charlie must NOT see Alice's apartment
  -- ==========================================================

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_user_c::TEXT,
      'role', 'authenticated',
      'aud', 'authenticated'
    )::TEXT,
    true
  );

  SELECT COUNT(*)
  INTO v_count
  FROM public.apartments
  WHERE id = v_apt_1;

  IF v_count != 0 THEN
    RAISE EXCEPTION
      'TEST 2 FAILED: Outsider Charlie can see Apartment 101.';
  END IF;

  RAISE NOTICE
    'PASS [TEST 2]: Apartment isolation verified.';

  -- ==========================================================
  -- TEST 3
  -- Bob joins using apartment invite code
  -- ==========================================================

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_user_b::TEXT,
      'role', 'authenticated',
      'aud', 'authenticated'
    )::TEXT,
    true
  );

  PERFORM public.join_apartment_by_code(
    'APT101',
    v_user_b
  );

  IF NOT EXISTS (
    SELECT 1
    FROM public.apartment_members
    WHERE apartment_id = v_apt_1
      AND user_id = v_user_b
      AND role = 'member'
  ) THEN
    RAISE EXCEPTION
      'TEST 3 FAILED: Bob was not added as a member.';
  END IF;

  RAISE NOTICE
    'PASS [TEST 3]: Invite-code membership verified.';

  -- ==========================================================
  -- TEST 3B
  -- Duplicate membership must be blocked
  -- ==========================================================

  BEGIN

    PERFORM public.join_apartment_by_code(
      'APT101',
      v_user_b
    );

    RAISE EXCEPTION
      'TEST 3B FAILED: Duplicate membership was permitted.';

  EXCEPTION
    WHEN OTHERS THEN

      IF SQLERRM LIKE '%already_member%' THEN
        RAISE NOTICE
          'PASS [TEST 3B]: Duplicate membership blocked.';
      ELSE
        RAISE EXCEPTION
          'TEST 3B FAILED: Unexpected error: %',
          SQLERRM;
      END IF;

  END;

  -- ==========================================================
  -- TEST 4
  -- Profile isolation
  -- ==========================================================

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_user_a::TEXT,
      'role', 'authenticated',
      'aud', 'authenticated'
    )::TEXT,
    true
  );

  SELECT COUNT(*)
  INTO v_profile_count
  FROM public.profiles
  WHERE id = v_user_b;

  IF v_profile_count != 1 THEN
    RAISE EXCEPTION
      'TEST 4A FAILED: Alice cannot view Bob profile.';
  END IF;

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_user_c::TEXT,
      'role', 'authenticated',
      'aud', 'authenticated'
    )::TEXT,
    true
  );

  SELECT COUNT(*)
  INTO v_profile_count
  FROM public.profiles
  WHERE id = v_user_a;

  IF v_profile_count != 0 THEN
    RAISE EXCEPTION
      'TEST 4B FAILED: Charlie can view Alice profile.';
  END IF;

  RAISE NOTICE
    'PASS [TEST 4]: Profile isolation verified.';

  -- ==========================================================
  -- TEST 5
  -- Laundry overlap protection
  -- ==========================================================

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_user_a::TEXT,
      'role', 'authenticated',
      'aud', 'authenticated'
    )::TEXT,
    true
  );

  v_booking_1 := public.book_laundry_slot(
    v_apt_1,
    v_user_a,
    (CURRENT_DATE + 1),
    '10:00:00'::TIME,
    '11:00:00'::TIME
  );

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_user_b::TEXT,
      'role', 'authenticated',
      'aud', 'authenticated'
    )::TEXT,
    true
  );

  BEGIN

    PERFORM public.book_laundry_slot(
      v_apt_1,
      v_user_b,
      (CURRENT_DATE + 1),
      '10:30:00'::TIME,
      '11:30:00'::TIME
    );

  EXCEPTION
    WHEN OTHERS THEN

      IF SQLERRM LIKE '%slot_taken%' THEN
        v_booking_overlap_err := TRUE;
      END IF;

  END;

  IF NOT v_booking_overlap_err THEN
    RAISE EXCEPTION
      'TEST 5 FAILED: Overlapping laundry booking was permitted.';
  END IF;

  RAISE NOTICE
    'PASS [TEST 5]: Laundry overlap protection verified.';

  -- ==========================================================
  -- TEST 6
  -- Cancellation and rebooking
  -- ==========================================================

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_user_a::TEXT,
      'role', 'authenticated',
      'aud', 'authenticated'
    )::TEXT,
    true
  );

  PERFORM public.cancel_laundry_booking(
    (v_booking_1->>'id')::UUID
  );

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_user_b::TEXT,
      'role', 'authenticated',
      'aud', 'authenticated'
    )::TEXT,
    true
  );

  PERFORM public.book_laundry_slot(
    v_apt_1,
    v_user_b,
    (CURRENT_DATE + 1),
    '10:00:00'::TIME,
    '11:00:00'::TIME
  );

  RAISE NOTICE
    'PASS [TEST 6]: Cancelled laundry slot can be rebooked.';

  -- ==========================================================
  -- TEST 7
  -- Laundry booking tampering
  -- ==========================================================

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_user_b::TEXT,
      'role', 'authenticated',
      'aud', 'authenticated'
    )::TEXT,
    true
  );

  v_unauthorized_err := FALSE;

  BEGIN

    UPDATE public.laundry_bookings
    SET start_time = '08:00:00'
    WHERE user_id = v_user_b;

  EXCEPTION
    WHEN OTHERS THEN
      v_unauthorized_err := TRUE;

  END;

  IF NOT v_unauthorized_err THEN
    RAISE EXCEPTION
      'TEST 7 FAILED: Booking schedule tampering was permitted.';
  END IF;

  RAISE NOTICE
    'PASS [TEST 7]: Booking schedule tampering blocked.';

  -- ==========================================================
  -- TEST 8
  -- Chat isolation
  -- ==========================================================

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_user_b::TEXT,
      'role', 'authenticated',
      'aud', 'authenticated'
    )::TEXT,
    true
  );

  INSERT INTO public.chat_messages (
    apartment_id,
    user_id,
    message
  )
  VALUES (
    v_apt_1,
    v_user_b,
    'Hello roommates!'
  );

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_user_c::TEXT,
      'role', 'authenticated',
      'aud', 'authenticated'
    )::TEXT,
    true
  );

  SELECT COUNT(*)
  INTO v_chat_count
  FROM public.chat_messages
  WHERE apartment_id = v_apt_1;

  IF v_chat_count != 0 THEN
    RAISE EXCEPTION
      'TEST 8 FAILED: Charlie can read apartment chat messages.';
  END IF;

  RAISE NOTICE
    'PASS [TEST 8]: Chat isolation verified.';

  -- ==========================================================
  -- TEST 9
  -- Apartment updates: admin-only creation
  -- ==========================================================

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_user_b::TEXT,
      'role', 'authenticated',
      'aud', 'authenticated'
    )::TEXT,
    true
  );

  v_unauthorized_err := FALSE;

  BEGIN

    INSERT INTO public.apartment_updates (
      apartment_id,
      created_by,
      title,
      description,
      category
    )
    VALUES (
      v_apt_1,
      v_user_b,
      'Water outage',
      'Off at 2pm',
      'water'
    );

  EXCEPTION
    WHEN OTHERS THEN
      v_unauthorized_err := TRUE;

  END;

  IF NOT v_unauthorized_err THEN
    RAISE EXCEPTION
      'TEST 9 FAILED: Non-admin Bob posted an apartment update.';
  END IF;

  RAISE NOTICE
    'PASS [TEST 9]: Non-admin update creation blocked.';

  -- Admin Alice creates update

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_user_a::TEXT,
      'role', 'authenticated',
      'aud', 'authenticated'
    )::TEXT,
    true
  );

  INSERT INTO public.apartment_updates (
    apartment_id,
    created_by,
    title,
    description,
    category
  )
  VALUES (
    v_apt_1,
    v_user_a,
    'Maintenance',
    'Elevator serviced today',
    'maintenance'
  );

  -- Bob should be able to read the update

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_user_b::TEXT,
      'role', 'authenticated',
      'aud', 'authenticated'
    )::TEXT,
    true
  );

  SELECT COUNT(*)
  INTO v_updates_count
  FROM public.apartment_updates
  WHERE apartment_id = v_apt_1;

  IF v_updates_count != 1 THEN
    RAISE EXCEPTION
      'TEST 9B FAILED: Bob cannot view apartment update.';
  END IF;

  RAISE NOTICE
    'PASS [TEST 9B]: Apartment update visibility verified.';

  -- ==========================================================
  -- TEST 10
  -- Device token isolation
  -- ==========================================================

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_user_a::TEXT,
      'role', 'authenticated',
      'aud', 'authenticated'
    )::TEXT,
    true
  );

  INSERT INTO public.device_tokens (
    user_id,
    token,
    platform
  )
  VALUES (
    v_user_a,
    'token_alice_123',
    'android'
  );

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object(
      'sub', v_user_b::TEXT,
      'role', 'authenticated',
      'aud', 'authenticated'
    )::TEXT,
    true
  );

  SELECT COUNT(*)
  INTO v_count
  FROM public.device_tokens
  WHERE user_id = v_user_a;

  IF v_count != 0 THEN
    RAISE EXCEPTION
      'TEST 10 FAILED: Bob can read Alice device tokens.';
  END IF;

  RAISE NOTICE
    'PASS [TEST 10]: Device token isolation verified.';

  -- ==========================================================
  -- FINAL RESULT
  -- ==========================================================

  RAISE NOTICE '==================================================';
  RAISE NOTICE 'ALL 10 ELLIMATE SECURITY TESTS PASSED SUCCESSFULLY';
  RAISE NOTICE '==================================================';

END $$;

ROLLBACK;