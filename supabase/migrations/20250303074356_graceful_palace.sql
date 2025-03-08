-- Insert additional NCLEX questions

-- Question 3: Health Promotion and Maintenance - SATA
WITH inserted_question AS (
  INSERT INTO questions (
    text,
    explanation,
    question_type,
    difficulty,
    statistics
  ) VALUES (
    'A nurse is teaching a client about breast self-examination (BSE). Which statements should the nurse include? Select all that apply.',
    jsonb_build_object(
      'correct', jsonb_build_array(
        'BSE should be performed at the same time each month, about 7-10 days after menstruation begins.',
        'The examination should be performed both lying down and standing up.',
        'Any new lumps, changes in breast size/shape, or nipple discharge should be reported to healthcare provider.'
      ),
      'incorrect', jsonb_build_array(
        'BSE is not recommended for women over 65 years old.',
        'BSE should be performed only when experiencing breast pain.'
      )
    ),
    'select_all',
    'medium',
    jsonb_build_object(
      'clientNeedArea', 'Health Promotion and Maintenance',
      'clientNeedTopic', 'Health Screening',
      'timeTaken', '2:30',
      'avgPeerScore', '78%',
      'difficulty', 'MEDIUM'
    )
  )
  RETURNING id
),
area_id AS (
  SELECT id FROM client_needs_areas WHERE name = 'Health Promotion and Maintenance' LIMIT 1
)
INSERT INTO question_options (question_id, text, is_correct, order_index)
SELECT 
  (SELECT id FROM inserted_question),
  unnest(ARRAY[
    'BSE should be performed at the same time each month, about 7-10 days after menstruation begins.',
    'The examination should be performed both lying down and standing up.',
    'Any new lumps, changes in breast size/shape, or nipple discharge should be reported to healthcare provider.',
    'BSE is not recommended for women over 65 years old.',
    'BSE should be performed only when experiencing breast pain.'
  ]),
  unnest(ARRAY[true, true, true, false, false]),
  generate_series(1, 5);

-- Question 4: Psychosocial Integrity - Multiple Choice
WITH inserted_question AS (
  INSERT INTO questions (
    text,
    explanation,
    question_type,
    difficulty,
    statistics
  ) VALUES (
    'A client diagnosed with major depression states, "I''m worthless and everyone would be better off without me." Which is the most appropriate initial nursing response?',
    jsonb_build_object(
      'correct', jsonb_build_array(
        'This response directly addresses the client''s suicidal ideation while showing concern and encouraging further discussion. It helps assess the severity of the client''s thoughts and establishes therapeutic communication.'
      ),
      'incorrect', jsonb_build_array(
        'Telling the client they have much to live for minimizes their feelings and may shut down communication.',
        'Immediately calling for help without assessment may break trust and therapeutic relationship.',
        'Changing the subject avoids addressing the serious nature of the client''s statement.'
      )
    ),
    'multiple_choice',
    'medium',
    jsonb_build_object(
      'clientNeedArea', 'Psychosocial Integrity',
      'clientNeedTopic', 'Crisis Intervention',
      'timeTaken', '1:45',
      'avgPeerScore', '72%',
      'difficulty', 'MEDIUM'
    )
  )
  RETURNING id
),
area_id AS (
  SELECT id FROM client_needs_areas WHERE name = 'Psychosocial Integrity' LIMIT 1
)
INSERT INTO question_options (question_id, text, is_correct, order_index)
SELECT 
  (SELECT id FROM inserted_question),
  unnest(ARRAY[
    'Tell me more about these thoughts. Are you thinking about hurting yourself?',
    'You have so much to live for. Think about your family.',
    'I need to call your doctor right away.',
    'Let''s talk about your plans for when you leave the hospital.'
  ]),
  unnest(ARRAY[true, false, false, false]),
  generate_series(1, 4);

-- Question 5: Basic Care and Comfort - Multiple Choice
WITH inserted_question AS (
  INSERT INTO questions (
    text,
    explanation,
    question_type,
    difficulty,
    statistics
  ) VALUES (
    'A nurse is caring for a client who has been NPO for 24 hours. Which assessment finding should be reported to the healthcare provider immediately?',
    jsonb_build_object(
      'correct', jsonb_build_array(
        'Urine output less than 30 mL/hr indicates potential dehydration and requires immediate intervention. Normal adult urine output should be at least 0.5 mL/kg/hr.'
      ),
      'incorrect', jsonb_build_array(
        'Dry oral mucosa is an expected finding in an NPO patient.',
        'Slight thirst is normal when NPO.',
        'Clear urine indicates adequate hydration from IV fluids.'
      )
    ),
    'multiple_choice',
    'medium',
    jsonb_build_object(
      'clientNeedArea', 'Basic Care and Comfort',
      'clientNeedTopic', 'Nutrition and Oral Hydration',
      'timeTaken', '1:30',
      'avgPeerScore', '85%',
      'difficulty', 'MEDIUM'
    )
  )
  RETURNING id
),
area_id AS (
  SELECT id FROM client_needs_areas WHERE name = 'Basic Care and Comfort' LIMIT 1
)
INSERT INTO question_options (question_id, text, is_correct, order_index)
SELECT 
  (SELECT id FROM inserted_question),
  unnest(ARRAY[
    'Urine output of 25 mL/hr',
    'Dry oral mucosa',
    'Reports of thirst',
    'Clear urine'
  ]),
  unnest(ARRAY[true, false, false, false]),
  generate_series(1, 4);

-- Question 6: Pharmacological Therapies - SATA
WITH inserted_question AS (
  INSERT INTO questions (
    text,
    explanation,
    question_type,
    difficulty,
    statistics
  ) VALUES (
    'A nurse is preparing to administer warfarin (Coumadin). Which assessments should be performed before administration? Select all that apply.',
    jsonb_build_object(
      'correct', jsonb_build_array(
        'The most recent PT/INR must be checked as it indicates the blood''s clotting ability.',
        'Signs of bleeding must be assessed as warfarin increases bleeding risk.',
        'Recent medication changes could affect warfarin''s effectiveness.'
      ),
      'incorrect', jsonb_build_array(
        'Blood pressure is not directly related to warfarin administration.',
        'Lung sounds are not specifically related to warfarin administration.'
      )
    ),
    'select_all',
    'medium',
    jsonb_build_object(
      'clientNeedArea', 'Pharmacological Therapies',
      'clientNeedTopic', 'Medication Administration',
      'timeTaken', '2:15',
      'avgPeerScore', '76%',
      'difficulty', 'MEDIUM'
    )
  )
  RETURNING id
),
area_id AS (
  SELECT id FROM client_needs_areas WHERE name = 'Pharmacological Therapies' LIMIT 1
)
INSERT INTO question_options (question_id, text, is_correct, order_index)
SELECT 
  (SELECT id FROM inserted_question),
  unnest(ARRAY[
    'Check most recent PT/INR result',
    'Assess for signs of bleeding',
    'Review medication changes',
    'Check blood pressure',
    'Auscultate lung sounds'
  ]),
  unnest(ARRAY[true, true, true, false, false]),
  generate_series(1, 5);

-- Question 7: Reduction of Risk Potential - Multiple Choice
WITH inserted_question AS (
  INSERT INTO questions (
    text,
    explanation,
    question_type,
    difficulty,
    statistics
  ) VALUES (
    'A client''s serum potassium level is 6.5 mEq/L. Which ECG change should the nurse expect to observe?',
    jsonb_build_object(
      'correct', jsonb_build_array(
        'Peaked T waves are the earliest ECG change seen in hyperkalemia. As potassium levels rise above 5.5 mEq/L, T waves become tall and peaked.'
      ),
      'incorrect', jsonb_build_array(
        'Flattened T waves are associated with hypokalemia.',
        'Prolonged PR interval is not a typical early sign of hyperkalemia.',
        'ST segment elevation is not characteristic of hyperkalemia.'
      )
    ),
    'multiple_choice',
    'medium',
    jsonb_build_object(
      'clientNeedArea', 'Reduction of Risk Potential',
      'clientNeedTopic', 'Lab Values',
      'timeTaken', '1:45',
      'avgPeerScore', '68%',
      'difficulty', 'MEDIUM'
    )
  )
  RETURNING id
),
area_id AS (
  SELECT id FROM client_needs_areas WHERE name = 'Reduction of Risk Potential' LIMIT 1
)
INSERT INTO question_options (question_id, text, is_correct, order_index)
SELECT 
  (SELECT id FROM inserted_question),
  unnest(ARRAY[
    'Peaked T waves',
    'Flattened T waves',
    'Prolonged PR interval',
    'ST segment elevation'
  ]),
  unnest(ARRAY[true, false, false, false]),
  generate_series(1, 4);

-- Question 8: Physiological Adaptation - SATA
WITH inserted_question AS (
  INSERT INTO questions (
    text,
    explanation,
    question_type,
    difficulty,
    statistics
  ) VALUES (
    'A client is admitted with diabetic ketoacidosis (DKA). Which assessment findings would the nurse expect? Select all that apply.',
    jsonb_build_object(
      'correct', jsonb_build_array(
        'Kussmaul respirations are a compensatory mechanism for metabolic acidosis.',
        'Polyuria occurs as a result of osmotic diuresis from hyperglycemia.',
        'Fruity breath odor is caused by ketone production.',
        'Excessive thirst results from fluid loss and hyperglycemia.'
      ),
      'incorrect', jsonb_build_array(
        'Bradycardia is not associated with DKA; tachycardia is more common.'
      )
    ),
    'select_all',
    'medium',
    jsonb_build_object(
      'clientNeedArea', 'Physiological Adaptation',
      'clientNeedTopic', 'Illness Management',
      'timeTaken', '2:30',
      'avgPeerScore', '74%',
      'difficulty', 'MEDIUM'
    )
  )
  RETURNING id
),
area_id AS (
  SELECT id FROM client_needs_areas WHERE name = 'Physiological Adaptation' LIMIT 1
)
INSERT INTO question_options (question_id, text, is_correct, order_index)
SELECT 
  (SELECT id FROM inserted_question),
  unnest(ARRAY[
    'Kussmaul respirations',
    'Polyuria',
    'Fruity breath odor',
    'Excessive thirst',
    'Bradycardia'
  ]),
  unnest(ARRAY[true, true, true, true, false]),
  generate_series(1, 5);