-- Insert additional NCLEX questions

-- Question 17: Management of Care - Multiple Choice
WITH inserted_question AS (
  INSERT INTO questions (
    text,
    explanation,
    question_type,
    difficulty,
    statistics
  ) VALUES (
    'A nurse is caring for 6 clients on a medical-surgical unit. Which client should the nurse assess first?',
    jsonb_build_object(
      'correct', jsonb_build_array(
        'A client with new onset chest pain requires immediate assessment as it could indicate a life-threatening condition such as myocardial infarction or pulmonary embolism.'
      ),
      'incorrect', jsonb_build_array(
        'While important, scheduled medications can wait briefly for a more urgent situation.',
        'Routine vital signs can be delayed for a more urgent situation.',
        'Discharge teaching can be delayed for a more urgent situation.'
      )
    ),
    'multiple_choice',
    'medium',
    jsonb_build_object(
      'clientNeedArea', 'Management of Care',
      'clientNeedTopic', 'Establishing Priorities',
      'timeTaken', '1:45',
      'avgPeerScore', '82%',
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
    'Client reporting new onset chest pain',
    'Client due for scheduled medications',
    'Client needing routine vital signs',
    'Client awaiting discharge teaching'
  ]),
  unnest(ARRAY[true, false, false, false]),
  generate_series(1, 4);

-- Question 18: Safety and Infection Control - SATA
WITH inserted_question AS (
  INSERT INTO questions (
    text,
    explanation,
    question_type,
    difficulty,
    statistics
  ) VALUES (
    'A nurse is implementing fall precautions for a client. Which interventions should be included? Select all that apply.',
    jsonb_build_object(
      'correct', jsonb_build_array(
        'Keeping the bed in the lowest position reduces injury risk if a fall occurs.',
        'Ensuring the call light is within reach allows the client to call for assistance.',
        'Using non-slip footwear helps prevent falls when ambulating.',
        'Keeping personal items within reach reduces the need for risky reaching or stretching.'
      ),
      'incorrect', jsonb_build_array(
        'Raising all side rails can create an entrapment hazard and may increase fall risk if the client attempts to climb over them.'
      )
    ),
    'select_all',
    'medium',
    jsonb_build_object(
      'clientNeedArea', 'Safety and Infection Control',
      'clientNeedTopic', 'Accident/Error/Injury Prevention',
      'timeTaken', '2:00',
      'avgPeerScore', '88%',
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
    'Keep bed in lowest position',
    'Ensure call light is within reach',
    'Provide non-slip footwear',
    'Keep personal items within reach',
    'Raise all side rails'
  ]),
  unnest(ARRAY[true, true, true, true, false]),
  generate_series(1, 5);

-- Question 19: Health Promotion and Maintenance - Multiple Choice
WITH inserted_question AS (
  INSERT INTO questions (
    text,
    explanation,
    question_type,
    difficulty,
    statistics
  ) VALUES (
    'A nurse is teaching a client about osteoporosis prevention. Which statement by the client indicates understanding of the teaching?',
    jsonb_build_object(
      'correct', jsonb_build_array(
        'Weight-bearing exercises combined with adequate calcium and vitamin D intake are essential for maintaining bone density and preventing osteoporosis.'
      ),
      'incorrect', jsonb_build_array(
        'Swimming is not a weight-bearing exercise.',
        'Calcium alone without vitamin D is not as effective.',
        'Walking alone without strength training is not optimal.'
      )
    ),
    'multiple_choice',
    'medium',
    jsonb_build_object(
      'clientNeedArea', 'Health Promotion and Maintenance',
      'clientNeedTopic', 'Health Promotion/Disease Prevention',
      'timeTaken', '1:30',
      'avgPeerScore', '81%',
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
    'I will do weight-bearing exercises and take calcium with vitamin D daily',
    'I will swim laps three times a week',
    'I will take calcium supplements alone',
    'I will walk for 30 minutes daily'
  ]),
  unnest(ARRAY[true, false, false, false]),
  generate_series(1, 4);

-- Question 20: Psychosocial Integrity - SATA
WITH inserted_question AS (
  INSERT INTO questions (
    text,
    explanation,
    question_type,
    difficulty,
    statistics
  ) VALUES (
    'A nurse is caring for a client experiencing grief. Which interventions are appropriate? Select all that apply.',
    jsonb_build_object(
      'correct', jsonb_build_array(
        'Active listening demonstrates support and allows the client to express feelings.',
        'Allowing silence gives the client time to process emotions and gather thoughts.',
        'Encouraging expression of feelings helps with the grieving process.',
        'Providing presence shows support and availability.'
      ),
      'incorrect', jsonb_build_array(
        'Telling the client not to cry can invalidate their feelings and hinder the grieving process.'
      )
    ),
    'select_all',
    'medium',
    jsonb_build_object(
      'clientNeedArea', 'Psychosocial Integrity',
      'clientNeedTopic', 'Grief and Loss',
      'timeTaken', '2:15',
      'avgPeerScore', '83%',
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
    'Practice active listening',
    'Allow periods of silence',
    'Encourage expression of feelings',
    'Provide presence',
    'Tell client not to cry'
  ]),
  unnest(ARRAY[true, true, true, true, false]),
  generate_series(1, 5);