/*
  # Add Test Session and Progress Tables
  
  1. New Tables
    - test_sessions: Tracks individual test attempts
    - test_answers: Records user answers for each question
    - test_results: Stores overall test results and analytics
    - study_progress: Tracks user's study progress by topic
    - user_preferences: Stores user settings and preferences
    
  2. Security
    - Enable RLS on all tables
    - Add policies for user data access
    
  3. Changes
    - Add indexes for performance optimization
    - Add triggers for updated_at timestamps
*/

-- Create updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create test session related tables
CREATE TABLE IF NOT EXISTS test_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  test_type text NOT NULL CHECK (test_type IN ('practice', 'quick', 'custom', 'cat')),
  start_time timestamptz DEFAULT now(),
  end_time timestamptz,
  total_questions integer NOT NULL,
  completed_questions integer DEFAULT 0,
  is_timed boolean DEFAULT false,
  time_limit integer, -- in minutes
  settings jsonb DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'paused', 'terminated')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS test_answers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  test_id uuid REFERENCES test_sessions ON DELETE CASCADE NOT NULL,
  question_id text NOT NULL, -- Changed to text to match existing schema
  selected_options jsonb NOT NULL,
  is_correct boolean NOT NULL,
  is_partially_correct boolean DEFAULT false,
  score numeric NOT NULL DEFAULT 0,
  time_spent integer NOT NULL, -- in seconds
  marked_for_review boolean DEFAULT false,
  notes text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS test_results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  test_id uuid REFERENCES test_sessions ON DELETE CASCADE NOT NULL,
  total_score numeric NOT NULL,
  correct_count integer NOT NULL,
  incorrect_count integer NOT NULL,
  partially_correct_count integer NOT NULL DEFAULT 0,
  skipped_count integer NOT NULL DEFAULT 0,
  average_time_per_question numeric NOT NULL, -- in seconds
  category_scores jsonb NOT NULL DEFAULT '{}'::jsonb,
  topic_scores jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS study_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  topic text NOT NULL,
  sub_topic text,
  questions_attempted integer DEFAULT 0,
  questions_correct integer DEFAULT 0,
  questions_incorrect integer DEFAULT 0,
  total_time_spent integer DEFAULT 0, -- in seconds
  last_study_date timestamptz,
  mastery_level text DEFAULT 'beginner' CHECK (mastery_level IN ('beginner', 'intermediate', 'advanced', 'master')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, topic, sub_topic)
);

CREATE TABLE IF NOT EXISTS user_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL UNIQUE,
  theme text DEFAULT 'light' CHECK (theme IN ('light', 'dark', 'system')),
  default_test_time integer DEFAULT 120, -- in minutes
  default_question_count integer DEFAULT 75,
  tutor_mode_enabled boolean DEFAULT true,
  sound_enabled boolean DEFAULT true,
  notification_preferences jsonb DEFAULT '{
    "test_reminders": true,
    "study_reminders": true,
    "performance_updates": true
  }'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE test_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE test_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE test_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Create triggers for updated_at
CREATE TRIGGER set_test_sessions_updated_at
  BEFORE UPDATE ON test_sessions
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_test_results_updated_at
  BEFORE UPDATE ON test_results
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_study_progress_updated_at
  BEFORE UPDATE ON study_progress
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_user_preferences_updated_at
  BEFORE UPDATE ON user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Create RLS policies
CREATE POLICY "Users can view their own test sessions"
  ON test_sessions
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own test sessions"
  ON test_sessions
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own test sessions"
  ON test_sessions
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own test answers"
  ON test_answers
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM test_sessions
      WHERE test_sessions.id = test_answers.test_id
      AND test_sessions.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert their own test answers"
  ON test_answers
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM test_sessions
      WHERE test_sessions.id = test_answers.test_id
      AND test_sessions.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can view their own test results"
  ON test_results
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM test_sessions
      WHERE test_sessions.id = test_results.test_id
      AND test_sessions.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can view their own study progress"
  ON study_progress
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own study progress"
  ON study_progress
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their own preferences"
  ON user_preferences
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_test_sessions_user_id ON test_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_test_sessions_status ON test_sessions(status);
CREATE INDEX IF NOT EXISTS idx_test_sessions_test_type ON test_sessions(test_type);
CREATE INDEX IF NOT EXISTS idx_test_answers_test_id ON test_answers(test_id);
CREATE INDEX IF NOT EXISTS idx_test_answers_question_id ON test_answers(question_id);
CREATE INDEX IF NOT EXISTS idx_test_results_test_id ON test_results(test_id);
CREATE INDEX IF NOT EXISTS idx_study_progress_user_id ON study_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_study_progress_topic ON study_progress(topic);
CREATE INDEX IF NOT EXISTS idx_study_progress_mastery_level ON study_progress(mastery_level);