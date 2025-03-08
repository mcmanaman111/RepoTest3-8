/*
  # Create subscription history table

  1. New Tables
    - `subscription_history`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `subscription_type` (text, plan type)
      - `status` (text, subscription status)
      - `start_date` (timestamptz)
      - `end_date` (timestamptz)
      - `amount` (numeric)
      - `currency` (text)
      - `payment_method` (text)
      - `payment_status` (text)
      - `metadata` (jsonb)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on subscription_history table
    - Add policies for:
      - Users can view their own subscription history
      - Admins can view and manage all subscriptions

  3. Changes
    - Create table with comprehensive subscription tracking
    - Set up RLS policies
    - Create indexes for efficient querying
*/

-- Create subscription_history table
CREATE TABLE IF NOT EXISTS subscription_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  subscription_type text NOT NULL CHECK (subscription_type IN ('free', 'basic', 'premium', 'team', 'enterprise')),
  status text NOT NULL CHECK (status IN ('active', 'cancelled', 'expired', 'trial', 'pending')),
  start_date timestamptz NOT NULL,
  end_date timestamptz,
  amount numeric,
  currency text DEFAULT 'USD',
  payment_method text,
  payment_status text CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE subscription_history ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger
CREATE TRIGGER set_subscription_history_updated_at
  BEFORE UPDATE ON subscription_history
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Create RLS policies
CREATE POLICY "Users can view own subscription history"
  ON subscription_history
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all subscription history"
  ON subscription_history
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

CREATE POLICY "Admins can manage all subscription history"
  ON subscription_history
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

-- Create indexes
CREATE INDEX idx_subscription_history_user_id ON subscription_history(user_id);
CREATE INDEX idx_subscription_history_subscription_type ON subscription_history(subscription_type);
CREATE INDEX idx_subscription_history_status ON subscription_history(status);
CREATE INDEX idx_subscription_history_start_date ON subscription_history(start_date);
CREATE INDEX idx_subscription_history_end_date ON subscription_history(end_date);
CREATE INDEX idx_subscription_history_payment_status ON subscription_history(payment_status);