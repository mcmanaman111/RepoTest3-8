/*
  # Create achievements and rewards system

  1. New Tables
    - `achievements`
      - `id` (uuid, primary key)
      - `name` (text)
      - `description` (text)
      - `icon_name` (text)
      - `points` (integer)
      - `badge_level` (text)
      - `category` (text)

    - `achievement_rules`
      - `id` (uuid, primary key)
      - `achievement_id` (uuid, references achievements)
      - `rule_type` (text)
      - `threshold` (integer)
      - `comparison` (text)
      - `metric` (text)

    - `user_achievements`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `achievement_id` (uuid, references achievements)
      - `progress` (integer)
      - `completed` (boolean)
      - `completed_at` (timestamptz)

  2. Security
    - Enable RLS on all tables
    - Add policies for users to view their achievements
    - Add policies for admins to manage achievements

  3. Changes
    - Create tables for achievements system
    - Set up RLS policies
    - Create indexes for efficient querying
*/

-- Create achievements table
CREATE TABLE IF NOT EXISTS achievements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  description text NOT NULL,
  icon_name text NOT NULL,
  points integer NOT NULL DEFAULT 0,
  badge_level text NOT NULL CHECK (badge_level IN ('bronze', 'silver', 'gold', 'platinum')),
  category text NOT NULL CHECK (category IN ('study', 'test', 'mastery', 'streak', 'special')),
  is_hidden boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create achievement rules table
CREATE TABLE IF NOT EXISTS achievement_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  achievement_id uuid REFERENCES achievements ON DELETE CASCADE NOT NULL,
  rule_type text NOT NULL CHECK (rule_type IN ('count', 'streak', 'score', 'time', 'custom')),
  threshold integer NOT NULL,
  comparison text NOT NULL CHECK (comparison IN ('>=', '>', '=', '<', '<=')),
  metric text NOT NULL,
  additional_criteria jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(achievement_id, rule_type, metric)
);

-- Create user achievements table
CREATE TABLE IF NOT EXISTS user_achievements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  achievement_id uuid REFERENCES achievements ON DELETE CASCADE NOT NULL,
  progress integer DEFAULT 0,
  completed boolean DEFAULT false,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, achievement_id)
);

-- Enable RLS
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievement_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- Create updated_at triggers
CREATE TRIGGER set_achievements_updated_at
  BEFORE UPDATE ON achievements
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_achievement_rules_updated_at
  BEFORE UPDATE ON achievement_rules
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_user_achievements_updated_at
  BEFORE UPDATE ON user_achievements
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Create RLS policies for achievements
CREATE POLICY "Enable read access for all users"
  ON achievements
  FOR SELECT
  TO authenticated
  USING (NOT is_hidden OR EXISTS (
    SELECT 1 FROM users_profiles
    WHERE users_profiles.id = auth.uid()
    AND users_profiles.user_type = 'administrator'
  ));

CREATE POLICY "Admins can manage achievements"
  ON achievements
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

-- Create RLS policies for achievement_rules
CREATE POLICY "Enable read access for all users"
  ON achievement_rules
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage achievement rules"
  ON achievement_rules
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

-- Create RLS policies for user_achievements
CREATE POLICY "Users can view own achievements"
  ON user_achievements
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own achievements"
  ON user_achievements
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all user achievements"
  ON user_achievements
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
CREATE INDEX idx_achievements_category ON achievements(category);
CREATE INDEX idx_achievements_badge_level ON achievements(badge_level);
CREATE INDEX idx_achievements_is_hidden ON achievements(is_hidden);
CREATE INDEX idx_achievement_rules_achievement_id ON achievement_rules(achievement_id);
CREATE INDEX idx_achievement_rules_rule_type ON achievement_rules(rule_type);
CREATE INDEX idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX idx_user_achievements_achievement_id ON user_achievements(achievement_id);
CREATE INDEX idx_user_achievements_completed ON user_achievements(completed);