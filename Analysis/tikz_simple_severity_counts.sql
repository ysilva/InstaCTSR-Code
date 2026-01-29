CREATE TEMP TABLE severity_counts AS
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

map_inconclusive AS (
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

sum_inconclusive AS (
  SELECT
      comment_id,
      bullying_severity,
      sum(severity_annotation_count) AS severity_annotation_count
  FROM map_inconclusive
  GROUP BY comment_id, bullying_severity
),

selecting_counts AS (
  SELECT *,
    row_number() OVER (
      PARTITION BY comment_id
      ORDER BY severity_annotation_count DESC) AS reverse_row_count
  FROM sum_inconclusive
),

select_one_role_per_count AS (
  SELECT *
  FROM selecting_counts
  WHERE reverse_row_count = 1
),

count_comments_with_severity AS (
  SELECT
      bullying_severity,
      count(*) AS severity_count,
      sum(count(*)) OVER () AS total_comment,
      ROUND(100.0 * count(*) / (sum(count(*)) OVER ()), 1) AS percentage
  FROM select_one_role_per_count
  GROUP BY bullying_severity
)
SELECT *, severity_count || ' (' || percentage || '\%)' AS label
FROM count_comments_with_severity
ORDER BY severity_count DESC;

SELECT *
FROM severity_counts;

\copy severity_counts TO '/tmp/severity_counts.txt' With CSV DELIMITER ',' HEADER;
