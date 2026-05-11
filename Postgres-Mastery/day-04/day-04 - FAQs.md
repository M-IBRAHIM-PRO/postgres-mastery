# Day 4 FAQs

These FAQs focus on migrations, schema evolution, and high-volume table design.

Use the source notes for full explanations:

- Migrations: [[migrations]]
- New tables: [[new-tables]]
- Partitioning: [[partitioning]]
- Day-level system picture: [[day-04 - Architecture]]

---

## 1. Why not just run raw SQL files instead of a migration tool?

Raw files work at day one.
They break at day ten.

```txt
Which files are already applied on staging?
What order do they run in?
How do I roll back one change?
What happened when a file ran halfway and failed?
```

A migration tool answers all of these automatically.

Use [[migrations#1. Why golang-migrate|Why golang-migrate]].

---

## 2. What is the difference between golang-migrate, goose, and atlas?

```txt
golang-migrate  → minimal CLI, file-based SQL, no config needed
goose           → similar, also supports Go code migrations
atlas           → computes diffs from desired schema state, steeper setup
```

For SQL-only learners, golang-migrate or goose is the right start.
Atlas becomes useful when managing many environments with drift.

Use [[migrations#1. Why golang-migrate|Why golang-migrate]].

---

## 3. Why does every up.sql use IF NOT EXISTS?

So the migration is safe to re-run.

```txt
CI retries a failed job → migration runs again → IF NOT EXISTS skips safely
Developer runs migrate-up twice by mistake → no crash
```

Without it, a second run would fail with "relation already exists".

Use [[migrations#4. Safe Up Migrations|Safe Up Migrations]].

---

## 4. Why does every down.sql use CASCADE?

Because DROP fails if anything references the object being dropped.

```txt
DROP TABLE auth.users
→ fails because auth.memberships has a FK to auth.users
```

With CASCADE:

```txt
DROP TABLE auth.users CASCADE
→ drops memberships too (or any other dependents)
```

Down migrations must drop in reverse dependency order anyway.
CASCADE is an extra safety net for cross-migration dependencies.

Use [[migrations#5. Safe Down Migrations|Safe Down Migrations]].

---

## 5. What does "dirty" mean in golang-migrate?

It means a migration started but did not complete cleanly.

```txt
version=5, dirty=true
→ migration 5 ran but failed halfway
```

Running `migrate-up` again will refuse until you resolve it.

Fix:

```bash
# 1. manually undo any partial changes from migration 5
# 2. reset to last clean version
make migrate-force VERSION=4
# 3. fix the SQL in 000005_...up.sql
# 4. re-apply
make migrate-up
```

Use [[migrations#7. Dirty State|Dirty State]].

---

## 6. Why does auth.invitations have expires_at NOT NULL?

An invitation without a deadline is a security risk.

```txt
Invitation tokens are sensitive — they grant access to an organization.
Without expiry, an old token found in an email thread could still work years later.
```

Always set a short expiry (24–72 hours is common).

Use [[new-tables#1. auth.invitations|auth.invitations]].

---

## 7. Why is assignee_id in projects.tasks nullable?

Because tasks are often created before they are assigned.

A product workflow where you must assign every task at creation is restrictive.
Nullable `assignee_id` models "unassigned" cleanly without a placeholder user.

Use [[new-tables#2. projects.tasks|projects.tasks]].

---

## 8. Why does events.activity_log use payload JSONB instead of typed columns?

Because every event type has different data.

```txt
user.login   → ip, device
task.created → task_id, title
invitation.sent → email, org_id
```

Adding a new column per event type would:

```txt
Require a migration for each new event type
Leave most columns NULL for most rows
Make the table wide and messy
```

JSONB stores event-specific data flexibly.
`event_type TEXT` lets queries filter to a specific shape.

Use [[new-tables#3. events.activity_log|events.activity_log]].

---

## 9. Why does the activity_log PRIMARY KEY include occurred_at?

Because PostgreSQL requires the partition key to be in every unique constraint.

```txt
PARTITION BY RANGE (occurred_at)
→ uniqueness must be per partition
→ PK must include occurred_at to enforce uniqueness within each partition
```

Without `occurred_at` in the PK, this error appears:

```txt
ERROR: unique constraint on partitioned table must include all partitioning columns
```

Use [[partitioning#3. Partition-Ready Shape|Partition-Ready Shape]].

---

## 10. What is the main Day 4 mindset change?

Day 3 asked:

```txt
How do I query, protect, and optimize the schema?
```

Day 4 asks:

```txt
How do I change the schema safely across environments, over time, as a team?
```

That is the shift from writing SQL to shipping SQL.

Use [[day-04 - Architecture]].
