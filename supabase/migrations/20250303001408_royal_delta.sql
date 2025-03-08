/*
  # Create test sessions and related tables

  1. New Tables
    - `test_sessions`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `test_type` (text, enum: practice, quick, custom, cat)
      - `start_time` (timestamptz)
      - `end_time` (timestamptz)
      - `total_questions` (integer)
      - `completed_questions` (integer)
      - `is_timed` (boolean)
      - `time_limit` (integer, in minutes)
      - `settings` (jsonb)
      - `status` (text, enum: in_progress, completed, paused, terminated)

    - `test_answers`
      - `id` (uuid, primary key)
      - `test_id` (uuid, references test_sessions)
      - `question_id` (text)
      - `selected_options` (jsonb)
      - `is_correct` (boolean)
      - `is_partially_correct` (boolean)
      - `score` (numeric)
      - `time_spent` (integer, in seconds)
      - `marked_for_review` (boolean)
      - `notes` (text)

    - `test_results`
      - `id` (uuid, primary key)
      - `test_id` (uuid, references test_sessions)
      - `total_score` (numeric)
      - `correct_count` (integer)
      - `incorrect_count` (integer)
      - `partially_correct_count` (integer)
      - `skipped_count` (integer)
      - `average_time_per_question` (numeric)
      - `category_scores` (jsonb)
      - `topic_scores` (jsonb)

  2. Security
    - Enable RLS on all tables
    - Add policies for users to manage their own test data
    - Add policies for admins to view all test data

  3. Changes
    - Create tables for test sessions, answers, and results
    - Set up RLS policies
    - Create indexes for efficient querying
*/

-- Create test_sessions table
CREATE TABLE IF NOT EXISTS test_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
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

-- Create test_answers table
CREATE TABLE IF NOT EXISTS test_answers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  test_id uuid REFERENCES test_sessions ON DELETE CASCADE NOT NULL,
  question_id text NOT NULL,
  selected_options jsonb NOT NULL,
  is_correct boolean NOT NULL,
  is_partially_correct boolean DEFAULT false,
  score numeric NOT NULL DEFAULT 0,
  time_spent integer NOT NULL, -- in seconds
  marked_for_review boolean DEFAULT false,
  notes text,
  created_at timestamptz DEFAULT now()
);

-- Create test_results table
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

-- Enable RLS
ALTER TABLE test_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE test_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE test_results ENABLE ROW LEVEL SECURITY;

-- Create updated_at triggers
CREATE TRIGGER set_test_sessions_updated_at
  BEFORE UPDATE ON test_sessions
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_test_results_updated_at
  BEFORE UPDATE ON test_results
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Create RLS policies for test_sessions
CREATE POLICY "Users can view own test sessions"
  ON test_sessions
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own test sessions"
  ON test_sessions
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own test sessions"
  ON test_sessions
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all test sessions"
  ON test_sessions
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

-- Create RLS policies for test_answers
CREATE POLICY "Users can view own test answers"
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

CREATE POLICY "Users can insert own test answers"
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

CREATE POLICY "Admins can view all test answers"
  ON test_answers
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

-- Create RLS policies for test_results
CREATE POLICY "Users can view own test results"
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

CREATE POLICY "Users can insert own test results"
  ON test_results
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM test_sessions
      WHERE test_sessions.id = test_results.test_id
      AND test_sessions.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can view all test results"
  ON test_results
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
CREATE INDEX idx_test_sessions_user_id ON test_sessions(user_id);
CREATE INDEX idx_test_sessions_test_type ON test_sessions(test_type);
CREATE INDEX idx_test_sessions_status ON test_sessions(status);
CREATE INDEX idx_test_sessions_start_time ON test_sessions(start_time);
CREATE INDEX idx_test_answers_test_id ON test_answers(test_id);
CREATE INDEX idx_test_answers_question_id ON test_answers(question_id);
CREATE INDEX idx_test_answers_is_correct ON test_answers(is_correct);
CREATE INDEX idx_test_results_test_id ON test_results(test_id);
CREATE INDEX idx_test_results_total_score ON test_results(total_score);