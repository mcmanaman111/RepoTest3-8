-- Create questions table
CREATE TABLE IF NOT EXISTS questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  text text NOT NULL,
  explanation jsonb NOT NULL DEFAULT '{"correct": [], "incorrect": []}'::jsonb,
  question_type text NOT NULL CHECK (
    question_type IN (
      'multiple_choice',
      'select_all',
      'ordered_response',
      'hot_spot',
      'fill_blank',
      'drag_drop',
      'chart_exhibit',
      'ngn_case_study'
    )
  ),
  difficulty text NOT NULL DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
  is_ngn boolean DEFAULT false,
  statistics jsonb NOT NULL DEFAULT '{
    "times_shown": 0,
    "times_correct": 0,
    "times_incorrect": 0,
    "times_skipped": 0,
    "avg_time_spent": 0,
    "avg_peer_score": "0%"
  }'::jsonb,
  created_by uuid REFERENCES auth.users,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create question_options table
CREATE TABLE IF NOT EXISTS question_options (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid REFERENCES questions ON DELETE CASCADE NOT NULL,
  text text NOT NULL,
  is_correct boolean NOT NULL DEFAULT false,
  explanation text,
  order_index integer NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create question_client_needs_mapping table
CREATE TABLE IF NOT EXISTS question_client_needs_mapping (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid REFERENCES questions ON DELETE CASCADE NOT NULL,
  area_id uuid REFERENCES client_needs_areas ON DELETE CASCADE NOT NULL,
  topic_id uuid REFERENCES client_needs_topics ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(question_id, area_id, topic_id)
);

-- Enable RLS
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_client_needs_mapping ENABLE ROW LEVEL SECURITY;

-- Create updated_at triggers
CREATE TRIGGER set_questions_updated_at
  BEFORE UPDATE ON questions
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_question_options_updated_at
  BEFORE UPDATE ON question_options
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Create RLS policies for questions
CREATE POLICY "Enable read access for all users"
  ON questions
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage questions"
  ON questions
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

-- Create RLS policies for question_options
CREATE POLICY "Enable read access for all users"
  ON question_options
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage question options"
  ON question_options
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

-- Create RLS policies for question_client_needs_mapping
CREATE POLICY "Enable read access for all users"
  ON question_client_needs_mapping
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage question mappings"
  ON question_client_needs_mapping
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
CREATE INDEX idx_questions_question_type ON questions(question_type);
CREATE INDEX idx_questions_difficulty ON questions(difficulty);
CREATE INDEX idx_questions_is_ngn ON questions(is_ngn);
CREATE INDEX idx_questions_created_by ON questions(created_by);
CREATE INDEX idx_question_options_question_id ON question_options(question_id);
CREATE INDEX idx_question_options_is_correct ON question_options(is_correct);
CREATE INDEX idx_question_client_needs_mapping_question_id ON question_client_needs_mapping(question_id);
CREATE INDEX idx_question_client_needs_mapping_area_id ON question_client_needs_mapping(area_id);
CREATE INDEX idx_question_client_needs_mapping_topic_id ON question_client_needs_mapping(topic_id);

-- Create helper functions
CREATE OR REPLACE FUNCTION get_question_client_needs(question_id uuid)
RETURNS TABLE (
  area_name text,
  topic_name text
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.name as area_name,
    t.name as topic_name
  FROM question_client_needs_mapping m
  JOIN client_needs_areas a ON m.area_id = a.id
  LEFT JOIN client_needs_topics t ON m.topic_id = t.id
  WHERE m.question_id = question_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get questions by client needs area
CREATE OR REPLACE FUNCTION get_questions_by_area(area_name text)
RETURNS TABLE (
  question_id uuid,
  question_text text,
  question_type text,
  difficulty text,
  is_ngn boolean
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    q.id,
    q.text,
    q.question_type,
    q.difficulty,
    q.is_ngn
  FROM questions q
  JOIN question_client_needs_mapping m ON q.id = m.question_id
  JOIN client_needs_areas a ON m.area_id = a.id
  WHERE a.name = area_name
  AND a.is_active = true
  ORDER BY q.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;