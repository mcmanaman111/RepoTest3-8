/*
  # Create users_profiles table

  1. New Tables
    - `users_profiles`
      - `id` (uuid, primary key, references auth.users)
      - `full_name` (text)
      - `avatar_url` (text)
      - `user_type` (text, enum of user types)
      - `subscription_status` (text)
      - `subscription_end_date` (timestamptz)
      - `exam_date` (date)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on users_profiles table
    - Add policies for:
      - Users can view their own profile
      - Users can update their own profile
      - Admins can view and update all profiles
      - Team members can view all profiles

  3. Changes
    - Create updated_at trigger function
    - Create trigger for automatic updated_at updates
*/

-- Create updated_at trigger function if it doesn't exist
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
  user_type text NOT NULL CHECK (user_type IN ('administrator', 'team_member', 'user', 'trial_user', 'test_user')),
  subscription_status text NOT NULL CHECK (subscription_status IN ('active', 'inactive', 'trial', 'expired')),
  subscription_end_date timestamptz,
  exam_date date,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE users_profiles ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE TRIGGER set_users_profiles_updated_at
  BEFORE UPDATE ON users_profiles
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Create RLS policies
-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON users_profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON users_profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Admins can view all profiles
CREATE POLICY "Admins can view all profiles"
  ON users_profiles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

-- Admins can update all profiles
CREATE POLICY "Admins can update all profiles"
  ON users_profiles
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

-- Team members can view all profiles
CREATE POLICY "Team members can view all profiles"
  ON users_profiles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'team_member'
    )
  );

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_profiles_user_type ON users_profiles(user_type);
CREATE INDEX IF NOT EXISTS idx_users_profiles_subscription_status ON users_profiles(subscription_status);
CREATE INDEX IF NOT EXISTS idx_users_profiles_subscription_end_date ON users_profiles(subscription_end_date);