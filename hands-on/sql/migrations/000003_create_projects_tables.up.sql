CREATE TABLE IF NOT EXISTS projects.projects (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID        NOT NULL DEFAULT gen_random_uuid(),
    organization_id BIGINT      NOT NULL REFERENCES auth.organizations(id),
    created_by      BIGINT      NOT NULL REFERENCES auth.users(id),
    name            TEXT        NOT NULL,
    description     TEXT,
    metadata        JSONB       NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
