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

-- Create updated_at triggers
CREATE TRIGGER set_client_needs_areas_updated_at
  BEFORE UPDATE ON client_needs_areas
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_client_needs_topics_updated_at
  BEFORE UPDATE ON client_needs_topics
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

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
CREATE INDEX idx_client_needs_areas_order_index ON client_needs_areas(order_index);
CREATE INDEX idx_client_needs_areas_is_active ON client_needs_areas(is_active);
CREATE INDEX idx_client_needs_topics_area_id ON client_needs_topics(area_id);
CREATE INDEX idx_client_needs_topics_order_index ON client_needs_topics(order_index);
CREATE INDEX idx_client_needs_topics_is_active ON client_needs_topics(is_active);

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

-- Migrate data from old tables if they exist
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'question_categories') THEN
    INSERT INTO client_needs_areas (id, name, description, order_index, is_active, created_at, updated_at)
    SELECT id, name, description, order_index, is_active, created_at, updated_at
    FROM question_categories
    ON CONFLICT (name) DO NOTHING;
    
    INSERT INTO client_needs_topics (id, area_id, name, description, order_index, is_active, created_at, updated_at)
    SELECT id, category_id, name, description, order_index, is_active, created_at, updated_at
    FROM question_topics
    ON CONFLICT (area_id, name) DO NOTHING;
  END IF;
END $$;