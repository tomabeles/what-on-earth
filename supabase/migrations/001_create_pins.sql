-- Supabase pins table for cloud sync (TECH_SPEC §4.4, §9.3)
-- RLS restricts each user to their own data.

CREATE TABLE pins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  lat_deg float8 NOT NULL,
  lon_deg float8 NOT NULL,
  name text NOT NULL CHECK (char_length(name) <= 100),
  note text,
  icon_id smallint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE pins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own pins" ON pins
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX pins_user_updated ON pins(user_id, updated_at DESC);
