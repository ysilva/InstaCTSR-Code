/*
CREATE TEMP TABLE comment_topics AS
SELECT
    annotation.comment_id,
    CASE
        WHEN topics.topic IS NULL THEN 'No Topic'
        WHEN topics.topic = 'topic' THEN 'Topic'
        WHEN topics.topic = 'none' THEN 'Other'
        WHEN topics.topic = 'religious' THEN 'Religious'
        WHEN topics.topic = 'race' THEN 'Race'
        WHEN topics.topic = 'social_status' THEN 'Social Status'
        WHEN topics.topic = 'intellectual' THEN 'Intellectual'
        WHEN topics.topic = 'disability' THEN 'Disability'
        WHEN topics.topic = 'sexual' THEN 'Sexual'
        WHEN topics.topic = 'physical' THEN 'Physical'
        WHEN topics.topic = 'gender' THEN 'Gender'
        WHEN topics.topic = 'political' THEN 'Political'
        ELSE 'Error in When-Then'
    END AS topic,
    COUNT(*) AS topic_annotation_count
FROM mturk.comment_annotations AS annotation
INNER JOIN mturk.comment_topics AS topics
    ON annotation.comment_id = topics.comment_id
    AND annotation.assignment_id = topics.assignment_id
GROUP BY annotation.comment_id, topic
HAVING topic_annotation_count >= 3;

CREATE TEMP TABLE annotation_comments AS
SELECT
    comment_id,
    CASE
        WHEN bullying_severity = 'mild'
            THEN 'Mild'
        WHEN bullying_severity = 'moderate'
            THEN 'Moderate'
        WHEN bullying_severity = 'severe'
            THEN 'Severe'
        WHEN bullying_severity IS NULL
            THEN 'No Severity'
        ELSE 'Erorr in When-Then'
    END AS bullying_severity,
    COUNT(*) AS severity_annotation_counts
FROM mturk.comment_annotations
GROUP BY comment_id, bullying_severity
QUALIFY row_number() OVER (
  PARTITION BY comment_id
  ORDER BY severity_annotation_counts DESC) = 1;


CREATE TEMP TABLE severity_majority AS
SELECT
    comment_id,
    CASE
        WHEN severity_annotation_counts < 3
            THEN 'Inconclusive'
        ELSE bullying_severity
    END AS bullying_severity
FROM annotation_comments;

*/ 
CREATE TEMP TABLE topic_heat_map AS
WITH raw_comment_severity_counts AS (
  SELECT
      comment_id,
      CASE
          WHEN bullying_severity = 'mild'
              THEN 'Mild'
          WHEN bullying_severity = 'moderate'
              THEN 'Moderate'
          WHEN bullying_severity = 'severe'
              THEN 'Severe'
          WHEN bullying_severity IS NULL
              THEN 'No Severity'
          ELSE 'Erorr in When-Then'
      END AS renamed_bullying_severity,
      count(*) AS severity_annotation_count
  FROM mturk.comment_annotations
  GROUP BY comment_id, renamed_bullying_severity
),

severity_map_inconclusive AS (
  SELECT
      comment_id,
      severity_annotation_count,
      CASE
          WHEN severity_annotation_count < 3
              THEN 'Inconclusive'
          ELSE renamed_bullying_severity
      END AS bullying_severity
  FROM raw_comment_severity_counts
),

severity_sum_inconclusive AS (
  SELECT
      comment_id,
      bullying_severity,
      sum(severity_annotation_count) AS severity_annotation_count
  FROM severity_map_inconclusive
  GROUP BY comment_id, bullying_severity
),

severity_selecting_counts AS (
  SELECT *,
    row_number() OVER (
      PARTITION BY comment_id
      ORDER BY severity_annotation_count DESC) AS reverse_row_count
  FROM severity_sum_inconclusive
),

select_one_severity_per_count AS (
  SELECT *
  FROM severity_selecting_counts
  WHERE reverse_row_count = 1
),

raw_comment_topic_counts AS (
  SELECT
      annotation.comment_id,
      CASE
          WHEN topics.topic IS NULL THEN 'No Topic'
          WHEN topics.topic = 'disability' THEN 'Disability'
          WHEN topics.topic = 'gender' THEN 'Gender'
          WHEN topics.topic = 'intellectual' THEN 'Intellectual'
          WHEN topics.topic = 'none' THEN 'Other'
          WHEN topics.topic = 'physical' THEN 'Physical'
          WHEN topics.topic = 'political' THEN 'Political'
          WHEN topics.topic = 'race' THEN 'Race'
          WHEN topics.topic = 'religious' THEN 'Religious'
          WHEN topics.topic = 'sexual' THEN 'Sexual'
          WHEN topics.topic = 'social_status' THEN 'Social Status'
      ELSE 'Error in When-Then'
      END AS topic,
      count(*) AS topic_annotation_count
  FROM mturk.comment_annotations AS annotation
  LEFT JOIN mturk.comment_topics AS topics
    ON annotation.comment_id = topics.comment_id
    AND annotation.assignment_id = topics.assignment_id
  GROUP BY annotation.comment_id, topic
  HAVING count(*) >= 3
)

SELECT topic.topic, severity.bullying_severity, count(*) AS count
FROM select_one_severity_per_count AS severity
INNER JOIN raw_comment_topic_counts AS topic
    ON severity.comment_id = topic.comment_id
WHERE severity.reverse_row_count = 1 
  AND severity.bullying_severity  <> 'No Severity'
GROUP BY topic.topic, severity.bullying_severity;

SELECT *
FROM topic_heat_map
ORDER BY sum(count) OVER (PARTITION BY topic) DESC, bullying_severity;

\copy topic_heat_map TO '/tmp/topic_heat_map.txt' With CSV DELIMITER ',' HEADER;
