/*
  # Update Test Terminology

  1. Changes
    - Rename columns in test_results to match application terminology:
      - category_scores -> client_needs_scores
      - topic_scores -> sub_topic_scores
    - Add client_needs and sub_topics arrays to test_sessions
    - Update column names in study_progress to match terminology
    - Add client_needs_area and client_needs_topic to test_answers

  2. Security
    - Maintain existing RLS policies
    - No changes to access control needed
*/

-- Add new columns to test_sessions
ALTER TABLE test_sessions 
ADD COLUMN IF NOT EXISTS selected_client_needs text[] DEFAULT ARRAY[]::text[],
ADD COLUMN IF NOT EXISTS selected_sub_topics text[] DEFAULT ARRAY[]::text[];

-- Add new columns to test_answers
ALTER TABLE test_answers 
ADD COLUMN IF NOT EXISTS client_needs_area text,
ADD COLUMN IF NOT EXISTS client_needs_topic text;

-- Rename columns in test_results
ALTER TABLE test_results 
RENAME COLUMN category_scores TO client_needs_scores;

ALTER TABLE test_results 
RENAME COLUMN topic_scores TO sub_topic_scores;

-- Update study_progress terminology
ALTER TABLE study_progress 
RENAME COLUMN topic TO client_needs_area;

ALTER TABLE study_progress 
RENAME COLUMN sub_topic TO client_needs_topic;

-- Update daily_study_logs terminology
ALTER TABLE daily_study_logs 
RENAME COLUMN topics_covered TO client_needs_covered;

-- Add new column for sub-topics to daily_study_logs
ALTER TABLE daily_study_logs 
ADD COLUMN IF NOT EXISTS sub_topics_covered text[] DEFAULT ARRAY[]::text[];

-- Create new indexes for the renamed/new columns
CREATE INDEX IF NOT EXISTS idx_test_sessions_selected_client_needs ON test_sessions USING gin(selected_client_needs);
CREATE INDEX IF NOT EXISTS idx_test_sessions_selected_sub_topics ON test_sessions USING gin(selected_sub_topics);
CREATE INDEX IF NOT EXISTS idx_test_answers_client_needs_area ON test_answers(client_needs_area);
CREATE INDEX IF NOT EXISTS idx_test_answers_client_needs_topic ON test_answers(client_needs_topic);
CREATE INDEX IF NOT EXISTS idx_study_progress_client_needs_area ON study_progress(client_needs_area);
CREATE INDEX IF NOT EXISTS idx_study_progress_client_needs_topic ON study_progress(client_needs_topic);
CREATE INDEX IF NOT EXISTS idx_daily_study_logs_client_needs ON daily_study_logs USING gin(client_needs_covered);
CREATE INDEX IF NOT EXISTS idx_daily_study_logs_sub_topics ON daily_study_logs USING gin(sub_topics_covered);

-- Drop old indexes that are no longer needed
DROP INDEX IF EXISTS idx_study_progress_topic;
DROP INDEX IF EXISTS idx_study_progress_sub_topic;

-- Update unique constraint on study_progress
ALTER TABLE study_progress 
DROP CONSTRAINT IF EXISTS study_progress_user_id_topic_sub_topic_key;

ALTER TABLE study_progress
ADD CONSTRAINT study_progress_user_id_client_needs_key UNIQUE (user_id, client_needs_area, client_needs_topic);