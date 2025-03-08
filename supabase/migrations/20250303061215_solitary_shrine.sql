-- Create user_ability_history table
CREATE TABLE IF NOT EXISTS user_ability_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  area_id uuid REFERENCES client_needs_areas ON DELETE CASCADE,
  topic_id uuid REFERENCES client_needs_topics ON DELETE CASCADE,
  ability_estimate float8 NOT NULL,
  confidence_interval float8 NOT NULL,
  sample_size integer NOT NULL,
  calculation_date timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- Create user_ability_metrics table
CREATE TABLE IF NOT EXISTS user_ability_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  area_id uuid REFERENCES client_needs_areas ON DELETE CASCADE,
  topic_id uuid REFERENCES client_needs_topics ON DELETE CASCADE,
  total_questions_attempted integer DEFAULT 0,
  correct_answers integer DEFAULT 0,
  average_time_per_question integer DEFAULT 0, -- in seconds
  mastery_level text DEFAULT 'beginner' CHECK (mastery_level IN ('beginner', 'intermediate', 'advanced', 'master')),
  last_activity_date timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, area_id, topic_id)
);

-- Enable RLS
ALTER TABLE user_ability_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_ability_metrics ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE TRIGGER set_user_ability_metrics_updated_at
  BEFORE UPDATE ON user_ability_metrics
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Create RLS policies for user_ability_history
CREATE POLICY "Users can view their own ability history"
  ON user_ability_history
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all ability history"
  ON user_ability_history
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

-- Create RLS policies for user_ability_metrics
CREATE POLICY "Users can view their own ability metrics"
  ON user_ability_metrics
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own ability metrics"
  ON user_ability_metrics
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all ability metrics"
  ON user_ability_metrics
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
CREATE INDEX idx_user_ability_history_user_id ON user_ability_history(user_id);
CREATE INDEX idx_user_ability_history_area_id ON user_ability_history(area_id);
CREATE INDEX idx_user_ability_history_topic_id ON user_ability_history(topic_id);
CREATE INDEX idx_user_ability_history_calculation_date ON user_ability_history(calculation_date);

CREATE INDEX idx_user_ability_metrics_user_id ON user_ability_metrics(user_id);
CREATE INDEX idx_user_ability_metrics_area_id ON user_ability_metrics(area_id);
CREATE INDEX idx_user_ability_metrics_topic_id ON user_ability_metrics(topic_id);
CREATE INDEX idx_user_ability_metrics_mastery_level ON user_ability_metrics(mastery_level);
CREATE INDEX idx_user_ability_metrics_last_activity ON user_ability_metrics(last_activity_date);

-- Create helper functions for ability tracking
CREATE OR REPLACE FUNCTION calculate_mastery_level(
  correct_percentage float8,
  questions_attempted integer,
  confidence_interval float8
)
RETURNS text AS $$
BEGIN
  -- Requires minimum number of questions for higher levels
  IF questions_attempted < 10 THEN
    RETURN 'beginner';
  ELSIF questions_attempted < 25 AND correct_percentage >= 70 THEN
    RETURN 'intermediate';
  ELSIF questions_attempted >= 25 AND correct_percentage >= 80 AND confidence_interval <= 0.15 THEN
    RETURN 'advanced';
  ELSIF questions_attempted >= 50 AND correct_percentage >= 90 AND confidence_interval <= 0.1 THEN
    RETURN 'master';
  ELSE
    RETURN 'beginner';
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create function to update user ability metrics
CREATE OR REPLACE FUNCTION update_user_ability_metrics(
  user_id uuid,
  area_id uuid,
  topic_id uuid,
  is_correct boolean,
  time_spent integer
)
RETURNS void AS $$
DECLARE
  current_metrics user_ability_metrics%ROWTYPE;
  new_correct_percentage float8;
  new_confidence_interval float8;
  new_mastery_level text;
BEGIN
  -- Get or create metrics record
  SELECT * INTO current_metrics
  FROM user_ability_metrics
  WHERE user_ability_metrics.user_id = update_user_ability_metrics.user_id
    AND user_ability_metrics.area_id = update_user_ability_metrics.area_id
    AND user_ability_metrics.topic_id = update_user_ability_metrics.topic_id;

  IF NOT FOUND THEN
    INSERT INTO user_ability_metrics (
      user_id, area_id, topic_id,
      total_questions_attempted, correct_answers,
      average_time_per_question, last_activity_date
    ) VALUES (
      update_user_ability_metrics.user_id,
      update_user_ability_metrics.area_id,
      update_user_ability_metrics.topic_id,
      1,
      CASE WHEN is_correct THEN 1 ELSE 0 END,
      time_spent,
      now()
    ) RETURNING * INTO current_metrics;
  ELSE
    -- Update existing metrics
    UPDATE user_ability_metrics
    SET
      total_questions_attempted = current_metrics.total_questions_attempted + 1,
      correct_answers = current_metrics.correct_answers + CASE WHEN is_correct THEN 1 ELSE 0 END,
      average_time_per_question = (
        (current_metrics.average_time_per_question * current_metrics.total_questions_attempted + time_spent) /
        (current_metrics.total_questions_attempted + 1)
      )::integer,
      last_activity_date = now()
    WHERE id = current_metrics.id
    RETURNING * INTO current_metrics;
  END IF;

  -- Calculate new metrics
  new_correct_percentage := (current_metrics.correct_answers::float8 / current_metrics.total_questions_attempted::float8) * 100;
  new_confidence_interval := 1.96 * sqrt(
    (new_correct_percentage * (100 - new_correct_percentage)) /
    current_metrics.total_questions_attempted
  ) / 100;

  -- Update mastery level
  new_mastery_level := calculate_mastery_level(
    new_correct_percentage,
    current_metrics.total_questions_attempted,
    new_confidence_interval
  );

  -- Update mastery level if changed
  IF new_mastery_level != current_metrics.mastery_level THEN
    UPDATE user_ability_metrics
    SET mastery_level = new_mastery_level
    WHERE id = current_metrics.id;
  END IF;

  -- Record ability history
  INSERT INTO user_ability_history (
    user_id,
    area_id,
    topic_id,
    ability_estimate,
    confidence_interval,
    sample_size
  ) VALUES (
    update_user_ability_metrics.user_id,
    update_user_ability_metrics.area_id,
    update_user_ability_metrics.topic_id,
    new_correct_percentage / 100,
    new_confidence_interval,
    current_metrics.total_questions_attempted
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get user ability summary
CREATE OR REPLACE FUNCTION get_user_ability_summary(user_id uuid)
RETURNS TABLE (
  area_name text,
  topic_name text,
  ability_estimate float8,
  confidence_interval float8,
  mastery_level text,
  total_questions integer,
  correct_answers integer,
  average_time integer
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.name as area_name,
    t.name as topic_name,
    (m.correct_answers::float8 / m.total_questions_attempted::float8) as ability_estimate,
    1.96 * sqrt(
      ((m.correct_answers::float8 / m.total_questions_attempted::float8) * 
      (1 - (m.correct_answers::float8 / m.total_questions_attempted::float8))) /
      m.total_questions_attempted
    ) as confidence_interval,
    m.mastery_level,
    m.total_questions_attempted as total_questions,
    m.correct_answers,
    m.average_time_per_question as average_time
  FROM user_ability_metrics m
  JOIN client_needs_areas a ON m.area_id = a.id
  LEFT JOIN client_needs_topics t ON m.topic_id = t.id
  WHERE m.user_id = get_user_ability_summary.user_id
  ORDER BY a.order_index, t.order_index NULLS FIRST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;