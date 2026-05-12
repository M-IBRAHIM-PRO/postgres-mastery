# `GROUPING SETS`, `ROLLUP`, `CUBE` — Multi-Level Aggregation

For recipes see [[Advanced SQL Cheatsheet#4. `GROUPING SETS`, `ROLLUP`, `CUBE`]]. For gotchas see [[day-05 - FAQs#`GROUPING SETS`, `ROLLUP`, `CUBE`]].

## Theory

Regular `GROUP BY` summarizes data **at one level**. These three extensions compute **multiple levels of aggregation in one query**.

**Analogy: a sales report on a manager's desk.**

When you hand a manager a report, they want:

- totals per project per status
- subtotals per project (across all statuses)
- subtotals per status (across all projects)
- the grand total

In plain SQL, that's four separate `GROUP BY` queries plus a `UNION ALL`. `GROUPING SETS`, `ROLLUP`, `CUBE` give you all in one query.

```txt
GROUP BY        = one level of summary
GROUPING SETS   = several specific levels you list
ROLLUP          = a hierarchy of subtotals + grand total
CUBE            = every possible combination of levels
```

## The Mental Model

Each output row answers "for this combination of columns, what's the aggregate?" `NULL` in a group-by column means "**this column was not grouped on for this row — it's an 'all values' row.**"

Toy example with `project_id` and `status`:

```txt
project_id | status      | task_count
-----------+-------------+-----------
    1      | todo        |   5      ← grouped by both
    1      | in_progress |   3      ← grouped by both
    1      |  NULL       |   8      ← subtotal for project 1 (all statuses)
  NULL     | todo        |  12      ← subtotal for todo (all projects)
  NULL     |  NULL       |  47      ← grand total
```

That `NULL` is **structural** — it means "this column was rolled up." Distinguish from real `NULL` with `GROUPING()` (see below).

## `GROUPING SETS` — You Pick the Levels

```sql
GROUP BY GROUPING SETS (
  (col_a, col_b),   -- group by both
  (col_a),          -- group by col_a only
  (col_b),          -- group by col_b only
  ()                -- grand total
)
```

Each tuple is one level. Result is the union of all groupings.

## `ROLLUP` — Hierarchical Subtotals

`ROLLUP(a, b, c)` peels columns from the right:

```txt
ROLLUP(a, b, c) is equivalent to GROUPING SETS:
  (a, b, c)
  (a, b)
  (a)
  ()
```

Matches natural hierarchies: country → region → city. **Order matters** — see [[day-05 - FAQs#14. Does column order matter in `ROLLUP`?]].

## `CUBE` — Every Combination

`CUBE(a, b)` = every subset:

```txt
(a, b), (a), (b), ()
```

`CUBE(a, b, c)` = 2³ = **8 groupings**. Cost doubles per column — see [[day-05 - FAQs#15. Is `CUBE` expensive?]].

## The `GROUPING()` Function

Real `NULL` and structural `NULL` look identical. `GROUPING()` separates them:

```txt
GROUPING(col) = 1 -> row aggregated over col (structural NULL)
GROUPING(col) = 0 -> row grouped on col (any NULL is real data)
```

Critical for nullable columns like `projects.tasks.assignee_id`. See [[day-05 - FAQs#13. How do I tell "rolled up `NULL`" from "real `NULL`"?]].

## Practical Queries

### Example 1 — `GROUPING SETS` for a focused task report

*"Task counts per status, per project, and overall — skip per-(project, status)."*

```sql
SELECT
  project_id,
  status,
  COUNT(*) AS task_count
FROM projects.tasks
GROUP BY GROUPING SETS (
  (project_id),
  (status),
  ()
)
ORDER BY project_id NULLS LAST, status NULLS LAST;
```

Three blocks: per project, per status, grand total.

### Example 2 — `ROLLUP` for hierarchical task report

Natural hierarchy: **organization → project → task**.

```sql
SELECT
  p.organization_id,
  t.project_id,
  COUNT(*) AS task_count
FROM projects.tasks AS t
JOIN projects.projects AS p ON p.id = t.project_id
GROUP BY ROLLUP (p.organization_id, t.project_id)
ORDER BY p.organization_id NULLS LAST, t.project_id NULLS LAST;
```

Produces per-project rows, per-org subtotals, grand total.

### Example 3 — `CUBE` for cross-tab analysis

*"Task counts from every angle — per status, per assignee, per (status, assignee), and overall."*

```sql
SELECT
  status,
  assignee_id,
  COUNT(*) AS task_count
FROM projects.tasks
GROUP BY CUBE (status, assignee_id)
ORDER BY status NULLS LAST, assignee_id NULLS LAST;
```

Four kinds of rows: per (status, assignee), per status, per assignee, grand total.

### Example 4 — Labeling with `GROUPING()` (disambiguating real `NULL`)

`assignee_id` is nullable, so a `NULL` could mean unassigned OR rolled-up. `GROUPING()` separates them.

```sql
SELECT
  CASE WHEN GROUPING(status) = 1
       THEN 'All statuses'
       ELSE status
  END AS status,
  CASE
    WHEN GROUPING(assignee_id) = 1 THEN 'All assignees'
    WHEN assignee_id IS NULL       THEN 'Unassigned'
    ELSE assignee_id::TEXT
  END AS assignee,
  COUNT(*) AS task_count
FROM projects.tasks
GROUP BY ROLLUP (status, assignee_id)
ORDER BY GROUPING(status), status,
         GROUPING(assignee_id), assignee_id;
```

Output:

```txt
status       | assignee      | task_count
-------------+---------------+-----------
todo         | 3             |   2
todo         | Unassigned    |   4     ← real NULL in data
todo         | All assignees |   7     ← rolled up
in_progress  | 1             |   3
...
All statuses | All assignees |  47     ← grand total
```

### Example 5 — Filtering aggregation rows

Filter on `GROUPING()` in `HAVING`:

```sql
SELECT
  p.organization_id,
  t.status,
  COUNT(*) AS task_count
FROM projects.tasks AS t
JOIN projects.projects AS p ON p.id = t.project_id
GROUP BY ROLLUP (p.organization_id, t.status)
HAVING GROUPING(p.organization_id) = 0;   -- drop the grand total row
```

### Example 6 — Multi-table report: invitations by org and status

```sql
SELECT
  o.name AS organization,
  i.status,
  COUNT(*) AS invitation_count
FROM auth.invitations AS i
JOIN auth.organizations AS o ON o.id = i.organization_id
GROUP BY ROLLUP (o.name, i.status)
ORDER BY o.name NULLS LAST, i.status NULLS LAST;
```

Per-org per-status counts, per-org subtotals, grand total.

## Schema-specific note

`projects.tasks.assignee_id` is nullable — **always reach for `GROUPING()` when rolling up over it**, otherwise "unassigned" and "rolled up" collapse into the same-looking `NULL` row and the report lies.
