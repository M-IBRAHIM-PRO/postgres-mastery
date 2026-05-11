CREATE TABLE IF NOT EXISTS auth.users (
    id         BIGSERIAL PRIMARY KEY,
    public_id  UUID        NOT NULL DEFAULT gen_random_uuid(),
    email      TEXT        NOT NULL UNIQUE,
    full_name  TEXT        NOT NULL,
    is_active  BOOLEAN     NOT NULL DEFAULT TRUE,
    preferences JSONB      NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS auth.organizations (
    id         BIGSERIAL PRIMARY KEY,
    public_id  UUID        NOT NULL DEFAULT gen_random_uuid(),
    name       TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS auth.memberships (
    id              BIGSERIAL PRIMARY KEY,
    organization_id BIGINT      NOT NULL REFERENCES auth.organizations(id),
    user_id         BIGINT      NOT NULL REFERENCES auth.users(id),
    role            TEXT        NOT NULL DEFAULT 'member',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (organization_id, user_id),
    CONSTRAINT memberships_role_check CHECK (role IN ('owner', 'admin', 'member'))
);
