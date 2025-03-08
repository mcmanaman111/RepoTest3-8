/*
  # Add Achievement System Tables
  
  1. New Tables
    - achievements: Defines available achievements
    - user_achievements: Tracks user progress towards achievements
    - achievement_rules: Defines criteria for earning achievements
    
  2. Security
    - Enable RLS on all tables
    - Add policies for user data access
    
  3. Changes
    - Add indexes for performance optimization
    - Add triggers for updated_at timestamps
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

-- Create RLS policies
CREATE POLICY "Enable read access for all users"
  ON achievements
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Enable read access for all users"
  ON achievement_rules
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can view their own achievements"
  ON user_achievements
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own achievements"
  ON user_achievements
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create indexes
CREATE INDEX idx_achievements_category ON achievements(category);
CREATE INDEX idx_achievements_badge_level ON achievements(badge_level);
CREATE INDEX idx_achievement_rules_achievement_id ON achievement_rules(achievement_id);
CREATE INDEX idx_achievement_rules_rule_type ON achievement_rules(rule_type);
CREATE INDEX idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX idx_user_achievements_achievement_id ON user_achievements(achievement_id);
CREATE INDEX idx_user_achievements_completed ON user_achievements(completed);