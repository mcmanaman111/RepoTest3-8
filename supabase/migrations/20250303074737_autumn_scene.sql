-- Insert additional NCLEX questions

-- Question 13: Basic Care and Comfort - Multiple Choice
WITH inserted_question AS (
  INSERT INTO questions (
    text,
    explanation,
    question_type,
    difficulty,
    statistics
  ) VALUES (
    'A nurse is caring for a client who has been immobile for 3 days. Which intervention is most important for preventing pressure ulcers?',
    jsonb_build_object(
      'correct', jsonb_build_array(
        'Regular repositioning every 2 hours is the most effective intervention for preventing pressure ulcers in immobile clients. This allows for relief of pressure on bony prominences and promotes circulation.'
      ),
      'incorrect', jsonb_build_array(
        'While important, moisturizing alone is not the most effective prevention method.',
        'Massage of bony prominences is contraindicated as it can cause tissue damage.',
        'While important, nutrition alone is not the most immediate intervention needed.'
      )
    ),
    'multiple_choice',
    'medium',
    jsonb_build_object(
      'clientNeedArea', 'Basic Care and Comfort',
      'clientNeedTopic', 'Mobility/Immobility',
      'timeTaken', '1:30',
      'avgPeerScore', '84%',
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
    'Reposition client every 2 hours',
    'Apply moisturizer to dry skin',
    'Massage bony prominences',
    'Provide high-protein supplements'
  ]),
  unnest(ARRAY[true, false, false, false]),
  generate_series(1, 4);

-- Question 14: Pharmacological Therapies - SATA
WITH inserted_question AS (
  INSERT INTO questions (
    text,
    explanation,
    question_type,
    difficulty,
    statistics
  ) VALUES (
    'A nurse is preparing to administer insulin. Which actions are appropriate? Select all that apply.',
    jsonb_build_object(
      'correct', jsonb_build_array(
        'Checking blood glucose before administration is essential for safe insulin therapy.',
        'Verifying the insulin type and dose against the order is a critical safety step.',
        'Rotating injection sites prevents lipohypertrophy and ensures consistent absorption.',
        'Documenting the site used helps ensure proper rotation of injection sites.'
      ),
      'incorrect', jsonb_build_array(
        'Massaging the injection site can affect insulin absorption and is not recommended.'
      )
    ),
    'select_all',
    'medium',
    jsonb_build_object(
      'clientNeedArea', 'Pharmacological Therapies',
      'clientNeedTopic', 'Medication Administration',
      'timeTaken', '2:15',
      'avgPeerScore', '79%',
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
    'Check blood glucose level',
    'Verify insulin type and dose',
    'Rotate injection sites',
    'Document injection site',
    'Massage the injection site'
  ]),
  unnest(ARRAY[true, true, true, true, false]),
  generate_series(1, 5);

-- Question 15: Reduction of Risk Potential - Multiple Choice
WITH inserted_question AS (
  INSERT INTO questions (
    text,
    explanation,
    question_type,
    difficulty,
    statistics
  ) VALUES (
    'A client''s arterial blood gas results show: pH 7.30, PaCO2 52 mmHg, HCO3 25 mEq/L. Which condition does this indicate?',
    jsonb_build_object(
      'correct', jsonb_build_array(
        'Elevated PaCO2 with normal HCO3 and decreased pH indicates respiratory acidosis. The elevated PaCO2 shows inadequate ventilation, while the normal HCO3 indicates no renal compensation yet.'
      ),
      'incorrect', jsonb_build_array(
        'In respiratory alkalosis, PaCO2 would be decreased.',
        'In metabolic acidosis, HCO3 would be decreased.',
        'In metabolic alkalosis, HCO3 would be elevated.'
      )
    ),
    'multiple_choice',
    'medium',
    jsonb_build_object(
      'clientNeedArea', 'Reduction of Risk Potential',
      'clientNeedTopic', 'Lab Values',
      'timeTaken', '2:00',
      'avgPeerScore', '71%',
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
    'Respiratory acidosis',
    'Respiratory alkalosis',
    'Metabolic acidosis',
    'Metabolic alkalosis'
  ]),
  unnest(ARRAY[true, false, false, false]),
  generate_series(1, 4);

-- Question 16: Physiological Adaptation - SATA
WITH inserted_question AS (
  INSERT INTO questions (
    text,
    explanation,
    question_type,
    difficulty,
    statistics
  ) VALUES (
    'A client is admitted with acute pancreatitis. Which assessment findings would the nurse expect to find? Select all that apply.',
    jsonb_build_object(
      'correct', jsonb_build_array(
        'Epigastric pain radiating to the back is a classic symptom of pancreatitis.',
        'Nausea and vomiting are common symptoms due to pancreatic inflammation.',
        'Elevated serum amylase and lipase levels are diagnostic indicators.',
        'Decreased bowel sounds occur due to pancreatic inflammation affecting nearby organs.'
      ),
      'incorrect', jsonb_build_array(
        'Increased appetite is not associated with acute pancreatitis; anorexia is more common.'
      )
    ),
    'select_all',
    'medium',
    jsonb_build_object(
      'clientNeedArea', 'Physiological Adaptation',
      'clientNeedTopic', 'Alterations in Body Systems',
      'timeTaken', '2:30',
      'avgPeerScore', '75%',
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
    'Epigastric pain radiating to the back',
    'Nausea and vomiting',
    'Elevated serum amylase and lipase',
    'Decreased bowel sounds',
    'Increased appetite'
  ]),
  unnest(ARRAY[true, true, true, true, false]),
  generate_series(1, 5);