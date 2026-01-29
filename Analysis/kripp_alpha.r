library(tidyverse)
library(glue)
library(DBI)
library(irr)
library(RPostgres)

con <- dbConnect(
  RPostgres::Postgres(),
  dbname = "ctsr",
  host = "box",
  port = 5432,
  user = "sandy",
  password = "roles"
)


bully_sql <- "
  SELECT
      comment_id,
      assignment_id,
      is_cyberbullying::INT AS is_bullying,
      'annotator_' || row_number() OVER (PARTITION BY comment_id) AS annotator_number
  FROM mturk.comment_annotations;
"

roles_sql <- "
SELECT
    comment_id,
    assignment_id,
    CASE
      WHEN bullying_role = 'non_aggressive_victim'
          THEN 1
      WHEN bullying_role = 'bully_assistant'
          THEN 2
      WHEN bullying_role = 'passive_bystander'
          THEN 3
      WHEN bullying_role = 'bully'
          THEN 4
      WHEN bullying_role = 'aggressive_defender'
          THEN 5
      WHEN bullying_role = 'non_aggressive_defender'
          THEN 6
      WHEN bullying_role = 'aggressive_victim'
          THEN 7
      ELSE -1
    END AS bullying_role,
    'annotator_' || row_number() OVER (PARTITION BY comment_id) AS annotator_number
FROM mturk.comment_annotations;
"

severity_sql <- "
SELECT
    comment_id,
    CASE
        WHEN bullying_severity = 'mild'
            THEN 1
        WHEN bullying_severity = 'moderate'
            THEN 2
        WHEN bullying_severity = 'severe'
            THEN 3
        WHEN bullying_severity IS NULL
            THEN 0
        ELSE -1
    END AS bullying_severity,
    'annotator_' || row_number() OVER (PARTITION BY comment_id) AS annotator_number
FROM mturk.comment_annotations
"

compute_topic_alphas <- function() {
  topics <- c("sexual", "physical", "gender", "political", "disability", "intellectual", "religious", "none", "race", "social_status")
  for (topic in topics) {
    toipc_sql <- glue("
    WITH annotator_selected_topic AS (
      SELECT comment_id, assignment_id, topic
      FROM mturk.comment_topics
      WHERE topic = '{topic}'
    ), has_topics AS (
      SELECT
        anons.comment_id,
        row_number() OVER (PARTITION BY anons.comment_id) AS annotator_number,
        (selected.topic IS NOT NULL)::INT AS has_topic
      FROM mturk.comment_annotations AS anons
      LEFT JOIN annotator_selected_topic AS selected
        ON anons.comment_id = selected.comment_id
        AND anons.assignment_id = selected.assignment_id
    )
    SELECT *
    FROM has_topics;
    ")

    result <- dbGetQuery(con, toipc_sql) |>
      as_tibble() |>
      pivot_wider(
        id_cols = annotator_number,
        names_from = comment_id,
        values_from = has_topic
      ) |>
      as.matrix() |>
      kripp.alpha(method = "nominal")
    print(result)
  }
}

dbGetQuery(con, bully_sql) |>
  as_tibble() |>
  pivot_wider(
    id_cols = annotator_number,
    names_from = comment_id,
    values_from = is_bullying
  ) |>
  as.matrix() |>
  kripp.alpha(method = "nominal")


dbGetQuery(con, severity_sql) |>
  as_tibble() |>
  pivot_wider(
    id_cols = annotator_number,
    names_from = comment_id,
    values_from = bullying_severity
  ) |>
  as.matrix() |>
  kripp.alpha(method = "ordinal")

dbGetQuery(con, roles_sql) |>
  as_tibble() |>
  pivot_wider(
    id_cols = annotator_number,
    names_from = comment_id,
    values_from = bullying_role
  ) |>
  as.matrix() |>
  kripp.alpha(method = "nominal")


compute_topic_alphas()
