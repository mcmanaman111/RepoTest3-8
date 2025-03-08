/*
  # Create study streaks tracking table

  1. New Tables
    - `study_streaks`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `current_streak` (integer)
      - `longest_streak` (integer)
      - `last_study_date` (timestamptz)
      - `streak_start_date` (timestamptz)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on study_streaks table
    - Add policies for:
      - Users can view and update their own streaks
      - Admins can view all streaks

  3. Changes
    - Create table for tracking study streaks
    - Set up RLS policies
    - Create indexes for efficient querying
*/

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

-- Enable RLS
ALTER TABLE study_streaks ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE TRIGGER set_study_streaks_updated_at
  BEFORE UPDATE ON study_streaks
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Create RLS policies
CREATE POLICY "Users can view own study streaks"
  ON study_streaks
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own study streaks"
  ON study_streaks
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can insert own study streaks"
  ON study_streaks
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all study streaks"
  ON study_streaks
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
CREATE INDEX idx_study_streaks_user_id ON study_streaks(user_id);
CREATE INDEX idx_study_streaks_current_streak ON study_streaks(current_streak);
CREATE INDEX idx_study_streaks_last_study_date ON study_streaks(last_study_date);