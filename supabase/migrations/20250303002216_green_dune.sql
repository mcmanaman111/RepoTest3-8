/*
  # Question Bank Core Schema

  1. New Tables
    - `question_categories`
      - `id` (uuid, primary key)
      - `name` (text, unique)
      - `description` (text)
      - `parent_id` (uuid, self-reference for nested categories)
      - `order_index` (integer)
      - `is_active` (boolean)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `question_topics`
      - `id` (uuid, primary key)
      - `category_id` (uuid, references question_categories)
      - `name` (text)
      - `description` (text)
      - `order_index` (integer)
      - `is_active` (boolean)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

  2. Security
    - Enable RLS on both tables
    - Add policies for:
      - Public read access for active categories/topics
      - Admin-only write access
    
  3. Changes
    - Added self-referential parent_id for nested categories
    - Added order_index for custom sorting
    - Added is_active flag for soft deletion
*/

-- Create question_categories table
CREATE TABLE IF NOT EXISTS question_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  description text,
  parent_id uuid REFERENCES question_categories(id),
  order_index integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create question_topics table
CREATE TABLE IF NOT EXISTS question_topics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id uuid REFERENCES question_categories(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  description text,
  order_index integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(category_id, name)
);

-- Enable RLS
ALTER TABLE question_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_topics ENABLE ROW LEVEL SECURITY;

-- Create updated_at triggers
CREATE TRIGGER set_question_categories_updated_at
  BEFORE UPDATE ON question_categories
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_question_topics_updated_at
  BEFORE UPDATE ON question_topics
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Create RLS policies for question_categories
CREATE POLICY "Enable read access for active categories"
  ON question_categories
  FOR SELECT
  TO authenticated
  USING (is_active = true OR EXISTS (
    SELECT 1 FROM users_profiles
    WHERE users_profiles.id = auth.uid()
    AND users_profiles.user_type = 'administrator'
  ));

CREATE POLICY "Admins can manage categories"
  ON question_categories
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

-- Create RLS policies for question_topics
CREATE POLICY "Enable read access for active topics"
  ON question_topics
  FOR SELECT
  TO authenticated
  USING (is_active = true OR EXISTS (
    SELECT 1 FROM users_profiles
    WHERE users_profiles.id = auth.uid()
    AND users_profiles.user_type = 'administrator'
  ));

CREATE POLICY "Admins can manage topics"
  ON question_topics
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
CREATE INDEX idx_question_categories_parent_id ON question_categories(parent_id);
CREATE INDEX idx_question_categories_order_index ON question_categories(order_index);
CREATE INDEX idx_question_categories_is_active ON question_categories(is_active);
CREATE INDEX idx_question_topics_category_id ON question_topics(category_id);
CREATE INDEX idx_question_topics_order_index ON question_topics(order_index);
CREATE INDEX idx_question_topics_is_active ON question_topics(is_active);