CREATE TEMP TABLE bullying_majority AS
SELECT
    comment_id,
    CASE
        WHEN is_cyberbullying
            THEN 'Bullying'
        ELSE 'Non-Bullying'
    END AS is_cyberbullying,
    count(*) AS bullying_annotation_count
FROM mturk.comment_annotations
GROUP BY comment_id, is_cyberbullying
HAVING count(*) >= 3;


CREATE TEMP TABLE bullying_counts AS
SELECT
    is_cyberbullying,
    count(*) AS bullying_count,
    sum(count(*)) OVER () AS total_comments,
    round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS percentage,
    count(*) || ' (' || round(100.0 * count(*) / sum(count(*)) OVER (), 1) || '\%)' AS label
FROM bullying_majority
GROUP BY is_cyberbullying
ORDER BY bullying_count DESC;

SELECT *
FROM bullying_counts;

\copy bullying_counts TO '/tmp/bullying_counts.txt' With CSV DELIMITER ',' HEADER;
