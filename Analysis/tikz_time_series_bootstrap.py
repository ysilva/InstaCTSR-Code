# pyright: basic

import polars as pl

SAMPLES = 30_000
COMMENT_BUCKETS = 10


def query(query: str) -> pl.DataFrame:
    assert "SELECT" in query
    DATABASE = "postgresql://sandy:roles@box:5432/ctsr"
    frame = pl.read_database_uri(query, DATABASE)
    assert isinstance(frame, pl.DataFrame)
    return frame


def write_severity_tables(
    comments: pl.DataFrame, comment_annotations: pl.DataFrame, with_nulls: bool = False
) -> None:
    if with_nulls:
        min_severity = -1.0
    else:
        min_severity = 0.0

    numeric_severity = comment_annotations.select(
        pl.col("comment_id", "bullying_severity"),
        pl.when(pl.col("bullying_severity") == "mild")
        .then(pl.lit(1.0))
        .when(pl.col("bullying_severity") == "moderate")
        .then(pl.lit(2.0))
        .when(pl.col("bullying_severity") == "severe")
        .then(pl.lit(3.0))
        .when(pl.col("bullying_severity").is_null())
        .then(pl.lit(0.0))
        .alias("severity"),
    ).filter(pl.col("severity") > min_severity)

    comment_sequence = comments.select(
        pl.col("comment_bucket", "comment_bucket_display", "comment_id")
    )
    severity = numeric_severity.join(comment_sequence, on="comment_id")

    samples: list[pl.DataFrame] = []
    for comment_bucket in range(1, COMMENT_BUCKETS + 1):
        this_comment = severity.filter(pl.col("comment_bucket") == comment_bucket)
        number_bootstrap_samples = len(this_comment)
        for _ in range(SAMPLES):
            comment_mean = (
                this_comment.sample(
                    number_bootstrap_samples, shuffle=True, with_replacement=True
                )
                .group_by(["comment_bucket", "comment_bucket_display"])
                .agg(pl.col("severity").mean().alias("mean_severity"))
            )
            samples.append(comment_mean)
    sampled_severity = pl.concat(samples, how="vertical")
    bootstrapped_severity_stats = (
        sampled_severity.group_by(["comment_bucket", "comment_bucket_display"])
        .agg(
            pl.col("mean_severity").quantile(0.05).round(4).alias("lower_5th"),
            pl.col("mean_severity").mean().round(4).alias("mean_severity"),
            pl.col("mean_severity").quantile(0.95).round(4).alias("upper_95th"),
        )
        .sort("comment_bucket")
    )
    print(bootstrapped_severity_stats)
    bootstrapped_severity_stats.write_csv(
        f"boot_strap_severity_stats_with_null_{with_nulls}.txt", separator=";"
    )


def write_bully_tables(comments: pl.DataFrame, comment_annotations: pl.DataFrame):
    """
    I want to count the percent of annotators within a comment that voted bully,
    then I want to bootstrapped the percentages for each comment in the comment sequence.
    """
    comment_percents = (
        comment_annotations.group_by("comment_id", "is_cyberbullying")
        .len("bullying_count")
        .with_columns(
            (
                pl.col("bullying_count") / pl.sum("bullying_count").over("comment_id")
            ).alias("percentage")
        )
        .filter(pl.col("is_cyberbullying"))
        .select(pl.col("comment_id", "percentage"))
        .sort("comment_id")
    )
    comment_sequence = comments.select(
        pl.col("comment_bucket", "comment_bucket_display", "comment_id")
    )
    samples: list[pl.DataFrame] = []
    percents = comment_percents.join(comment_sequence, on="comment_id")
    for comment_bucket in range(1, COMMENT_BUCKETS + 1):
        this_comment = percents.filter(pl.col("comment_bucket") == comment_bucket)
        number_bootstrap_samples = len(this_comment)
        for _ in range(SAMPLES):
            mean_sample = (
                this_comment.sample(
                    number_bootstrap_samples, shuffle=True, with_replacement=True
                )
                .group_by(["comment_bucket", "comment_bucket_display"])
                .agg(pl.col("percentage").mean().alias("mean_percentage"))
            )
            samples.append(mean_sample)
    sampled_percents = pl.concat(samples, how="vertical")
    bootstrapped_percent_stats = (
        sampled_percents.group_by(["comment_bucket", "comment_bucket_display"])
        .agg(
            pl.col("mean_percentage").quantile(0.05).round(4).alias("lower_5th"),
            pl.col("mean_percentage")
            .mean()
            .alias("mean")
            .round(4)
            .alias("mean_cb_percentage"),
            pl.col("mean_percentage").quantile(0.95).round(4).alias("upper_95th"),
        )
        .sort("comment_bucket")
    )
    print(bootstrapped_percent_stats)
    bootstrapped_percent_stats.write_csv("boot_strap_percent_stats.txt", separator=";")


QUERY_BUCKETED_COMMENTS = """
WITH comments_numbered AS (
    SELECT
        *,
        row_number()
            OVER (
            PARTITION BY unit_id 
            ORDER BY comment_created_at) AS comment_number
    FROM instagram.comments
)
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
FROM comments_numbered
"""

comments = query(QUERY_BUCKETED_COMMENTS)
comment_annotations = query("SELECT * FROM mturk.comment_annotations")
comment_topics = query("SELECT * FROM mturk.comment_topics")
write_bully_tables(comments, comment_annotations)
write_severity_tables(comments, comment_annotations, False)
write_severity_tables(comments, comment_annotations, True)
