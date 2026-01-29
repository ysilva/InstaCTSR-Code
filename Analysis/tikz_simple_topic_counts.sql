-- disability
-- gender
-- intellectual
-- none
-- physical
-- political
-- race
-- religious
-- sexual
-- social_status
CREATE TEMP TABLE topic_counts AS
WITH raw_comment_topic_counts AS (
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
),

count_comments_with_topic AS (
  SELECT
      topic,
      count(*) AS topic_count,
      sum(count(*)) OVER () AS total_comments,
      ROUND(100.0 * count(*) / sum(count(*)) OVER (), 1) AS percentage
  FROM raw_comment_topic_counts
  GROUP BY topic
)
SELECT *, topic_count || ' (' || percentage || '\%)' AS label
FROM count_comments_with_topic
ORDER BY topic_count DESC;

SELECT *
FROM topic_counts;

\copy topic_counts TO '/tmp/topic_counts.txt' With CSV DELIMITER ',' HEADER;
