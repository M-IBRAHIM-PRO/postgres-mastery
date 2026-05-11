# Day 4 Architecture

Day 3 worked on an existing schema — querying, constraints, indexes, transactions.

Day 4 changes how the schema itself gets built and shipped:

```txt
Day 1 = PostgreSQL foundations
Day 2 = schema and relationships
Day 3 = production-style data access
Day 4 = controlled schema change + high-volume table design
```

---

## 1. The Problem With Raw SQL Files

Before Day 4, the schema lived in `sql/queries/day-01.sql`, `day-02.sql`, and so on.

That approach breaks down quickly:

```txt
Which file do I run on a fresh database?
Which changes are already applied on staging?
How do I undo a change?
What happened when a file ran partially and failed?
```

Migration tools solve all of these.

---

## 2. What a Migration Tool Provides

```txt
Ordered execution   → each change has a sequence number
Up/down symmetry    → every forward change has a matching rollback
State tracking      → the tool records which migrations already ran
Repeatable          → safe to run in CI, staging, production without guessing
```

The tool used here is `golang-migrate`.

It creates a `schema_migrations` table in the database.
That table tracks the current version and a dirty flag.

See [[migrations]] for the full command reference.

---

## 3. Schema Change: New Tables

Day 4 adds three tables that reflect real SaaS needs:

```txt
auth.invitations       → invite flow for onboarding users
projects.tasks         → work items inside a project
events.activity_log    → audit trail of everything that happens
```

These tables were planned at the end of Day 3 as natural extensions.

See [[new-tables]] for design decisions and column rationale.

---

## 4. The High-Volume Problem

`events.activity_log` is different from the other tables.

Every user action writes a row.
At scale, this table grows extremely fast.

The solution is partitioning.

Instead of one massive table, PostgreSQL manages many child tables (partitions).
Each partition holds rows for a time range.

Day 4 sets the table up with a partition-ready shape.
Named monthly partitions come later as volume grows.

See [[partitioning]] for the design and mechanics.

---

## 5. Project Layout Shift

Day 4 also restructures the Go project slightly:

```txt
cmd/main.go         → old
cmd/api/main.go     → new (matches Go convention for multi-binary repos)
scripts/migrate.sh  → new (migration runner, sources .env, calls golang-migrate)
Makefile            → updated with run, build, migrate-up, migrate-down, migrate-force
```

The Makefile delegates to `scripts/migrate.sh` instead of calling `migrate` directly.
This keeps the migration logic in one place and makes it easy to add pre/post steps later.

---

## 6. Day 4 Layers

```txt
Schema change layer   → migrations (numbered, up/down, IF NOT EXISTS)
Domain layer          → invitations, tasks, activity_log
Volume layer          → partitioned table, default partition
Tooling layer         → Makefile targets, migrate.sh, golang-migrate
```
