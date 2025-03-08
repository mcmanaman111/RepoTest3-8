/*
  # Create notes and feedback tables

  1. New Tables
    - `notes`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `content` (text)
      - `question_id` (text)
      - `test_id` (text)
      - `topic` (text)
      - `sub_topic` (text)

    - `question_feedback`
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `question_id` (text)
      - `test_id` (text)
      - `message` (text)
      - `rating` (integer)
      - `difficulty` (text)
      - `status` (text)
      - `admin_response` (text)

    - `notifications`
      - `id` (uuid, primary key)
      - `user_id` (text)
      - `type` (text)
      - `title` (text)
      - `message` (text)
      - `link` (text)
      - `read` (boolean)

  2. Security
    - Enable RLS on all tables
    - Add policies for users to manage their own notes and feedback
    - Add policies for admins to manage feedback and notifications

  3. Changes
    - Create tables for notes, feedback, and notifications
    - Set up RLS policies
    - Create indexes for efficient querying
*/

-- Create notes table
CREATE TABLE IF NOT EXISTS notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  content text NOT NULL,
  question_id text NOT NULL,
  test_id text NOT NULL,
  topic text NOT NULL,
  sub_topic text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create question_feedback table
CREATE TABLE IF NOT EXISTS question_feedback (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  question_id text NOT NULL,
  test_id text NOT NULL,
  message text NOT NULL,
  rating integer NOT NULL CHECK (rating BETWEEN 1 AND 5),
  difficulty text NOT NULL CHECK (difficulty IN ('EASY', 'MEDIUM', 'HARD')),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'responded')),
  admin_response text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text NOT NULL,
  type text NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  link text,
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Create updated_at triggers
CREATE TRIGGER set_notes_updated_at
  BEFORE UPDATE ON notes
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_question_feedback_updated_at
  BEFORE UPDATE ON question_feedback
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Create RLS policies for notes
CREATE POLICY "Users can view own notes"
  ON notes
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notes"
  ON notes
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notes"
  ON notes
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own notes"
  ON notes
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all notes"
  ON notes
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

-- Create RLS policies for question_feedback
CREATE POLICY "Users can view own feedback"
  ON question_feedback
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own feedback"
  ON question_feedback
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all feedback"
  ON question_feedback
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

CREATE POLICY "Admins can update all feedback"
  ON question_feedback
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles
      WHERE users_profiles.id = auth.uid()
      AND users_profiles.user_type = 'administrator'
    )
  );

-- Create RLS policies for notifications
CREATE POLICY "Users can view own notifications"
  ON notifications
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid()::text OR user_id = 'admin');

CREATE POLICY "Users can update own notifications"
  ON notifications
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid()::text)
  WITH CHECK (user_id = auth.uid()::text);

CREATE POLICY "Admins can manage all notifications"
  ON notifications
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
CREATE INDEX idx_notes_user_id ON notes(user_id);
CREATE INDEX idx_notes_question_id ON notes(question_id);
CREATE INDEX idx_notes_topic ON notes(topic);
CREATE INDEX idx_question_feedback_user_id ON question_feedback(user_id);
CREATE INDEX idx_question_feedback_question_id ON question_feedback(question_id);
CREATE INDEX idx_question_feedback_status ON question_feedback(status);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_read ON notifications(read);