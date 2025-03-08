-- Create question_statistics table
CREATE TABLE IF NOT EXISTS question_statistics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid REFERENCES questions ON DELETE CASCADE NOT NULL,
  times_shown integer DEFAULT 0,
  times_correct integer DEFAULT 0,
  times_incorrect integer DEFAULT 0,
  times_skipped integer DEFAULT 0,
  avg_time_spent integer DEFAULT 0, -- in seconds
  difficulty_rating float8 DEFAULT 0.5, -- 0 to 1 scale
  discrimination_index float8 DEFAULT 0.0, -- -1 to 1 scale
  point_biserial float8 DEFAULT 0.0, -- -1 to 1 scale
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(question_id)
);

-- Create question_response_times table
CREATE TABLE IF NOT EXISTS question_response_times (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid REFERENCES questions ON DELETE CASCADE NOT NULL,
  user_id uuid REFERENCES auth.users NOT NULL,
  test_id uuid REFERENCES test_sessions ON DELETE CASCADE NOT NULL,
  time_spent integer NOT NULL, -- in seconds
  created_at timestamptz DEFAULT now()
);

-- Create question_difficulty_history table
CREATE TABLE IF NOT EXISTS question_difficulty_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid REFERENCES questions ON DELETE CASCADE NOT NULL,
  difficulty_value float8 NOT NULL,
  confidence_interval float8 NOT NULL,
  sample_size integer NOT NULL,
  calculation_date timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- Create question_discrimination_history table
CREATE TABLE IF NOT EXISTS question_discrimination_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid REFERENCES questions ON DELETE CASCADE NOT NULL,
  discrimination_value float8 NOT NULL,
  confidence_interval float8 NOT NULL,
  sample_size integer NOT NULL,
  calculation_date timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE question_statistics ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_response_times ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_difficulty_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_discrimination_history ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE TRIGGER set_question_statistics_updated_at
  BEFORE UPDATE ON question_statistics
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Create RLS policies for question_statistics
CREATE POLICY "Enable read access for all users"
  ON question_statistics
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage statistics"
  ON question_statistics
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

-- Create RLS policies for question_response_times
CREATE POLICY "Users can view own response times"
  ON question_response_times
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own response times"
  ON question_response_times
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all response times"
  ON question_response_times
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

-- Create RLS policies for question_difficulty_history
CREATE POLICY "Enable read access for all users"
  ON question_difficulty_history
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage difficulty history"
  ON question_difficulty_history
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

-- Create RLS policies for question_discrimination_history
CREATE POLICY "Enable read access for all users"
  ON question_discrimination_history
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage discrimination history"
  ON question_discrimination_history
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
CREATE INDEX idx_question_statistics_question_id ON question_statistics(question_id);
CREATE INDEX idx_question_statistics_difficulty_rating ON question_statistics(difficulty_rating);
CREATE INDEX idx_question_statistics_discrimination_index ON question_statistics(discrimination_index);

CREATE INDEX idx_question_response_times_question_id ON question_response_times(question_id);
CREATE INDEX idx_question_response_times_user_id ON question_response_times(user_id);
CREATE INDEX idx_question_response_times_test_id ON question_response_times(test_id);

CREATE INDEX idx_question_difficulty_history_question_id ON question_difficulty_history(question_id);
CREATE INDEX idx_question_difficulty_history_calculation_date ON question_difficulty_history(calculation_date);

CREATE INDEX idx_question_discrimination_history_question_id ON question_discrimination_history(question_id);
CREATE INDEX idx_question_discrimination_history_calculation_date ON question_discrimination_history(calculation_date);

-- Create helper functions for statistics calculations
CREATE OR REPLACE FUNCTION calculate_question_statistics(question_id uuid)
RETURNS void AS $$
DECLARE
  total_responses integer;
  correct_responses integer;
  incorrect_responses integer;
  skipped_responses integer;
  total_time integer;
  avg_time integer;
  difficulty float8;
  discrimination float8;
BEGIN
  -- Get response counts
  SELECT 
    COUNT(*),
    COUNT(*) FILTER (WHERE is_correct = true),
    COUNT(*) FILTER (WHERE is_correct = false),
    0 -- Placeholder for skipped (implement actual logic based on your needs)
  INTO 
    total_responses,
    correct_responses,
    incorrect_responses,
    skipped_responses
  FROM test_answers
  WHERE test_answers.question_id = calculate_question_statistics.question_id::text;

  -- Calculate average time spent
  SELECT COALESCE(AVG(time_spent), 0)::integer
  INTO avg_time
  FROM question_response_times
  WHERE question_response_times.question_id = calculate_question_statistics.question_id;

  -- Calculate difficulty (p-value)
  difficulty := CASE 
    WHEN total_responses > 0 THEN 
      correct_responses::float8 / total_responses::float8
    ELSE 0.5 
  END;

  -- Update statistics
  INSERT INTO question_statistics (
    question_id,
    times_shown,
    times_correct,
    times_incorrect,
    times_skipped,
    avg_time_spent,
    difficulty_rating
  ) VALUES (
    calculate_question_statistics.question_id,
    total_responses,
    correct_responses,
    incorrect_responses,
    skipped_responses,
    avg_time,
    difficulty
  )
  ON CONFLICT (question_id) DO UPDATE SET
    times_shown = EXCLUDED.times_shown,
    times_correct = EXCLUDED.times_correct,
    times_incorrect = EXCLUDED.times_incorrect,
    times_skipped = EXCLUDED.times_skipped,
    avg_time_spent = EXCLUDED.avg_time_spent,
    difficulty_rating = EXCLUDED.difficulty_rating,
    updated_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get question performance metrics
CREATE OR REPLACE FUNCTION get_question_performance(question_id uuid)
RETURNS TABLE (
  total_attempts integer,
  correct_percentage float8,
  average_time_seconds integer,
  difficulty_rating float8,
  discrimination_index float8
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.times_shown as total_attempts,
    CASE 
      WHEN s.times_shown > 0 THEN 
        (s.times_correct::float8 / s.times_shown::float8) * 100
      ELSE 0 
    END as correct_percentage,
    s.avg_time_spent as average_time_seconds,
    s.difficulty_rating,
    s.discrimination_index
  FROM question_statistics s
  WHERE s.question_id = get_question_performance.question_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;