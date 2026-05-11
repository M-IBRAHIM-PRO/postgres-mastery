# New Tables — Day 4

Three tables added in Day 4 to extend the SaaS schema.

For migration setup, see [[migrations]].
For the system picture, see [[day-04 - Architecture]].

---

## 1. auth.invitations

### What it models

The flow for inviting a new user to an organization before they have an account.

### Schema

```sql
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
```

### Design decisions

```txt
token UNIQUE          → the invite link is the token; must be globally unique
status CHECK          → only four valid lifecycle states
expires_at NOT NULL   → every invitation has a deadline; no open-ended invites
email NOT NULL        → target address, may not be a registered user yet
invited_by FK         → audit trail of who sent it
```

### Status lifecycle

```txt
pending   → invitation sent, not acted on
accepted  → user clicked link, created account or joined
expired   → expires_at passed without acceptance
revoked   → manually cancelled by an admin
```

---

## 2. projects.tasks

### What it models

Individual work items inside a project.

### Schema

```sql
CREATE TABLE IF NOT EXISTS projects.tasks (
    id          BIGSERIAL PRIMARY KEY,
    project_id  BIGINT      NOT NULL REFERENCES projects.projects(id),
    title       TEXT        NOT NULL,
    status      TEXT        NOT NULL DEFAULT 'todo',
    assignee_id BIGINT      REFERENCES auth.users(id),
    due_date    DATE        ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT tasks_status_check CHECK (status IN ('todo', 'in_progress', 'done', 'cancelled'))
);
```

### Design decisions

```txt
assignee_id nullable   → a task can exist before it is assigned to anyone
due_date DATE          → DATE not TIMESTAMPTZ; a deadline is a calendar day, not a moment
status CHECK           → four valid states covering the normal task lifecycle
updated_at             → needed for change detection; task status changes are frequent
```

### Status lifecycle

```txt
todo         → created, not started
in_progress  → actively being worked on
done         → completed
cancelled    → abandoned
```

---

## 3. events.activity_log

### What it models

An append-only audit trail of everything that happens in the system.

Every meaningful user action writes one row.

### Schema

```sql
CREATE TABLE IF NOT EXISTS events.activity_log (
    id              BIGSERIAL,
    occurred_at     TIMESTAMPTZ NOT NULL,
    actor_id        BIGINT,
    organization_id BIGINT,
    event_type      TEXT        NOT NULL,
    payload         JSONB       NOT NULL DEFAULT '{}',
    PRIMARY KEY (id, occurred_at)
) PARTITION BY RANGE (occurred_at);

CREATE TABLE IF NOT EXISTS events.activity_log_default
    PARTITION OF events.activity_log DEFAULT;
```

### Design decisions

```txt
actor_id nullable        → some events are system-generated with no user actor
organization_id nullable → some events are platform-level, not scoped to an org
event_type TEXT          → flexible dotted namespace like 'user.login', 'task.created'
payload JSONB            → event-specific details without new columns per event type
occurred_at NOT NULL     → the moment is always known; never optional
```

### Why it lives in the events schema

```txt
auth     → identity and access
projects → project work
events   → what happened (read-only, append-only, high volume)
```

Separate schema makes it easier to:

- set different backup and retention policies
- restrict write access to specific roles
- add partitions without touching other schemas

For partitioning details, see [[partitioning]].

---

## 4. Seed Data

`sql/seeds/day-04.sql` inserts 51 rows into `events.activity_log`.

Events covered:

```txt
user.login
project.created
project.updated
task.created
task.status_changed
invitation.sent
invitation.accepted
```

Rows span the last 29 days across 5 actors and 2 organizations.
All rows land in `activity_log_default` since no range partitions are defined yet.
