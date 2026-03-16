-- Add payment tracking columns to matches
ALTER TABLE matches
  ADD COLUMN IF NOT EXISTS payment_instructions text,
  ADD COLUMN IF NOT EXISTS requester_paid_at timestamptz,
  ADD COLUMN IF NOT EXISTS owner_confirmed_at timestamptz;

-- Update match status check constraint to include new statuses
ALTER TABLE matches
  DROP CONSTRAINT IF EXISTS matches_status_check;

ALTER TABLE matches
  ADD CONSTRAINT matches_status_check
  CHECK (status IN ('pending','accepted','declined','active','completed'));
