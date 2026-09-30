-- ============================================================
-- ElliMate Supabase Storage Configuration (002_storage_setup.sql)
-- Run this in the Supabase SQL editor to configure profile image storage
-- ============================================================

-- 1. Create the public profile-images bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-images',
  'profile-images',
  true,
  5242880, -- 5 MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Public Read Policy (Anyone can view avatars)
DROP POLICY IF EXISTS "Profile images are publicly viewable" ON storage.objects;
CREATE POLICY "Profile images are publicly viewable"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'profile-images');

-- 3. Authenticated Insert Policy (User can only upload into their own folder: /<user_id>/...)
DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
CREATE POLICY "Users can upload own avatar"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'profile-images'
    AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
  );

-- 4. Authenticated Update Policy (User can only update their own avatar)
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

-- 5. Authenticated Delete Policy (User can only delete their own avatar)
DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;
CREATE POLICY "Users can delete own avatar"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'profile-images'
    AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
  );
