/*
  # Add Study Streaks Table
  
  1. New Tables
    - study_streaks
      - id (uuid, primary key)
      - user_id (uuid, references auth.users)
      - current_streak (integer)
      - longest_streak (integer)
      - last_study_date (timestamptz)
      - streak_start_date (timestamptz)
      - created_at (timestamptz)
      - updated_at (timestamptz)
    
  2. Security
    - Enable RLS
    - Add policies for user data access
    
  3. Changes
    - Add indexes for performance optimization
    - Add trigger for updated_at timestamp
*/

-- Create study streaks table
CREATE TABLE IF NOT EXISTS study_streaks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  current_streak integer DEFAULT 0,
  longest_streak integer DEFAULT 0,
  last_study_date timestamptz,
  streak_start_date timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id)
);

-- Create daily study logs table to track detailed study activity
CREATE TABLE IF NOT EXISTS daily_study_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  study_date date NOT NULL,
  questions_completed integer DEFAULT 0,
  time_spent integer DEFAULT 0, -- in minutes
  topics_covered text[] DEFAULT ARRAY[]::text[],
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, study_date)
);

-- Enable RLS
ALTER TABLE study_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_study_logs ENABLE ROW LEVEL SECURITY;

-- Create updated_at triggers
CREATE TRIGGER set_study_streaks_updated_at
  BEFORE UPDATE ON study_streaks
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_daily_study_logs_updated_at
  BEFORE UPDATE ON daily_study_logs
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

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

-- Create RLS policies for daily_study_logs
CREATE POLICY "Users can view their own study logs"
  ON daily_study_logs
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own study logs"
  ON daily_study_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own study logs"
  ON daily_study_logs
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create indexes
CREATE INDEX idx_study_streaks_user_id ON study_streaks(user_id);
CREATE INDEX idx_study_streaks_current_streak ON study_streaks(current_streak);
CREATE INDEX idx_study_streaks_last_study_date ON study_streaks(last_study_date);
CREATE INDEX idx_daily_study_logs_user_id ON daily_study_logs(user_id);
CREATE INDEX idx_daily_study_logs_study_date ON daily_study_logs(study_date);
CREATE INDEX idx_daily_study_logs_user_date ON daily_study_logs(user_id, study_date);