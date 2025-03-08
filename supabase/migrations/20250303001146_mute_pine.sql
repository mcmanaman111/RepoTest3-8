/*
  # Create daily study logs table

  1. New Tables
    - `daily_study_logs`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `study_date` (date)
      - `questions_completed` (integer)
      - `time_spent` (integer, in minutes)
      - `topics_covered` (text array)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on daily_study_logs table
    - Add policies for:
      - Users can view and manage their own logs
      - Admins can view all logs

  3. Changes
    - Create table for tracking daily study activity
    - Set up RLS policies
    - Create indexes for efficient querying
*/

-- Create daily_study_logs table
CREATE TABLE IF NOT EXISTS daily_study_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  study_date date NOT NULL,
  questions_completed integer DEFAULT 0,
  time_spent integer DEFAULT 0, -- in minutes
  topics_covered text[] DEFAULT ARRAY[]::text[],
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, study_date)
);

-- Enable RLS
ALTER TABLE daily_study_logs ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE TRIGGER set_daily_study_logs_updated_at
  BEFORE UPDATE ON daily_study_logs
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Create RLS policies
CREATE POLICY "Users can view own study logs"
  ON daily_study_logs
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own study logs"
  ON daily_study_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own study logs"
  ON daily_study_logs
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all study logs"
  ON daily_study_logs
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
CREATE INDEX idx_daily_study_logs_user_id ON daily_study_logs(user_id);
CREATE INDEX idx_daily_study_logs_study_date ON daily_study_logs(study_date);
CREATE INDEX idx_daily_study_logs_user_date ON daily_study_logs(user_id, study_date);