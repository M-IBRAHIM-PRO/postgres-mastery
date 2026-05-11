# Database Migrations

Migrations are the production way to change a schema.
Instead of running raw SQL files manually, each change is versioned, ordered, and reversible.

For the Day 4 system picture, see [[day-04 - Architecture]].

---

## 1. Why golang-migrate

Three common tools exist:

```txt
golang-migrate  → lightweight CLI + Go library, file-based, no config file needed
goose           → similar, slightly more Go-centric, supports Go migrations
atlas           → more powerful, schema-diff based, steeper learning curve
```

`golang-migrate` chosen because:

```txt
Minimal setup — just numbered SQL files in a directory
Works as a CLI without touching Go code
Pairs well with a Makefile
```

---

## 2. How It Works

golang-migrate creates a `schema_migrations` table in your database.

```sql
-- managed by golang-migrate, do not edit manually
schema_migrations (version BIGINT, dirty BOOLEAN)
```

```txt
version = the last migration number successfully applied
dirty   = true if a migration ran but failed mid-execution
```

Every `make migrate-up` looks at the current version and applies all higher-numbered files in order.

---

## 3. File Naming

```txt
000001_init_extensions_and_schemas.up.sql
000001_init_extensions_and_schemas.down.sql
000002_create_auth_tables.up.sql
000002_create_auth_tables.down.sql
...
```

Rules:

```txt
Number first        → controls execution order
Name after number   → describes what changes
.up.sql             → apply the change
.down.sql           → reverse the change
```

Create a new pair:

```bash
make migrate-create name=add_something
```

---

## 4. Safe Up Migrations

Every `up.sql` uses `IF NOT EXISTS`:

```sql
CREATE TABLE IF NOT EXISTS auth.invitations ( ... );
CREATE SCHEMA IF NOT EXISTS events;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```

Why:

```txt
If the migration runs twice (CI retry, manual re-run), it does not crash.
The table either gets created or is already there — same result.
```

---

## 5. Safe Down Migrations

Every `down.sql` uses `IF EXISTS` and `CASCADE`:

```sql
DROP TABLE IF EXISTS projects.tasks;
DROP SCHEMA IF EXISTS events CASCADE;
```

Why `IF EXISTS`:

```txt
Safe to run even if up never completed — does not crash on missing objects.
```

Why `CASCADE`:

```txt
Child tables and dependent views are dropped automatically.
Without it, Postgres blocks the drop if anything references the object.
```

Down migration order must be the reverse of up migration order.

```txt
If 000005 creates tasks that reference 000003's projects,
then 000005.down runs before 000003.down.
```

golang-migrate handles this automatically — it steps down one version at a time.

---

## 6. Makefile Commands

```bash
make migrate-up                   # apply all pending migrations
make migrate-down                 # roll back 1 step
make migrate-down STEPS=3         # roll back 3 steps
make migrate-force VERSION=4      # force-set version (fix dirty state)
make migrate-create name=<slug>   # create new up/down file pair
```

---

## 7. Dirty State

If a migration fails halfway, golang-migrate marks the version as dirty:

```txt
version=5, dirty=true
```

Running `migrate-up` again will refuse:

```txt
error: Dirty database version 5. Fix and force version.
```

Fix:

1. Manually undo whatever the failed migration partially did
2. Run `make migrate-force VERSION=4` to reset to the last clean version
3. Fix the migration SQL
4. Run `make migrate-up` again

Memory hook:

```txt
dirty = migration in progress or partially failed. Never skip over it.
```

---

## 8. Current Migration History

```txt
000001  init_extensions_and_schemas   pgcrypto, auth/projects/events schemas
000002  create_auth_tables            users, organizations, memberships
000003  create_projects_tables        projects.projects
000004  add_auth_invitations          auth.invitations
000005  add_projects_tasks            projects.tasks
000006  add_events_activity_log       events.activity_log (partitioned)
```
