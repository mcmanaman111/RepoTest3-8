-- Create tables for client needs structure
CREATE TABLE IF NOT EXISTS client_needs_areas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  description text,
  order_index integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS client_needs_topics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  area_id uuid REFERENCES client_needs_areas(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  description text,
  order_index integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(area_id, name)
);

-- Enable RLS
ALTER TABLE client_needs_areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_needs_topics ENABLE ROW LEVEL SECURITY;

-- Create updated_at triggers only if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'set_client_needs_areas_updated_at'
  ) THEN
    CREATE TRIGGER set_client_needs_areas_updated_at
      BEFORE UPDATE ON client_needs_areas
      FOR EACH ROW
      EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'set_client_needs_topics_updated_at'
  ) THEN
    CREATE TRIGGER set_client_needs_topics_updated_at
      BEFORE UPDATE ON client_needs_topics
      FOR EACH ROW
      EXECUTE FUNCTION set_updated_at();
  END IF;
END $$;

-- Drop existing policies if they exist
DO $$ 
BEGIN
  -- Drop policies for client_needs_areas
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'client_needs_areas' AND policyname = 'Enable read access for active areas'
  ) THEN
    DROP POLICY "Enable read access for active areas" ON client_needs_areas;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'client_needs_areas' AND policyname = 'Admins can manage areas'
  ) THEN
    DROP POLICY "Admins can manage areas" ON client_needs_areas;
  END IF;

  -- Drop policies for client_needs_topics
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'client_needs_topics' AND policyname = 'Enable read access for active topics'
  ) THEN
    DROP POLICY "Enable read access for active topics" ON client_needs_topics;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'client_needs_topics' AND policyname = 'Admins can manage topics'
  ) THEN
    DROP POLICY "Admins can manage topics" ON client_needs_topics;
  END IF;
END $$;

-- Create RLS policies for client_needs_areas
CREATE POLICY "Enable read access for active areas"
  ON client_needs_areas
  FOR SELECT
  TO authenticated
  USING (is_active = true OR EXISTS (
    SELECT 1 FROM users_profiles
    WHERE users_profiles.id = auth.uid()
    AND users_profiles.user_type = 'administrator'
  ));

CREATE POLICY "Admins can manage areas"
  ON client_needs_areas
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

-- Create RLS policies for client_needs_topics
CREATE POLICY "Enable read access for active topics"
  ON client_needs_topics
  FOR SELECT
  TO authenticated
  USING (is_active = true OR EXISTS (
    SELECT 1 FROM users_profiles
    WHERE users_profiles.id = auth.uid()
    AND users_profiles.user_type = 'administrator'
  ));

CREATE POLICY "Admins can manage topics"
  ON client_needs_topics
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_client_needs_areas_order_index ON client_needs_areas(order_index);
CREATE INDEX IF NOT EXISTS idx_client_needs_areas_is_active ON client_needs_areas(is_active);
CREATE INDEX IF NOT EXISTS idx_client_needs_topics_area_id ON client_needs_topics(area_id);
CREATE INDEX IF NOT EXISTS idx_client_needs_topics_order_index ON client_needs_topics(order_index);
CREATE INDEX IF NOT EXISTS idx_client_needs_topics_is_active ON client_needs_topics(is_active);

-- Create helper function for getting topics by area
CREATE OR REPLACE FUNCTION get_client_needs_topics(area_name text)
RETURNS TABLE (
  topic_id uuid,
  topic_name text,
  description text
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.id,
    t.name,
    t.description
  FROM client_needs_topics t
  JOIN client_needs_areas a ON t.area_id = a.id
  WHERE a.name = area_name
  AND t.is_active = true
  AND a.is_active = true
  ORDER BY t.order_index;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;