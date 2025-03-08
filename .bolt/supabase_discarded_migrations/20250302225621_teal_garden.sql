/*
  # Initial Schema Setup for PrepClex

  1. New Tables
    - `users_profiles` - Stores user profile information
    - `notes` - Stores user study notes
    - `question_feedback` - Stores user feedback on questions
    - `notifications` - Stores user notifications
    - `test_sessions` - Stores information about test sessions
    - `test_answers` - Stores user answers for test questions
    - `test_results` - Stores test results and analytics
    - `study_progress` - Tracks user study progress by topic

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users to manage their own data
    - Add policies for admins to access all data

  3. Changes
    - Initial schema setup with core functionality
*/

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create users_profiles table
CREATE TABLE IF NOT EXISTS users_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  full_name text,
  avatar_url text,
  exam_date date,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create notes table
CREATE TABLE IF NOT EXISTS notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  content text NOT NULL,
  question_id text NOT NULL,
  test_id text NOT NULL,
  topic text NOT NULL,
  sub_topic text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create question_feedback table
CREATE TABLE IF NOT EXISTS question_feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  question_id text NOT NULL,
  test_id text NOT NULL,
  message text NOT NULL,
  rating integer NOT NULL CHECK (rating BETWEEN 1 AND 5),
  difficulty text NOT NULL CHECK (difficulty IN ('EASY', 'MEDIUM', 'HARD')),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'responded')),
  admin_response text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text NOT NULL,
  type text NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  link text,
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

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

-- Create study_progress table
CREATE TABLE IF NOT EXISTS study_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
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

-- Create study_streaks table
CREATE TABLE IF NOT EXISTS study_streaks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  current_streak integer DEFAULT 0,
  longest_streak integer DEFAULT 0,
  last_study_date timestamptz,
  streak_start_date timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id)
);

-- Enable RLS on all tables
ALTER TABLE users_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE test_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE test_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE test_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_streaks ENABLE ROW LEVEL SECURITY;

-- Create updated_at triggers
CREATE TRIGGER set_users_profiles_updated_at
  BEFORE UPDATE ON users_profiles
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_notes_updated_at
  BEFORE UPDATE ON notes
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_question_feedback_updated_at
  BEFORE UPDATE ON question_feedback
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

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

CREATE TRIGGER set_study_streaks_updated_at
  BEFORE UPDATE ON study_streaks
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Create RLS policies for users_profiles
CREATE POLICY "Users can view their own profile"
  ON users_profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON users_profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
  ON users_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Create RLS policies for notes
CREATE POLICY "Users can view their own notes"
  ON notes
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own notes"
  ON notes
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own notes"
  ON notes
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notes"
  ON notes
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Create RLS policies for question_feedback
CREATE POLICY "Users can view their own feedback"
  ON question_feedback
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own feedback"
  ON question_feedback
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Create RLS policies for notifications
CREATE POLICY "Users can view their own notifications"
  ON notifications
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid()::text OR user_id = 'admin');

CREATE POLICY "Users can update their own notifications"
  ON notifications
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid()::text)
  WITH CHECK (user_id = auth.uid()::text);

-- Create RLS policies for test_sessions
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

-- Create RLS policies for test_answers
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

-- Create RLS policies for test_results
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

-- Create RLS policies for study_progress
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

-- Create RLS policies for study_streaks
CREATE POLICY "Users can view their own study streaks"
  ON study_streaks
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own study streaks"
  ON study_streaks
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert their own study streaks"
  ON study_streaks
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_question_id ON notes(question_id);
CREATE INDEX IF NOT EXISTS idx_notes_topic ON notes(topic);
CREATE INDEX IF NOT EXISTS idx_question_feedback_user_id ON question_feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_question_feedback_question_id ON question_feedback(question_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(read);
CREATE INDEX IF NOT EXISTS idx_test_sessions_user_id ON test_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_test_sessions_status ON test_sessions(status);
CREATE INDEX IF NOT EXISTS idx_test_answers_test_id ON test_answers(test_id);
CREATE INDEX IF NOT EXISTS idx_test_results_test_id ON test_results(test_id);
CREATE INDEX IF NOT EXISTS idx_study_progress_user_id ON study_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_study_progress_topic ON study_progress(topic);
CREATE INDEX IF NOT EXISTS idx_study_streaks_user_id ON study_streaks(user_id);
CREATE INDEX IF NOT EXISTS idx_study_streaks_current_streak ON study_streaks(current_streak);