-- Insert additional NCLEX questions

-- Question 9: Management of Care - SATA
WITH inserted_question AS (
  INSERT INTO questions (
    text,
    explanation,
    question_type,
    difficulty,
    statistics
  ) VALUES (
    'A charge nurse is assigning tasks to team members. Which tasks are appropriate to delegate to a licensed practical nurse (LPN)? Select all that apply.',
    jsonb_build_object(
      'correct', jsonb_build_array(
        'Administering oral medications is within the LPN scope of practice.',
        'Changing sterile dressings is within the LPN scope of practice.',
        'Documenting vital signs is within the LPN scope of practice.'
      ),
      'incorrect', jsonb_build_array(
        'Initial patient assessment must be performed by an RN.',
        'Care planning requires RN assessment and judgment.'
      )
    ),
    'select_all',
    'medium',
    jsonb_build_object(
      'clientNeedArea', 'Management of Care',
      'clientNeedTopic', 'Assignment and Delegation',
      'timeTaken', '2:00',
      'avgPeerScore', '75%',
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
    'Administering oral medications',
    'Changing sterile dressings',
    'Documenting vital signs',
    'Performing initial patient assessment',
    'Developing the nursing care plan'
  ]),
  unnest(ARRAY[true, true, true, false, false]),
  generate_series(1, 5);

-- Question 10: Safety and Infection Control - Multiple Choice
WITH inserted_question AS (
  INSERT INTO questions (
    text,
    explanation,
    question_type,
    difficulty,
    statistics
  ) VALUES (
    'A nurse is caring for a client with neutropenia. Which intervention has the highest priority for preventing infection?',
    jsonb_build_object(
      'correct', jsonb_build_array(
        'Hand hygiene is the most effective method for preventing the spread of infection. This is especially critical for immunocompromised clients with neutropenia.'
      ),
      'incorrect', jsonb_build_array(
        'While important, maintaining a private room is not the highest priority.',
        'Wearing a mask is important but not the highest priority measure.',
        'Restricting flowers is important but not the highest priority intervention.'
      )
    ),
    'multiple_choice',
    'medium',
    jsonb_build_object(
      'clientNeedArea', 'Safety and Infection Control',
      'clientNeedTopic', 'Standard Precautions',
      'timeTaken', '1:30',
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
    'Performing hand hygiene before entering the room',
    'Placing the client in a private room',
    'Wearing a mask when entering the room',
    'Restricting fresh flowers in the room'
  ]),
  unnest(ARRAY[true, false, false, false]),
  generate_series(1, 4);

-- Question 11: Health Promotion and Maintenance - Multiple Choice
WITH inserted_question AS (
  INSERT INTO questions (
    text,
    explanation,
    question_type,
    difficulty,
    statistics
  ) VALUES (
    'A nurse is teaching a client about lifestyle modifications to reduce the risk of cardiovascular disease. Which client statement indicates understanding of the teaching?',
    jsonb_build_object(
      'correct', jsonb_build_array(
        'Regular aerobic exercise for 30 minutes most days of the week is recommended for cardiovascular health and disease prevention.'
      ),
      'incorrect', jsonb_build_array(
        'Weight training alone is not the most effective for cardiovascular health.',
        'Walking once a week is insufficient for cardiovascular benefits.',
        'Exercise intensity that prevents conversation is too strenuous.'
      )
    ),
    'multiple_choice',
    'medium',
    jsonb_build_object(
      'clientNeedArea', 'Health Promotion and Maintenance',
      'clientNeedTopic', 'Lifestyle Choices',
      'timeTaken', '1:45',
      'avgPeerScore', '79%',
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
    'I will walk briskly for 30 minutes five days a week',
    'I will do weight training exercises every day',
    'I will walk for one hour once a week',
    'I will exercise until I cannot carry on a conversation'
  ]),
  unnest(ARRAY[true, false, false, false]),
  generate_series(1, 4);

-- Question 12: Psychosocial Integrity - SATA
WITH inserted_question AS (
  INSERT INTO questions (
    text,
    explanation,
    question_type,
    difficulty,
    statistics
  ) VALUES (
    'A nurse is caring for a client experiencing anxiety. Which interventions are appropriate? Select all that apply.',
    jsonb_build_object(
      'correct', jsonb_build_array(
        'Speaking in a calm, reassuring manner helps reduce anxiety.',
        'Remaining with the client provides support and security.',
        'Simple, clear explanations help reduce confusion and anxiety.',
        'Teaching deep breathing techniques helps reduce anxiety symptoms.'
      ),
      'incorrect', jsonb_build_array(
        'Telling a client to calm down may minimize their feelings and increase anxiety.'
      )
    ),
    'select_all',
    'medium',
    jsonb_build_object(
      'clientNeedArea', 'Psychosocial Integrity',
      'clientNeedTopic', 'Coping Mechanisms',
      'timeTaken', '2:15',
      'avgPeerScore', '77%',
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
    'Speak in a calm, reassuring manner',
    'Remain with the client',
    'Provide simple, clear explanations',
    'Teach deep breathing techniques',
    'Tell the client to calm down'
  ]),
  unnest(ARRAY[true, true, true, true, false]),
  generate_series(1, 5);