-- Storage buckets and Row Level Security policies for ChipIn
-- Creates: avatars, listing-images, id-documents buckets

-- ── Buckets ────────────────────────────────────────────────────────────────

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('avatars',        'avatars',        true,  5242880,   ARRAY['image/jpeg','image/png','image/webp']),
  ('listing-images', 'listing-images', true,  10485760,  ARRAY['image/jpeg','image/png','image/webp']),
  ('id-documents',   'id-documents',   false, 10485760,  ARRAY['image/jpeg','image/png','application/pdf'])
ON CONFLICT (id) DO NOTHING;

-- ── RLS Policies: avatars (public read, owner write) ──────────────────────

CREATE POLICY "Avatars are publicly readable"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can update their own avatar"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete their own avatar"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- ── RLS Policies: listing-images (public read, owner write) ───────────────

CREATE POLICY "Listing images are publicly readable"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'listing-images');

CREATE POLICY "Authenticated users can upload listing images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'listing-images' AND
    auth.role() = 'authenticated'
  );

CREATE POLICY "Users can update their own listing images"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'listing-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete their own listing images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'listing-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- ── RLS Policies: id-documents (private — owner + service role only) ──────

CREATE POLICY "Users can upload their own ID documents"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'id-documents' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can read their own ID documents"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'id-documents' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );
