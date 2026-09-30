-- ============================================================
-- ElliMate Database Schema Verification & Security Test Checks
-- Run this in Supabase SQL editor after running 001_initial_schema.sql
-- ============================================================

DO $$
DECLARE
  v_missing_tables TEXT[] := ARRAY[]::TEXT[];
  v_missing_rls TEXT[] := ARRAY[]::TEXT[];
  v_missing_functions TEXT[] := ARRAY[]::TEXT[];
  v_missing_indexes TEXT[] := ARRAY[]::TEXT[];
  v_missing_constraints TEXT[] := ARRAY[]::TEXT[];
  v_table TEXT;
  v_func TEXT;
  v_idx TEXT;
  v_con TEXT;
  v_count INT;
BEGIN
  RAISE NOTICE '=== STARTING ELLIMATE SCHEMA VERIFICATION ===';

  -- 1. Check Tables Existence
  FOREACH v_table IN ARRAY ARRAY[
    'profiles',
    'apartments',
    'apartment_members',
    'laundry_bookings',
    'chat_messages',
    'apartment_updates',
    'notification_preferences',
    'device_tokens',
    'notifications'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = v_table
    ) THEN
      v_missing_tables := array_append(v_missing_tables, v_table);
    END IF;
  END LOOP;

  IF array_length(v_missing_tables, 1) > 0 THEN
    RAISE EXCEPTION 'FAILED: Missing tables: %', v_missing_tables;
  ELSE
    RAISE NOTICE 'PASS: All 9 required tables exist.';
  END IF;

  -- 2. Check Row Level Security (RLS) is ENABLED on every table
  FOREACH v_table IN ARRAY ARRAY[
    'profiles',
    'apartments',
    'apartment_members',
    'laundry_bookings',
    'chat_messages',
    'apartment_updates',
    'notification_preferences',
    'device_tokens',
    'notifications'
  ] LOOP
    SELECT COUNT(*) INTO v_count
    FROM pg_tables
    WHERE schemaname = 'public'
      AND tablename = v_table
      AND rowsecurity = TRUE;

    IF v_count = 0 THEN
      v_missing_rls := array_append(v_missing_rls, v_table);
    END IF;
  END LOOP;

  IF array_length(v_missing_rls, 1) > 0 THEN
    RAISE EXCEPTION 'FAILED: RLS not enabled on: %', v_missing_rls;
  ELSE
    RAISE NOTICE 'PASS: RLS is active on all 9 tables.';
  END IF;

  -- 3. Check Required Functions exist
  FOREACH v_func IN ARRAY ARRAY[
    'is_apartment_member',
    'is_apartment_admin',
    'shares_apartment_with'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
      WHERE n.nspname = 'app_security' AND p.proname = v_func
    ) THEN
      v_missing_functions := array_append(v_missing_functions, 'app_security.' || v_func);
    END IF;
  END LOOP;

  FOREACH v_func IN ARRAY ARRAY[
    'create_apartment_with_admin',
    'join_apartment_by_code',
    'book_laundry_slot',
    'cancel_laundry_booking',
    'delete_user_account',
    'make_booking_tsrange',
    'handle_new_user'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
      WHERE n.nspname = 'public' AND p.proname = v_func
    ) THEN
      v_missing_functions := array_append(v_missing_functions, 'public.' || v_func);
    END IF;
  END LOOP;

  IF array_length(v_missing_functions, 1) > 0 THEN
    RAISE EXCEPTION 'FAILED: Missing functions: %', v_missing_functions;
  ELSE
    RAISE NOTICE 'PASS: All security helper and RPC functions exist.';
  END IF;

  -- 4. Check Critical Constraints
  FOREACH v_con IN ARRAY ARRAY[
    'apartment_members_user_unique',
    'laundry_bookings_no_overlap',
    'laundry_bookings_valid_duration',
    'device_tokens_user_token_unique'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_constraint
      WHERE conname = v_con
    ) THEN
      v_missing_constraints := array_append(v_missing_constraints, v_con);
    END IF;
  END LOOP;

  IF array_length(v_missing_constraints, 1) > 0 THEN
    RAISE EXCEPTION 'FAILED: Missing constraints: %', v_missing_constraints;
  ELSE
    RAISE NOTICE 'PASS: Crucial exclusion and unique constraints verified.';
  END IF;

  -- 5. Check Required Query Indexes
  FOREACH v_idx IN ARRAY ARRAY[
    'apartments_invite_code_idx',
    'apartment_members_user_id_idx',
    'laundry_bookings_apt_date_status_idx',
    'chat_messages_apartment_created_idx',
    'apartment_updates_apartment_created_idx',
    'notifications_user_created_idx'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_indexes
      WHERE schemaname = 'public' AND indexname = v_idx
    ) THEN
      v_missing_indexes := array_append(v_missing_indexes, v_idx);
    END IF;
  END LOOP;

  IF array_length(v_missing_indexes, 1) > 0 THEN
    RAISE EXCEPTION 'FAILED: Missing indexes: %', v_missing_indexes;
  ELSE
    RAISE NOTICE 'PASS: All performance and lookup indexes exist.';
  END IF;

  -- 6. Check Realtime Configuration for chat_messages
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'chat_messages'
  ) THEN
    RAISE WARNING 'WARNING: chat_messages is not registered under supabase_realtime publication.';
  ELSE
    RAISE NOTICE 'PASS: Realtime enabled for chat_messages.';
  END IF;

  RAISE NOTICE '=== ALL SYSTEM DATABASE INTEGRITY CHECKS PASSED ===';
END $$;
