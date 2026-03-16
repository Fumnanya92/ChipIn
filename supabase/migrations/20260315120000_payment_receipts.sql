-- Add receipt_url to matches and create payment-receipts storage bucket

ALTER TABLE matches ADD COLUMN IF NOT EXISTS receipt_url text;

-- Payment receipts bucket (public read — both parties can view the uploaded proof)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'payment-receipts',
  'payment-receipts',
  true,
  10485760,
  ARRAY['image/jpeg','image/png','image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Only authenticated users can upload receipts
CREATE POLICY "Authenticated users can upload payment receipts"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'payment-receipts' AND
    auth.role() = 'authenticated'
  );

-- Public read (paths are match-ID based — hard to guess)
CREATE POLICY "Payment receipts are publicly readable"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'payment-receipts');

-- Owner can replace their own receipt
CREATE POLICY "Users can update their own payment receipts"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'payment-receipts' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );
