CREATE TEMP TABLE temp_final AS
WITH is_bullying AS (
    SELECT
        anons.comment_id,
        count(*) >= 3 AS cyberbullying
    FROM ctsr.mturk.comment_annotations AS anons
    INNER JOIN ctsr.instagram.comments
        ON anons.comment_id = comments.comment_id
    WHERE comments.comment_content <> ''
    GROUP BY anons.comment_id
),

assign_ranks_roles AS (
    SELECT
        anons.comment_id,
        anons.bullying_role,
        CASE
            WHEN bullying_role = 'bully_assistant'
                THEN 1
            WHEN bullying_role = 'aggressive_victim'
                THEN 2
            WHEN bullying_role = 'non_aggressive_victim'
                THEN 3
            WHEN bullying_role = 'non_aggressive_defender'
                THEN 4
            WHEN bullying_role = 'aggressive_defender'
                THEN 5
            WHEN bullying_role = 'bully'
                THEN 6
            ELSE 7
        END AS role_over_rule
    FROM ctsr.mturk.comment_annotations AS anons
    INNER JOIN ctsr.instagram.comments
        ON anons.comment_id = comments.comment_id
    WHERE comments.comment_content <> ''

),

count_role_votes AS (
    SELECT
        comment_id,
        bullying_role,
        role_over_rule,
        count(*) AS role_votes
    FROM assign_ranks_roles
    GROUP BY comment_id, bullying_role, role_over_rule
),

dense_rank_role_votes AS (
    SELECT
        *,
        dense_rank()
            OVER (
                PARTITION BY comment_id ORDER BY role_votes DESC, role_over_rule
            )
            AS roles_preferenced
    FROM count_role_votes
),

assign_ranks_severity AS (
    SELECT
        anons.comment_id,
        coalesce(anons.bullying_severity, 'no_severity') AS bullying_severity,
        CASE
            WHEN anons.bullying_severity IS NULL
                THEN 4 
            WHEN anons.bullying_severity = 'mild'
                THEN 3
            WHEN anons.bullying_severity = 'moderate'
                THEN 2
            WHEN anons.bullying_severity = 'severe'
                THEN 1
            ELSE 5
        END AS severity_over_rule
    FROM ctsr.mturk.comment_annotations AS anons
    INNER JOIN ctsr.instagram.comments
        ON anons.comment_id = comments.comment_id
    WHERE comments.comment_content <> ''

),

count_severity_votes AS (
    SELECT
        comment_id,
        bullying_severity,
        severity_over_rule,
        count(*) AS severity_votes
    FROM assign_ranks_severity
    GROUP BY comment_id, bullying_severity, severity_over_rule
),

dense_rank_severity_votes AS (
    SELECT
        *,
        dense_rank()
            OVER (
                PARTITION BY comment_id ORDER BY severity_votes DESC, severity_over_rule
            )
            AS severity_preferenced
    FROM count_severity_votes
),

race_topic AS (
  SELECT 
    topics.comment_id,
    COUNT(*) >= 3 AS has_race
  FROM instagram.comments
  LEFT JOIN mturk.comment_topics AS topics
    ON comments.comment_id = topics.comment_id
    AND topics.topic = 'race'
  GROUP BY topics.comment_id
),

political_topic AS (
  SELECT 
    topics.comment_id,
    COUNT(*) >= 3 AS has_political
  FROM instagram.comments
  LEFT JOIN mturk.comment_topics AS topics
    ON comments.comment_id = topics.comment_id
    AND topics.topic = 'political'
  GROUP BY topics.comment_id
),

intellectual_topic AS (
  SELECT 
    topics.comment_id,
    COUNT(*) >= 3 AS has_intellectual
  FROM instagram.comments
  LEFT JOIN mturk.comment_topics AS topics
    ON comments.comment_id = topics.comment_id
    AND topics.topic = 'intellectual'
  GROUP BY topics.comment_id
),

physical_topic AS (
  SELECT 
    topics.comment_id,
    COUNT(*) >= 3 AS has_physical
  FROM instagram.comments
  LEFT JOIN mturk.comment_topics AS topics
    ON comments.comment_id = topics.comment_id
    AND topics.topic = 'physical'
  GROUP BY topics.comment_id
),

social_status_topic AS (
  SELECT 
    topics.comment_id,
    COUNT(*) >= 3 AS has_social_status
  FROM instagram.comments
  LEFT JOIN mturk.comment_topics AS topics
    ON comments.comment_id = topics.comment_id
    AND topics.topic = 'social_status'
  GROUP BY topics.comment_id
),

gender_topic AS (
  SELECT 
    topics.comment_id,
    COUNT(*) >= 3 AS has_gender
  FROM instagram.comments
  LEFT JOIN mturk.comment_topics AS topics
    ON comments.comment_id = topics.comment_id
    AND topics.topic = 'gender'
  GROUP BY topics.comment_id
),

none_topic AS (
  SELECT 
    topics.comment_id,
    COUNT(*) >= 3 AS has_none
  FROM instagram.comments
  LEFT JOIN mturk.comment_topics AS topics
    ON comments.comment_id = topics.comment_id
    AND topics.topic = 'none'
  GROUP BY topics.comment_id
),

religious_topic AS (
  SELECT 
    topics.comment_id,
    COUNT(*) >= 3 AS has_religious
  FROM instagram.comments
  LEFT JOIN mturk.comment_topics AS topics
    ON comments.comment_id = topics.comment_id
    AND topics.topic = 'religious'
  GROUP BY topics.comment_id
),

disability_topic AS (
  SELECT 
    topics.comment_id,
    COUNT(*) >= 3 AS has_disability
  FROM instagram.comments
  LEFT JOIN mturk.comment_topics AS topics
    ON comments.comment_id = topics.comment_id
    AND topics.topic = 'disability'
  GROUP BY topics.comment_id
),

sexual_topic AS (
  SELECT 
    topics.comment_id,
    COUNT(*) >= 3 AS has_sexual
  FROM instagram.comments
  LEFT JOIN mturk.comment_topics AS topics
    ON comments.comment_id = topics.comment_id
    AND topics.topic = 'sexual'
  GROUP BY topics.comment_id
),

final AS (
  SELECT
    cmnts.unit_id,
    cmnts.comment_id,
    cmnts.comment_content,
    COALESCE(bullying.cyberbullying, FALSE) AS cyberbullying,
    COALESCE(role.bullying_role, 'passive_bystander') AS bullying_role,
    COALESCE(severity.bullying_severity, 'no_severity') AS bullying_severity,
    COALESCE(race.has_race, FALSE) AS has_race,
    COALESCE(political.has_political, FALSE) AS has_political,
    COALESCE(intellectual.has_intellectual, FALSE) AS has_intellectual,
    COALESCE(physical.has_physical, FALSE) AS has_physical,
    COALESCE(social_status.has_social_status, FALSE) AS has_social_status,
    COALESCE(gender.has_gender, FALSE) AS has_gender,
    COALESCE(none.has_none, FALSE) AS has_none,
    COALESCE(religious.has_religious, FALSE) AS has_religious,
    COALESCE(disability.has_disability, FALSE) AS has_disability,
    COALESCE(sexual.has_sexual, FALSE) AS has_sexual
  FROM instagram.comments AS cmnts
  LEFT JOIN is_bullying AS bullying
    ON cmnts.comment_id = bullying.comment_id
  LEFT JOIN dense_rank_role_votes AS role 
    ON cmnts.comment_id = role.comment_id 
    AND role.roles_preferenced = 1
  LEFT JOIN dense_rank_severity_votes AS severity
    ON cmnts.comment_id = severity.comment_id
    AND severity.severity_preferenced = 1
  LEFT JOIN race_topic AS race
    ON cmnts.comment_id = race.comment_id
  LEFT JOIN political_topic AS political
    ON cmnts.comment_id = political.comment_id
  LEFT JOIN intellectual_topic AS intellectual
    ON cmnts.comment_id = intellectual.comment_id
  LEFT JOIN physical_topic AS physical
    ON cmnts.comment_id = physical.comment_id
  LEFT JOIN social_status_topic AS social_status
    ON cmnts.comment_id = social_status.comment_id
  LEFT JOIN gender_topic AS gender
    ON cmnts.comment_id = gender.comment_id
  LEFT JOIN none_topic AS none
    ON cmnts.comment_id = none.comment_id
  LEFT JOIN religious_topic AS religious
    ON cmnts.comment_id = religious.comment_id
  LEFT JOIN disability_topic AS disability
    ON cmnts.comment_id = disability.comment_id
  LEFT JOIN sexual_topic AS sexual
    ON cmnts.comment_id = sexual.comment_id
)

SELECT *
FROM final;

\copy temp_final TO '/tmp/ml_data.csv' WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',', QUOTE '"', ESCAPE '"', NULL '', ENCODING 'UTF8');

-- Check for duplicate comment_ids
SELECT comment_id, COUNT(*) AS cnt
FROM temp_final
GROUP BY comment_id
HAVING COUNT(*) > 1
ORDER BY cnt DESC;

-- Distribution of bullying_role
SELECT bullying_role, COUNT(*) AS cnt
FROM temp_final
GROUP BY bullying_role
ORDER BY cnt DESC;

-- Distribution of bullying_severity
SELECT bullying_severity, COUNT(*) AS cnt
FROM temp_final
GROUP BY bullying_severity
ORDER BY cnt DESC;

-- Distribution of has_race
SELECT has_race, COUNT(*) AS cnt
FROM temp_final
GROUP BY has_race
ORDER BY cnt DESC;

-- Distribution of has_political
SELECT has_political, COUNT(*) AS cnt
FROM temp_final
GROUP BY has_political
ORDER BY cnt DESC;

-- Distribution of has_intellectual
SELECT has_intellectual, COUNT(*) AS cnt
FROM temp_final
GROUP BY has_intellectual
ORDER BY cnt DESC;

-- Distribution of has_physical
SELECT has_physical, COUNT(*) AS cnt
FROM temp_final
GROUP BY has_physical
ORDER BY cnt DESC;

-- Distribution of has_social_status
SELECT has_social_status, COUNT(*) AS cnt
FROM temp_final
GROUP BY has_social_status
ORDER BY cnt DESC;

-- Distribution of has_gender
SELECT has_gender, COUNT(*) AS cnt
FROM temp_final
GROUP BY has_gender
ORDER BY cnt DESC;

-- Distribution of has_none
SELECT has_none, COUNT(*) AS cnt
FROM temp_final
GROUP BY has_none
ORDER BY cnt DESC;

-- Distribution of has_religious
SELECT has_religious, COUNT(*) AS cnt
FROM temp_final
GROUP BY has_religious
ORDER BY cnt DESC;

-- Distribution of has_disability
SELECT has_disability, COUNT(*) AS cnt
FROM temp_final
GROUP BY has_disability
ORDER BY cnt DESC;

-- Distribution of has_sexual
SELECT has_sexual, COUNT(*) AS cnt
FROM temp_final
GROUP BY has_sexual
ORDER BY cnt DESC;

