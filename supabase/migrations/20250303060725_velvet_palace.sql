-- Create cat_sessions table
CREATE TABLE IF NOT EXISTS cat_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  start_time timestamptz DEFAULT now(),
  end_time timestamptz,
  initial_ability float8 DEFAULT 0,
  final_ability float8,
  confidence_interval float8,
  status text NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'terminated')),
  settings jsonb DEFAULT '{
    "min_questions": 75,
    "max_questions": 145,
    "time_limit": 300,
    "confidence_threshold": 0.95,
    "ability_threshold": 0.5
  }'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create cat_responses table
CREATE TABLE IF NOT EXISTS cat_responses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid REFERENCES cat_sessions ON DELETE CASCADE NOT NULL,
  question_id uuid REFERENCES questions ON DELETE CASCADE NOT NULL,
  response jsonb NOT NULL,
  is_correct boolean NOT NULL,
  time_spent integer NOT NULL, -- in seconds
  ability_estimate float8 NOT NULL,
  standard_error float8 NOT NULL,
  item_difficulty float8 NOT NULL,
  item_discrimination float8 NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create cat_ability_history table
CREATE TABLE IF NOT EXISTS cat_ability_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid REFERENCES cat_sessions ON DELETE CASCADE NOT NULL,
  ability_estimate float8 NOT NULL,
  standard_error float8 NOT NULL,
  question_number integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create user_ability table
CREATE TABLE IF NOT EXISTS user_ability (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  area_id uuid REFERENCES client_needs_areas ON DELETE CASCADE,
  topic_id uuid REFERENCES client_needs_topics ON DELETE CASCADE,
  ability_estimate float8 NOT NULL DEFAULT 0,
  confidence_interval float8 NOT NULL DEFAULT 1,
  sample_size integer NOT NULL DEFAULT 0,
  last_updated timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, area_id, topic_id)
);

-- Enable RLS
ALTER TABLE cat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE cat_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE cat_ability_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_ability ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE TRIGGER set_cat_sessions_updated_at
  BEFORE UPDATE ON cat_sessions
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Create RLS policies for cat_sessions
CREATE POLICY "Users can view their own CAT sessions"
  ON cat_sessions
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own CAT sessions"
  ON cat_sessions
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own CAT sessions"
  ON cat_sessions
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create RLS policies for cat_responses
CREATE POLICY "Users can view their own CAT responses"
  ON cat_responses
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM cat_sessions
      WHERE cat_sessions.id = cat_responses.session_id
      AND cat_sessions.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert their own CAT responses"
  ON cat_responses
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM cat_sessions
      WHERE cat_sessions.id = cat_responses.session_id
      AND cat_sessions.user_id = auth.uid()
    )
  );

-- Create RLS policies for cat_ability_history
CREATE POLICY "Users can view their own ability history"
  ON cat_ability_history
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM cat_sessions
      WHERE cat_sessions.id = cat_ability_history.session_id
      AND cat_sessions.user_id = auth.uid()
    )
  );

-- Create RLS policies for user_ability
CREATE POLICY "Users can view their own ability estimates"
  ON user_ability
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own ability estimates"
  ON user_ability
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all ability estimates"
  ON user_ability
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

-- Create indexes
CREATE INDEX idx_cat_sessions_user_id ON cat_sessions(user_id);
CREATE INDEX idx_cat_sessions_status ON cat_sessions(status);
CREATE INDEX idx_cat_responses_session_id ON cat_responses(session_id);
CREATE INDEX idx_cat_responses_question_id ON cat_responses(question_id);
CREATE INDEX idx_cat_ability_history_session_id ON cat_ability_history(session_id);
CREATE INDEX idx_user_ability_user_id ON user_ability(user_id);
CREATE INDEX idx_user_ability_area_id ON user_ability(area_id);
CREATE INDEX idx_user_ability_topic_id ON user_ability(topic_id);

-- Create helper functions for CAT
CREATE OR REPLACE FUNCTION get_next_cat_question(
  session_id uuid,
  current_ability float8,
  target_difficulty float8 DEFAULT NULL
)
RETURNS TABLE (
  question_id uuid,
  difficulty float8,
  discrimination float8
) AS $$
BEGIN
  -- If no target difficulty provided, use current ability estimate
  IF target_difficulty IS NULL THEN
    target_difficulty := current_ability;
  END IF;

  RETURN QUERY
  SELECT 
    q.id,
    qs.difficulty_rating as difficulty,
    qs.discrimination_index as discrimination
  FROM questions q
  JOIN question_statistics qs ON q.id = qs.question_id
  WHERE NOT EXISTS (
    -- Exclude questions already answered in this session
    SELECT 1 FROM cat_responses cr
    WHERE cr.session_id = get_next_cat_question.session_id
    AND cr.question_id = q.id
  )
  -- Find questions closest to target difficulty
  ORDER BY ABS(qs.difficulty_rating - target_difficulty) ASC,
    -- Prefer questions with higher discrimination for more precise measurement
    qs.discrimination_index DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to update ability estimate
CREATE OR REPLACE FUNCTION update_ability_estimate(
  session_id uuid,
  new_response_correct boolean,
  question_difficulty float8,
  question_discrimination float8
)
RETURNS TABLE (
  new_ability float8,
  new_error float8
) AS $$
DECLARE
  current_ability float8;
  current_error float8;
  information float8;
  score float8;
BEGIN
  -- Get current ability estimate
  SELECT 
    COALESCE(ability_estimate, 0),
    COALESCE(standard_error, 1)
  INTO current_ability, current_error
  FROM cat_ability_history
  WHERE session_id = update_ability_estimate.session_id
  ORDER BY created_at DESC
  LIMIT 1;

  -- Convert boolean response to numeric score (0 or 1)
  score := CASE WHEN new_response_correct THEN 1.0 ELSE 0.0 END;

  -- Calculate information (based on 2PL IRT model)
  information := question_discrimination * question_discrimination * 0.25;

  -- Update ability estimate using EAP (Expected A Posteriori)
  new_ability := current_ability + (
    (score - 1.0 / (1.0 + exp(-1.7 * question_discrimination * (current_ability - question_difficulty))))
    / information
  );

  -- Update standard error
  new_error := sqrt(1.0 / (1.0 / (current_error * current_error) + information));

  RETURN QUERY
  SELECT new_ability, new_error;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;