CREATE TABLE IF NOT EXISTS auth.invitations (
    id              BIGSERIAL PRIMARY KEY,
    organization_id BIGINT      NOT NULL REFERENCES auth.organizations(id),
    invited_by      BIGINT      NOT NULL REFERENCES auth.users(id),
    email           TEXT        NOT NULL,
    token           TEXT        NOT NULL UNIQUE,
    status          TEXT        NOT NULL DEFAULT 'pending',
    expires_at      TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT invitations_status_check CHECK (status IN ('pending', 'accepted', 'expired', 'revoked'))
);
