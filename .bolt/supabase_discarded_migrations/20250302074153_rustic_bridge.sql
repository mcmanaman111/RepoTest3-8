-- Drop existing tables if they exist
DROP TABLE IF EXISTS user_ability CASCADE;
DROP TABLE IF EXISTS cat_ability_history CASCADE;
DROP TABLE IF EXISTS cat_responses CASCADE;
DROP TABLE IF EXISTS cat_sessions CASCADE;
DROP TABLE IF EXISTS question_category_mapping CASCADE;
DROP TABLE IF EXISTS question_statistics CASCADE;
DROP TABLE IF EXISTS question_difficulty CASCADE;
DROP TABLE IF EXISTS question_discrimination CASCADE;
DROP TABLE IF EXISTS question_guessing CASCADE;
DROP TABLE IF EXISTS question_options CASCADE;
DROP TABLE IF EXISTS questions CASCADE;
DROP TABLE IF EXISTS question_topics CASCADE;
DROP TABLE IF EXISTS question_categories CASCADE;

-- Create base tables
CREATE TABLE question_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE question_topics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id uuid REFERENCES question_categories ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(category_id, name)
);

-- Create questions and related tables
CREATE TABLE questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  text text NOT NULL,
  explanation text NOT NULL,
  question_type text NOT NULL CHECK (question_type IN ('multiple_choice', 'select_all', 'ordered_response', 'hot_spot', 'fill_blank', 'drag_drop', 'chart_exhibit', 'ngn_case_study')),
  difficulty text NOT NULL DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
  is_ngn boolean DEFAULT false,
  created_by uuid REFERENCES auth.users,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE question_options (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid REFERENCES questions ON DELETE CASCADE NOT NULL,
  text text NOT NULL,
  is_correct boolean NOT NULL DEFAULT false,
  explanation text,
  order_index integer NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE question_category_mapping (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid REFERENCES questions ON DELETE CASCADE NOT NULL,
  category_id uuid REFERENCES question_categories ON DELETE CASCADE NOT NULL,
  topic_id uuid REFERENCES question_topics ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(question_id, category_id, topic_id)
);

-- Create CAT-related tables
CREATE TABLE cat_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  start_time timestamptz DEFAULT now(),
  end_time timestamptz,
  initial_ability float8 DEFAULT 0,
  final_ability float8,
  confidence_interval float8,
  status text NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'terminated')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE cat_responses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid REFERENCES cat_sessions ON DELETE CASCADE NOT NULL,
  question_id uuid REFERENCES questions ON DELETE CASCADE NOT NULL,
  response jsonb NOT NULL,
  is_correct boolean NOT NULL,
  time_spent integer NOT NULL,
  ability_estimate float8 NOT NULL,
  standard_error float8 NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE cat_ability_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid REFERENCES cat_sessions ON DELETE CASCADE NOT NULL,
  ability_estimate float8 NOT NULL,
  standard_error float8 NOT NULL,
  question_number integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE user_ability (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  category_id uuid REFERENCES question_categories ON DELETE CASCADE,
  topic_id uuid REFERENCES question_topics ON DELETE CASCADE,
  ability_estimate float8 NOT NULL DEFAULT 0,
  confidence_interval float8 NOT NULL DEFAULT 1,
  sample_size integer NOT NULL DEFAULT 0,
  last_updated timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, category_id, topic_id)
);

-- Enable RLS on all tables
ALTER TABLE question_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_category_mapping ENABLE ROW LEVEL SECURITY;
ALTER TABLE cat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE cat_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE cat_ability_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_ability ENABLE ROW LEVEL SECURITY;

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER set_question_categories_updated_at
  BEFORE UPDATE ON question_categories
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_question_topics_updated_at
  BEFORE UPDATE ON question_topics
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_questions_updated_at
  BEFORE UPDATE ON questions
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_cat_sessions_updated_at
  BEFORE UPDATE ON cat_sessions
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Create RLS policies
CREATE POLICY "Enable read access for all users"
  ON question_categories
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Enable read access for all users"
  ON question_topics
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Enable read access for all users"
  ON questions
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Enable read access for all users"
  ON question_options
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can view their own CAT sessions"
  ON cat_sessions
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own CAT sessions"
  ON cat_sessions
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own CAT sessions"
  ON cat_sessions
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own CAT responses"
  ON cat_responses
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM cat_sessions
      WHERE cat_sessions.id = cat_responses.session_id
      AND cat_sessions.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert their own CAT responses"
  ON cat_responses
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM cat_sessions
      WHERE cat_sessions.id = cat_responses.session_id
      AND cat_sessions.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can view their own ability history"
  ON cat_ability_history
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM cat_sessions
      WHERE cat_sessions.id = cat_ability_history.session_id
      AND cat_sessions.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can view their own ability estimates"
  ON user_ability
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Create indexes
CREATE INDEX idx_question_topics_category_id ON question_topics(category_id);
CREATE INDEX idx_questions_question_type ON questions(question_type);
CREATE INDEX idx_questions_difficulty ON questions(difficulty);
CREATE INDEX idx_questions_is_ngn ON questions(is_ngn);
CREATE INDEX idx_question_options_question_id ON question_options(question_id);
CREATE INDEX idx_question_options_is_correct ON question_options(is_correct);
CREATE INDEX idx_question_category_mapping_question_id ON question_category_mapping(question_id);
CREATE INDEX idx_question_category_mapping_category_id ON question_category_mapping(category_id);
CREATE INDEX idx_question_category_mapping_topic_id ON question_category_mapping(topic_id);
CREATE INDEX idx_cat_sessions_user_id ON cat_sessions(user_id);
CREATE INDEX idx_cat_sessions_status ON cat_sessions(status);
CREATE INDEX idx_cat_responses_session_id ON cat_responses(session_id);
CREATE INDEX idx_cat_responses_question_id ON cat_responses(question_id);
CREATE INDEX idx_cat_ability_history_session_id ON cat_ability_history(session_id);
CREATE INDEX idx_user_ability_user_id ON user_ability(user_id);
CREATE INDEX idx_user_ability_category_id ON user_ability(category_id);
CREATE INDEX idx_user_ability_topic_id ON user_ability(topic_id);