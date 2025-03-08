/*
  # Add Flashcards Tables
  
  1. New Tables
    - flashcard_decks
      - id (uuid, primary key)
      - user_id (uuid, references auth.users)
      - name (text)
      - description (text)
      - is_public (boolean)
      - created_at (timestamptz)
      - updated_at (timestamptz)
    
    - flashcards
      - id (uuid, primary key)
      - deck_id (uuid, references flashcard_decks)
      - front_content (text)
      - back_content (text)
      - topic (text)
      - sub_topic (text)
      - created_at (timestamptz)
      - updated_at (timestamptz)
    
    - flashcard_study_logs
      - id (uuid, primary key)
      - user_id (uuid, references auth.users)
      - flashcard_id (uuid, references flashcards)
      - confidence_level (integer)
      - next_review_date (timestamptz)
      - created_at (timestamptz)
      - updated_at (timestamptz)
    
  2. Security
    - Enable RLS
    - Add policies for user data access
    
  3. Changes
    - Add indexes for performance optimization
    - Add trigger for updated_at timestamp
*/

-- Create flashcard decks table
CREATE TABLE IF NOT EXISTS flashcard_decks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  name text NOT NULL,
  description text,
  is_public boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create flashcards table
CREATE TABLE IF NOT EXISTS flashcards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  deck_id uuid REFERENCES flashcard_decks ON DELETE CASCADE NOT NULL,
  front_content text NOT NULL,
  back_content text NOT NULL,
  topic text,
  sub_topic text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create flashcard study logs table
CREATE TABLE IF NOT EXISTS flashcard_study_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  flashcard_id uuid REFERENCES flashcards ON DELETE CASCADE NOT NULL,
  confidence_level integer CHECK (confidence_level BETWEEN 1 AND 5),
  next_review_date timestamptz NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE flashcard_decks ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashcards ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashcard_study_logs ENABLE ROW LEVEL SECURITY;

-- Create updated_at triggers
CREATE TRIGGER set_flashcard_decks_updated_at
  BEFORE UPDATE ON flashcard_decks
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_flashcards_updated_at
  BEFORE UPDATE ON flashcards
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_flashcard_study_logs_updated_at
  BEFORE UPDATE ON flashcard_study_logs
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

-- Create RLS policies for flashcard_decks
CREATE POLICY "Users can view public decks"
  ON flashcard_decks
  FOR SELECT
  TO authenticated
  USING (is_public OR auth.uid() = user_id);

CREATE POLICY "Users can manage their own decks"
  ON flashcard_decks
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create RLS policies for flashcards
CREATE POLICY "Users can view flashcards from accessible decks"
  ON flashcards
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM flashcard_decks
      WHERE flashcard_decks.id = flashcards.deck_id
      AND (flashcard_decks.is_public OR flashcard_decks.user_id = auth.uid())
    )
  );

CREATE POLICY "Users can manage flashcards in their own decks"
  ON flashcards
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM flashcard_decks
      WHERE flashcard_decks.id = flashcards.deck_id
      AND flashcard_decks.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM flashcard_decks
      WHERE flashcard_decks.id = flashcards.deck_id
      AND flashcard_decks.user_id = auth.uid()
    )
  );

-- Create RLS policies for flashcard_study_logs
CREATE POLICY "Users can manage their own study logs"
  ON flashcard_study_logs
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create indexes
CREATE INDEX idx_flashcard_decks_user_id ON flashcard_decks(user_id);
CREATE INDEX idx_flashcard_decks_is_public ON flashcard_decks(is_public);
CREATE INDEX idx_flashcards_deck_id ON flashcards(deck_id);
CREATE INDEX idx_flashcards_topic ON flashcards(topic);
CREATE INDEX idx_flashcard_study_logs_user_id ON flashcard_study_logs(user_id);
CREATE INDEX idx_flashcard_study_logs_flashcard_id ON flashcard_study_logs(flashcard_id);
CREATE INDEX idx_flashcard_study_logs_next_review ON flashcard_study_logs(next_review_date);