CREATE TEMP TABLE time_roles_count AS
WITH role_names AS (
    SELECT DISTINCT bullying_role
    FROM mturk.comment_annotations
    UNION ALL
    SELECT 'inconclusive' AS bullying_role
),

role_filler AS (
  SELECT *
  FROM generate_series(1, 10) AS gen(comment_bucket)
  CROSS JOIN role_names
),

bucketed_comments AS (
    SELECT
        *,
        row_number()
            OVER (PARTITION BY unit_id ORDER BY comment_created_at)
            AS comment_number
    FROM instagram.comments
),

sequenced_comments AS (
    SELECT
        *,
        CASE
            WHEN comment_number <= 15 * 1
                THEN 1
            WHEN comment_number <= 15 * 2
                THEN 2
            WHEN comment_number <= 15 * 3
                THEN 3
            WHEN comment_number <= 15 * 4
                THEN 4
            WHEN comment_number <= 15 * 5
                THEN 5
            WHEN comment_number <= 15 * 6
                THEN 6
            WHEN comment_number <= 15 * 7
                THEN 7
            WHEN comment_number <= 15 * 8
                THEN 8
            WHEN comment_number <= 15 * 9
                THEN 9
            WHEN comment_number <= 15 * 10
                THEN 10
            WHEN comment_number <= 15 * 11
                THEN 11
            WHEN comment_number <= 15 * 12
                THEN 12
            WHEN comment_number <= 15 * 13
                THEN 13
            WHEN comment_number <= 15 * 14
                THEN 14
            WHEN comment_number <= 15 * 15
                THEN 15
            ELSE 16
        END AS comment_bucket,
        CASE
            WHEN comment_number <= 15 * 1
                THEN '{[1, 15]}'
            WHEN comment_number <= 15 * 2
                THEN '{(15, 30]}'
            WHEN comment_number <= 15 * 3
                THEN '{(30, 45]}'
            WHEN comment_number <= 15 * 4
                THEN '{(45, 60]}'
            WHEN comment_number <= 15 * 5
                THEN '{(60, 75]}'
            WHEN comment_number <= 15 * 6
                THEN '{(75, 90]}'
            WHEN comment_number <= 15 * 7
                THEN '{(90, 105]}'
            WHEN comment_number <= 15 * 8
                THEN '{(105, 120]}'
            WHEN comment_number <= 15 * 9
                THEN '{(120, 135]}'
            WHEN comment_number <= 15 * 10
                THEN '{(135, 150]}'
            WHEN comment_number <= 15 * 11
                THEN '{(150, 165]}'
            WHEN comment_number <= 15 * 12
                THEN '{(165, 180]}'
            WHEN comment_number <= 15 * 13
                THEN '{(180, 195]}'
            WHEN comment_number <= 15 * 14
                THEN '{(195, 210]}'
            WHEN comment_number <= 15 * 15
                THEN '{(210, 225]}'
            ELSE '{(225, ∞)}'
        END AS comment_bucket_display
    FROM bucketed_comments
),

raw_comment_role_counts AS (
    SELECT
        comment_id,
        bullying_role,
        count(*) AS role_annotation_count
    FROM mturk.comment_annotations
    GROUP BY comment_id, bullying_role
),

map_inconclusive AS (
    SELECT
        comment_id,
        role_annotation_count,
        CASE
            WHEN role_annotation_count < 3
                THEN 'inconclusive'
            ELSE bullying_role
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
    SELECT
        *,
        row_number() OVER (
            PARTITION BY comment_id
            ORDER BY role_annotation_count DESC
        ) AS reverse_row_count
    FROM sum_inconclusive
),

select_one_role_per_count AS (
    SELECT *
    FROM selecting_counts
    WHERE reverse_row_count = 1
),

count_comments_with_role AS (
    SELECT
        comments.comment_bucket,
        roles.bullying_role,
        count(*) AS role_count
    FROM select_one_role_per_count AS roles
    INNER JOIN sequenced_comments AS comments
        ON roles.comment_id = comments.comment_id
    GROUP BY
        comments.comment_bucket,
        roles.bullying_role
)

SELECT
    role_filler.comment_bucket,
    role_filler.bullying_role,
    coalesce(count_comments_with_role.role_count, 0) AS role_count
FROM role_filler
LEFT JOIN  count_comments_with_role
    ON role_filler.bullying_role = count_comments_with_role.bullying_role
    AND role_filler.comment_bucket = count_comments_with_role.comment_bucket;

CREATE TEMP TABLE pivoted_role_counts AS
SELECT *
FROM
    crosstab(
        'SELECT comment_bucket, bullying_role, role_count FROM time_roles_count ORDER BY comment_bucket, bullying_role;'
    ) AS piv
(
comment_bucket INTEGER,
aggressive_defender BIGINT,
aggressive_victim BIGINT,
bully BIGINT,
bully_assistant BIGINT,
inconclusive BIGINT,
non_aggressive_defender BIGINT,
non_aggressive_victim BIGINT,
passive_bystander BIGINT
);


CREATE TEMP TABLE pivoted_role_percents AS
SELECT *
FROM
    crosstab(
        'SELECT comment_bucket, bullying_role, round(role_count::numeric(12, 8) / sum(role_count) OVER (PARTITION BY comment_bucket), 3) AS percent FROM time_roles_count ORDER BY comment_bucket, bullying_role;'
    ) AS piv
(
comment_bucket integer,
aggressive_defender numeric,
aggressive_victim numeric,
bully numeric,
bully_assistant numeric,
inconclusive numeric,
non_aggressive_defender numeric,
non_aggressive_victim numeric,
passive_bystander numeric
);

SELECT
    sum(passive_bystander) AS passive_bystander,
    sum(aggressive_defender) AS aggressive_defender,
    sum(aggressive_victim) AS aggressive_victim,
    sum(bully) AS bully,
    sum(bully_assistant) AS bully_assistant,
    sum(inconclusive) AS inconclusive,
    sum(non_aggressive_defender) AS non_aggressive_defender,
    sum(non_aggressive_victim) AS non_aggressive_victim
FROM pivoted_role_counts;

SELECT
    sum(passive_bystander) AS passive_bystander,
    sum(aggressive_defender) AS aggressive_defender,
    sum(aggressive_victim) AS aggressive_victim,
    sum(bully) AS bully,
    sum(bully_assistant) AS bully_assistant,
    sum(inconclusive) AS inconclusive,
    sum(non_aggressive_defender) AS non_aggressive_defender,
    sum(non_aggressive_victim) AS non_aggressive_victim
FROM pivoted_role_percents;

SELECT *
FROM pivoted_role_counts;

\copy pivoted_role_counts TO '/tmp/pivoted_role_counts.txt' With CSV DELIMITER ',' HEADER;

SELECT *
FROM pivoted_role_percents;

\copy pivoted_role_percents TO '/tmp/pivoted_role_percents.txt' With CSV DELIMITER ',' HEADER;
