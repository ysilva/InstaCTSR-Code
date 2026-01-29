CREATE TEMP TABLE role_counts AS
WITH raw_comment_role_counts AS (
  SELECT
      comment_id,
      CASE
          WHEN bullying_role = 'non_aggressive_victim'
              THEN 'Non-Agg Victim'
          WHEN bullying_role = 'bully_assistant'
              THEN 'Bully Assist'
          WHEN bullying_role = 'passive_bystander'
              THEN 'Bystander'
          WHEN bullying_role = 'bully'
              THEN 'Bully'
          WHEN bullying_role = 'aggressive_defender'
              THEN 'Agg Defender'
          WHEN bullying_role = 'non_aggressive_defender'
              THEN 'Non-Agg Defender'
          WHEN bullying_role = 'aggressive_victim'
              THEN 'Agg Victim'
          ELSE 'Error in When-Then'
      END AS renamed_bullying_role,
      COUNT(*) AS role_annotation_count
  FROM mturk.comment_annotations
  GROUP BY comment_id, renamed_bullying_role
),

map_inconclusive AS (
  SELECT
      comment_id,
      role_annotation_count,
      CASE
          WHEN role_annotation_count < 3
              THEN 'Inconclusive'
          ELSE renamed_bullying_role
      END AS bullying_role
  FROM raw_comment_role_counts
),

sum_inconclusive AS (
  SELECT
      comment_id,
      bullying_role,
      sum(role_annotation_count) AS role_annotation_count
  FROM map_inconclusive
  GROUP BY comment_id, bullying_role
),

selecting_counts AS (
  SELECT *,
    row_number() OVER (
    PARTITION BY comment_id
    ORDER BY role_annotation_count DESC) AS reverse_row_count
  FROM sum_inconclusive
),

select_one_role_per_count AS (
  SELECT *
  FROM selecting_counts
  WHERE reverse_row_count = 1
),

count_comments_with_role AS (
  SELECT
      bullying_role,
      count(*) AS role_count,
      sum(count(*)) OVER () AS total_comment,
      ROUND(100.0 * count(*) / (sum(count(*)) OVER ()), 1) AS percentage
  FROM select_one_role_per_count
  GROUP BY bullying_role
)

SELECT *, role_count || ' (' || percentage || '\%)' AS label
FROM count_comments_with_role
ORDER BY role_count DESC;


SELECT *
FROM role_counts;

\copy role_counts TO '/tmp/role_counts.txt' With CSV DELIMITER ',' HEADER;
