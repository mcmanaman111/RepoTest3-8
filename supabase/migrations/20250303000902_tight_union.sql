/*
  # Create study progress tracking table

  1. New Tables
    - `study_progress`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `topic` (text)
      - `sub_topic` (text)
      - `questions_attempted` (integer)
      - `questions_correct` (integer)
      - `questions_incorrect` (integer)
      - `total_time_spent` (integer, in seconds)
      - `last_study_date` (timestamptz)
      - `mastery_level` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on study_progress table
    - Add policies for:
      - Users can view and update their own progress
      - Admins can view all progress data

  3. Changes
    - Create table with comprehensive progress tracking
    - Set up RLS policies
    - Create indexes for efficient querying
*/

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

-- Enable RLS
ALTER TABLE study_progress ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE TRIGGER set_study_progress_updated_at
  BEFORE UPDATE ON study_progress
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Create RLS policies
CREATE POLICY "Users can view own study progress"
  ON study_progress
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own study progress"
  ON study_progress
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all study progress"
  ON study_progress
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
CREATE INDEX idx_study_progress_user_id ON study_progress(user_id);
CREATE INDEX idx_study_progress_topic ON study_progress(topic);
CREATE INDEX idx_study_progress_sub_topic ON study_progress(sub_topic);
CREATE INDEX idx_study_progress_mastery_level ON study_progress(mastery_level);
CREATE INDEX idx_study_progress_last_study_date ON study_progress(last_study_date);