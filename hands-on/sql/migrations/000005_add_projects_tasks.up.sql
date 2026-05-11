CREATE TABLE IF NOT EXISTS projects.tasks (
    id          BIGSERIAL PRIMARY KEY,
    project_id  BIGINT      NOT NULL REFERENCES projects.projects(id),
    title       TEXT        NOT NULL,
    status      TEXT        NOT NULL DEFAULT 'todo',
    assignee_id BIGINT      REFERENCES auth.users(id),
    due_date    DATE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT tasks_status_check CHECK (status IN ('todo', 'in_progress', 'done', 'cancelled'))
);
