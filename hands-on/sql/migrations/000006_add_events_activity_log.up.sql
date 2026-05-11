-- Partition-ready: PK includes occurred_at so Postgres can route rows to child partitions.
-- Each partition must include occurred_at in its PK — this is the Postgres partitioning requirement.
CREATE TABLE IF NOT EXISTS events.activity_log (
    id              BIGSERIAL,
    occurred_at     TIMESTAMPTZ NOT NULL,
    actor_id        BIGINT,
    organization_id BIGINT,
    event_type      TEXT        NOT NULL,
    payload         JSONB       NOT NULL DEFAULT '{}',
    PRIMARY KEY (id, occurred_at)
) PARTITION BY RANGE (occurred_at);

-- Default partition catches rows that don't match any explicit range partition.
-- Replace with named monthly partitions as volume grows.
CREATE TABLE IF NOT EXISTS events.activity_log_default
    PARTITION OF events.activity_log DEFAULT;
