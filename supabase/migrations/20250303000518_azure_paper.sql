/*
  # Create user_preferences table

  1. New Tables
    - `user_preferences`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `theme` (text, light/dark/system)
      - `default_test_time` (integer, minutes)
      - `default_question_count` (integer)
      - `tutor_mode_enabled` (boolean)
      - `sound_enabled` (boolean)
      - `notification_preferences` (jsonb)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on user_preferences table
    - Add policies for:
      - Users can view and update their own preferences
      - Admins can view all preferences

  3. Changes
    - Create table with default values
    - Set up RLS policies
    - Create indexes for efficient querying
*/

-- Create user_preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL UNIQUE,
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
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE TRIGGER set_user_preferences_updated_at
  BEFORE UPDATE ON user_preferences
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Create RLS policies
CREATE POLICY "Users can manage their own preferences"
  ON user_preferences
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all preferences"
  ON user_preferences
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
CREATE INDEX idx_user_preferences_user_id ON user_preferences(user_id);
CREATE INDEX idx_user_preferences_theme ON user_preferences(theme);