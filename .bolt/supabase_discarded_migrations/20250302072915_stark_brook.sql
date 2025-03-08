/*
  # Base Tables for NCLEX Prep App
  
  1. New Tables
    - question_categories
    - question_topics
    - questions
    - question_options
    - question_category_mapping
    - question_statistics
    - question_difficulty
    - question_discrimination
    - question_guessing
    
  2. Security
    - Enables RLS on all tables
    - Adds policies for user access
*/

-- Create tables if they don't exist
DO $$ 
BEGIN
  -- Create question_categories if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'question_categories') THEN
    CREATE TABLE question_categories (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      name text NOT NULL UNIQUE,
      description text,
      created_at timestamptz DEFAULT now(),
      updated_at timestamptz DEFAULT now()
    );
  END IF;

  -- Create question_topics if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'question_topics') THEN
    CREATE TABLE question_topics (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      category_id uuid REFERENCES question_categories ON DELETE CASCADE NOT NULL,
      name text NOT NULL,
      description text,
      created_at timestamptz DEFAULT now(),
      updated_at timestamptz DEFAULT now(),
      UNIQUE(category_id, name)
    );
  END IF;

  -- Create questions if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'questions') THEN
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
  END IF;

  -- Create question_options if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'question_options') THEN
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
  END IF;

  -- Create question_category_mapping if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'question_category_mapping') THEN
    CREATE TABLE question_category_mapping (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      question_id uuid REFERENCES questions ON DELETE CASCADE NOT NULL,
      category_id uuid REFERENCES question_categories ON DELETE CASCADE NOT NULL,
      topic_id uuid REFERENCES question_topics ON DELETE CASCADE,
      created_at timestamptz DEFAULT now(),
      UNIQUE(question_id, category_id, topic_id)
    );
  END IF;

  -- Create question_statistics if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'question_statistics') THEN
    CREATE TABLE question_statistics (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      question_id uuid REFERENCES questions ON DELETE CASCADE NOT NULL,
      times_shown integer DEFAULT 0,
      times_correct integer DEFAULT 0,
      times_incorrect integer DEFAULT 0,
      times_skipped integer DEFAULT 0,
      avg_time_spent integer DEFAULT 0, -- in seconds
      created_at timestamptz DEFAULT now(),
      updated_at timestamptz DEFAULT now(),
      UNIQUE(question_id)
    );
  END IF;

  -- Create question_difficulty if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'question_difficulty') THEN
    CREATE TABLE question_difficulty (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      question_id uuid REFERENCES questions ON DELETE CASCADE NOT NULL,
      difficulty_value float8 NOT NULL,
      confidence_interval float8 NOT NULL,
      sample_size integer NOT NULL,
      created_at timestamptz DEFAULT now(),
      updated_at timestamptz DEFAULT now(),
      UNIQUE(question_id)
    );
  END IF;

  -- Create question_discrimination if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'question_discrimination') THEN
    CREATE TABLE question_discrimination (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      question_id uuid REFERENCES questions ON DELETE CASCADE NOT NULL,
      discrimination_value float8 NOT NULL,
      confidence_interval float8 NOT NULL,
      sample_size integer NOT NULL,
      created_at timestamptz DEFAULT now(),
      updated_at timestamptz DEFAULT now(),
      UNIQUE(question_id)
    );
  END IF;

  -- Create question_guessing if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'question_guessing') THEN
    CREATE TABLE question_guessing (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      question_id uuid REFERENCES questions ON DELETE CASCADE NOT NULL,
      guessing_value float8 NOT NULL,
      confidence_interval float8 NOT NULL,
      sample_size integer NOT NULL,
      created_at timestamptz DEFAULT now(),
      updated_at timestamptz DEFAULT now(),
      UNIQUE(question_id)
    );
  END IF;
END $$;

-- Enable RLS on all tables
DO $$ 
BEGIN
  EXECUTE 'ALTER TABLE question_categories ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE question_topics ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE questions ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE question_options ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE question_category_mapping ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE question_statistics ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE question_difficulty ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE question_discrimination ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE question_guessing ENABLE ROW LEVEL SECURITY';
EXCEPTION
  WHEN others THEN NULL;
END $$;

-- Create indexes if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_questions_question_type') THEN
    CREATE INDEX idx_questions_question_type ON questions(question_type);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_questions_difficulty') THEN
    CREATE INDEX idx_questions_difficulty ON questions(difficulty);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_questions_is_ngn') THEN
    CREATE INDEX idx_questions_is_ngn ON questions(is_ngn);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_question_options_question_id') THEN
    CREATE INDEX idx_question_options_question_id ON question_options(question_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_question_options_is_correct') THEN
    CREATE INDEX idx_question_options_is_correct ON question_options(is_correct);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_question_topics_category_id') THEN
    CREATE INDEX idx_question_topics_category_id ON question_topics(category_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_question_category_mapping_question_id') THEN
    CREATE INDEX idx_question_category_mapping_question_id ON question_category_mapping(question_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_question_category_mapping_category_id') THEN
    CREATE INDEX idx_question_category_mapping_category_id ON question_category_mapping(category_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_question_category_mapping_topic_id') THEN
    CREATE INDEX idx_question_category_mapping_topic_id ON question_category_mapping(topic_id);
  END IF;
END $$;