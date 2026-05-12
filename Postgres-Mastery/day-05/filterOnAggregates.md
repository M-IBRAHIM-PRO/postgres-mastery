# `FILTER (WHERE ...)` on Aggregates

For recipes see [[Advanced SQL Cheatsheet#5. `FILTER (WHERE …)`]]. For gotchas see [[day-05 - FAQs#`FILTER (WHERE …)`]].

## Theory

`FILTER (WHERE ...)` lets an aggregate **count or sum only the rows that match a condition**, while still part of a normal aggregate query.

**Analogy: a smart cashier counting coins.**

Cashier empties a jar of mixed coins. You ask:

> "How many coins total? How many pennies? How many quarters? Value of just the gold ones?"

A normal cashier sorts them into piles first, then counts each — that's `GROUP BY`. A smart cashier looks at the same pile once and gives all four numbers by counting selectively. That's `FILTER`.

```txt
GROUP BY = "sort rows into piles, then aggregate each pile"
FILTER   = "look at all rows once, aggregate each metric on its own condition"
```

## Syntax

```sql
aggregate_function(expression) FILTER (WHERE condition)
```

Rules:

- `FILTER` attaches to **one aggregate**. Each aggregate can have its own filter (or none).
- The condition is a normal `WHERE` expression.
- `FILTER` is **separate from the query's `WHERE`**. `WHERE` decides which rows the query sees at all; `FILTER` decides which of those rows each aggregate counts.

Execution shape:

```txt
Step 1: FROM + JOIN  -> gather candidate rows
Step 2: WHERE        -> drop rows the whole query doesn't care about
Step 3: GROUP BY     -> form groups
Step 4: For each group, run each aggregate.
        Each aggregate's FILTER decides which rows in that group it counts.
```

For full `FILTER` vs `WHERE` and `FILTER` vs `CASE WHEN` discussion see [[day-05 - FAQs#16. `FILTER` vs `WHERE` — what's the actual difference?]] and [[day-05 - FAQs#17. Why prefer `FILTER` over `CASE WHEN` inside an aggregate?]].

## Practical Queries

### Example 1 — Task status breakdown per project (pivot)

Textbook `FILTER` use. One row per project, one column per status.

```sql
SELECT
  project_id,
  COUNT(*)                                            AS total_tasks,
  COUNT(*) FILTER (WHERE status = 'todo')             AS todo,
  COUNT(*) FILTER (WHERE status = 'in_progress')      AS in_progress,
  COUNT(*) FILTER (WHERE status = 'done')             AS done,
  COUNT(*) FILTER (WHERE status = 'cancelled')        AS cancelled
FROM projects.tasks
GROUP BY project_id
ORDER BY project_id;
```

**Pivot pattern**: row-shaped data ("one row per task") → column-shaped data ("one row per project with counts per status").

### Example 2 — Unassigned vs assigned tasks per project

```sql
SELECT
  project_id,
  COUNT(*) FILTER (WHERE assignee_id IS NOT NULL) AS assigned,
  COUNT(*) FILTER (WHERE assignee_id IS NULL)     AS unassigned
FROM projects.tasks
GROUP BY project_id
ORDER BY project_id;
```

### Example 3 — Overdue task count per assignee

`WHERE` narrows scope, `FILTER` defines the metric.

```sql
SELECT
  assignee_id,
  COUNT(*) AS total_tasks,
  COUNT(*) FILTER (
    WHERE due_date < CURRENT_DATE
      AND status NOT IN ('done', 'cancelled')
  ) AS overdue
FROM projects.tasks
WHERE assignee_id IS NOT NULL
GROUP BY assignee_id
ORDER BY overdue DESC, total_tasks DESC;
```

Division of labor:

- `WHERE assignee_id IS NOT NULL` — query ignores unassigned tasks.
- `FILTER (...)` — `overdue` column counts only overdue ones.

### Example 4 — Invitation funnel per organization

`auth.invitations.status`: `pending`, `accepted`, `expired`, `revoked`.

```sql
SELECT
  o.name AS organization,
  COUNT(*)                                            AS sent,
  COUNT(*) FILTER (WHERE i.status = 'accepted')       AS accepted,
  COUNT(*) FILTER (WHERE i.status = 'pending')        AS pending,
  COUNT(*) FILTER (WHERE i.status = 'expired')        AS expired,
  COUNT(*) FILTER (WHERE i.status = 'revoked')        AS revoked,
  ROUND(
    100.0 * COUNT(*) FILTER (WHERE i.status = 'accepted') / NULLIF(COUNT(*), 0),
    1
  ) AS accept_rate_pct
FROM auth.invitations AS i
JOIN auth.organizations AS o ON o.id = i.organization_id
GROUP BY o.name
ORDER BY o.name;
```

Acceptance rate = `accepted / total * 100`, both computed in the same `SELECT`.

### Example 5 — `SUM` with `FILTER` for budget rollups

`FILTER` works with any aggregate, not just `COUNT`.

```sql
SELECT
  organization_id,
  SUM((metadata->>'budget')::int)                                                   AS total_budget,
  SUM((metadata->>'budget')::int) FILTER (WHERE metadata->>'status' = 'active')     AS active_budget,
  SUM((metadata->>'budget')::int) FILTER (WHERE metadata->>'status' = 'planning')   AS planning_budget,
  SUM((metadata->>'budget')::int) FILTER (WHERE metadata->>'status' = 'completed')  AS completed_budget
FROM projects.projects
GROUP BY organization_id
ORDER BY organization_id;
```

### Example 6 — Multi-event monthly dashboard

```sql
SELECT
  DATE_TRUNC('month', occurred_at)::date AS month,
  COUNT(*)                                                          AS total_events,
  COUNT(*) FILTER (WHERE event_type = 'project.created')            AS projects_created,
  COUNT(*) FILTER (WHERE event_type = 'task.completed')             AS tasks_completed,
  COUNT(*) FILTER (WHERE event_type = 'invitation.sent')            AS invites_sent,
  COUNT(*) FILTER (WHERE event_type = 'invitation.accepted')        AS invites_accepted,
  COUNT(DISTINCT actor_id)                                          AS distinct_actors
FROM events.activity_log
GROUP BY DATE_TRUNC('month', occurred_at)
ORDER BY month;
```

Adding another metric = one more line. No new joins, no new query.

### Example 7 — `FILTER` with window functions

`FILTER` also works on **window aggregates**. Running count of "done" tasks per project:

```sql
SELECT
  project_id,
  id,
  status,
  created_at,
  COUNT(*) FILTER (WHERE status = 'done') OVER (
    PARTITION BY project_id
    ORDER BY created_at
  ) AS done_so_far,
  COUNT(*) OVER (
    PARTITION BY project_id
    ORDER BY created_at
  ) AS tasks_so_far
FROM projects.tasks
ORDER BY project_id, created_at;
```

Window decides *which rows the function sees*; `FILTER` decides *which of those it counts*. See [[day-05 - FAQs#18. Can `FILTER` work with window functions?]].
