-- Create client needs areas
INSERT INTO client_needs_areas (name, description, order_index) VALUES
('Management of Care', 'Focuses on coordination of care, safety, legal rights, and ethical practice.', 1),
('Safety and Infection Control', 'Covers prevention of injury, emergency response, and infection prevention.', 2),
('Health Promotion and Maintenance', 'Addresses prevention, early detection, and lifestyle choices.', 3),
('Psychosocial Integrity', 'Deals with mental health, coping, and cultural aspects of care.', 4),
('Basic Care and Comfort', 'Covers activities of daily living, nutrition, and rest.', 5),
('Pharmacological Therapies', 'Focuses on medication administration and pain management.', 6),
('Reduction of Risk Potential', 'Addresses complications and health alterations.', 7),
('Physiological Adaptation', 'Covers care for acute, chronic, and life-threatening conditions.', 8)
ON CONFLICT (name) DO NOTHING;

-- Insert first question
WITH inserted_question AS (
  INSERT INTO questions (
    text,
    explanation,
    question_type,
    difficulty,
    statistics
  ) VALUES (
    'The charge nurse is making assignments for the day shift. Which task should be delegated to the unlicensed assistive personnel (UAP)?',
    jsonb_build_object(
      'correct', jsonb_build_array('Measuring and recording vital signs is within the scope of practice for UAPs. They are trained to perform this task accurately and report abnormal findings to the RN.'),
      'incorrect', jsonb_build_array(
        'Initial assessment must be performed by the RN as it requires clinical judgment.',
        'IV medication administration requires nursing judgment and is not within UAP scope.',
        'Patient teaching requires nursing knowledge and judgment.'
      )
    ),
    'multiple_choice',
    'medium',
    jsonb_build_object(
      'clientNeedArea', 'Management of Care',
      'clientNeedTopic', 'Assignment and Delegation',
      'timeTaken', '1:45',
      'avgPeerScore', '76%',
      'difficulty', 'MEDIUM'
    )
  )
  RETURNING id
),
area_id AS (
  SELECT id FROM client_needs_areas WHERE name = 'Management of Care' LIMIT 1
)
INSERT INTO question_options (question_id, text, is_correct, order_index)
SELECT 
  (SELECT id FROM inserted_question),
  unnest(ARRAY[
    'Performing initial patient assessment',
    'Measuring and recording vital signs',
    'Administering IV medications',
    'Teaching about medication side effects'
  ]),
  unnest(ARRAY[false, true, false, false]),
  generate_series(1, 4);

-- Insert second question
WITH inserted_question AS (
  INSERT INTO questions (
    text,
    explanation,
    question_type,
    difficulty,
    statistics
  ) VALUES (
    'A nurse is caring for a patient in contact isolation. Which items should the nurse gather before entering the room? Select all that apply.',
    jsonb_build_object(
      'correct', jsonb_build_array(
        'Gloves are required for contact precautions to prevent transmission of organisms.',
        'A gown protects clothing from contamination during patient care.',
        'Hand sanitizer is essential for hand hygiene before and after patient contact.'
      ),
      'incorrect', jsonb_build_array(
        'An N95 respirator is not required for contact isolation.',
        'Shoe covers are not routinely required for contact precautions.'
      )
    ),
    'select_all',
    'medium',
    jsonb_build_object(
      'clientNeedArea', 'Safety and Infection Control',
      'clientNeedTopic', 'Standard Precautions',
      'timeTaken', '2:15',
      'avgPeerScore', '82%',
      'difficulty', 'MEDIUM'
    )
  )
  RETURNING id
),
area_id AS (
  SELECT id FROM client_needs_areas WHERE name = 'Safety and Infection Control' LIMIT 1
)
INSERT INTO question_options (question_id, text, is_correct, order_index)
SELECT 
  (SELECT id FROM inserted_question),
  unnest(ARRAY[
    'Disposable gloves',
    'Isolation gown',
    'N95 respirator',
    'Hand sanitizer',
    'Shoe covers'
  ]),
  unnest(ARRAY[true, true, false, true, false]),
  generate_series(1, 5);