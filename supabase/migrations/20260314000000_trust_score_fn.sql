-- Creates an atomic trust score increment function used when a review is submitted.
-- Called from the client via supabase.rpc('increment_trust_score', ...)

CREATE OR REPLACE FUNCTION increment_trust_score(user_id uuid, points int)
RETURNS void AS $$
  UPDATE users
  SET trust_score = trust_score + points
  WHERE id = user_id;
$$ LANGUAGE sql SECURITY DEFINER;
