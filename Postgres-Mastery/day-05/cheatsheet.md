# Advanced SQL Cheatsheet

Quick reference for CTEs, recursion, window functions, multi-level
aggregation, and `FILTER`. Examples use the Day 5 `teamsync` schema:

```txt
auth.users           (id, email, full_name, is_active, ...)
auth.organizations   (id, name, ...)
auth.memberships     (id, organization_id, user_id, role, ...)
auth.invitations     (id, organization_id, invited_by, email, status,
                      expires_at, ...)   -- status: pending|accepted|expired|revoked
projects.projects    (id, organization_id, created_by, name, metadata, ...)
projects.tasks       (id, project_id, title, status, assignee_id,
                      due_date, ...)     -- status: todo|in_progress|done|cancelled
events.activity_log  (id, occurred_at, actor_id, organization_id,
                      event_type, payload)
```

---

## 0. Pick The Right Tool

```txt
Reuse a subquery / break a big query into steps  -> CTE
Walk a tree (manager chain, threaded replies)    -> RECURSIVE CTE
Per-row calc across neighbors (rank, lag, lead)  -> Window function
Latest row per group / top-N per group           -> ROW_NUMBER + filter
Running totals, moving averages                  -> Aggregate OVER (...)
Multi-level totals + subtotals in one query      -> GROUPING SETS/ROLLUP/CUBE
Pivot rows into columns, multiple sliced metrics -> FILTER (WHERE …)
```

Two-rule sanity check:

```txt
"For each row, tell me about its neighbors"   -> window function
"For each group, give me one summary"         -> GROUP BY (+ ROLLUP/CUBE if multi-level)
```

---

## 1. CTE (`WITH`)

Named, temporary result set scoped to one query. Like scratch paper steps.

```sql
WITH active_users AS (
  SELECT id, email FROM auth.users
  WHERE is_active = true AND deleted_at IS NULL
),
member_counts AS (
  SELECT user_id, COUNT(*) AS orgs
  FROM auth.memberships
  GROUP BY user_id
)
SELECT u.email, COALESCE(m.orgs, 0) AS orgs
FROM active_users u
LEFT JOIN member_counts m ON m.user_id = u.id;
```

Data-modifying CTE (very common pattern):

```sql
WITH new_org AS (
  INSERT INTO auth.organizations (name) VALUES ('Orbit Labs')
  RETURNING id
)
INSERT INTO auth.memberships (organization_id, user_id, role)
SELECT id, 1, 'owner' FROM new_org;
```

Rules:

- Use a CTE when a subquery is **referenced more than once** or when steps need names.
- Don't reach for it on trivial single-use subqueries.
- PostgreSQL 12+: CTEs are inlined by default. Force one-time compute with `AS MATERIALIZED (...)`.

Memory hook:

```txt
WITH = "let me define these steps, then ask my real question"
```

---

## 2. Recursive CTE

Walk parent-child relationships of unknown depth.

```sql
-- All tasks created by user 1, plus the project they belong to,
-- isn't recursive. Use recursion for true hierarchies (manager chains,
-- folder trees, threaded comments). Sketch:

WITH RECURSIVE chain AS (
  -- Anchor: starting row(s)
  SELECT id, name, parent_id, 1 AS depth
  FROM some_tree
  WHERE id = :start

  UNION ALL

  -- Recursive step: reference the CTE itself
  SELECT t.id, t.name, t.parent_id, c.depth + 1
  FROM some_tree t
  JOIN chain c ON t.parent_id = c.id
  WHERE c.depth < 100               -- safety cap
)
SELECT * FROM chain;
```

Three parts:

- **Anchor** — runs once, the seed rows.
- **Recursive member** — references the CTE itself.
- **Termination** — natural (no more matches) or explicit (`WHERE depth < N`).

Generator (no table needed):

```sql
WITH RECURSIVE n AS (
  SELECT 1 AS i
  UNION ALL
  SELECT i + 1 FROM n WHERE i < 10
)
SELECT i FROM n;
```

Rules:

- Always have a stop condition. Cycles in data → infinite loop.
- Cap depth defensively (`WHERE depth < 100`) or use the `CYCLE` clause.

Memory hook:

```txt
Recursive CTE = "start here, then keep walking by this rule"
```

---

## 3. Window Functions

Per-row calculation across a related set of rows — **without collapsing** them.

```txt
GROUP BY        = summarize and lose detail
Window function = summarize alongside the detail
```

### 3.1 The Five Core Functions

| Function | Returns |
|---|---|
| `ROW_NUMBER()` | 1, 2, 3, … unique numbers (ties broken arbitrarily) |
| `RANK()` | ties tie, gaps after (1, 1, 3) |
| `DENSE_RANK()` | ties tie, no gaps (1, 1, 2) |
| `LAG(col [, n [, default]])` | value from previous row in window |
| `LEAD(col [, n [, default]])` | value from next row in window |

Score 100, 100, 90, 80:

```txt
ROW_NUMBER : 1 2 3 4
RANK       : 1 1 3 4   ← skips
DENSE_RANK : 1 1 2 3   ← no skip
```

### 3.2 `OVER (PARTITION BY … ORDER BY …)`

```sql
function(...) OVER (
  PARTITION BY ...      -- which group of rows is "my window"?
  ORDER BY ...          -- order inside that window
  ROWS BETWEEN ...      -- which subset can I see right now?
)
```

Mental model, three questions per row:

```txt
1. Which rows are in my window?     -> PARTITION BY
2. What order are they in?          -> ORDER BY inside OVER
3. Which of them can I actually see? -> the frame
```

Hidden trap — default frame when `ORDER BY` is present:

```txt
RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
```

This is why this gives a **running** total, not the partition total:

```sql
SUM(amount) OVER (PARTITION BY user_id ORDER BY created_at)
```

For a true partition total, either drop `ORDER BY` or set the frame explicitly:

```sql
SUM(amount) OVER (
  PARTITION BY user_id
  ORDER BY created_at
  ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
)
```

Frame keywords:

```txt
UNBOUNDED PRECEDING   from the very first row in the partition
N PRECEDING           N rows before current
CURRENT ROW           the row being processed
N FOLLOWING           N rows after current
UNBOUNDED FOLLOWING   to the very last row in the partition
```

`ROWS` = physical rows · `RANGE` = same value group · start with `ROWS`.

### 3.3 Where Window Functions Can Live

```txt
SELECT list   YES
ORDER BY      YES
WHERE         NO
GROUP BY      NO
HAVING        NO
```

To filter on a window result, wrap in a CTE/subquery:

```sql
WITH ranked AS (
  SELECT id, project_id, status, created_at,
         ROW_NUMBER() OVER (PARTITION BY project_id ORDER BY created_at DESC) AS rn
  FROM projects.tasks
)
SELECT * FROM ranked WHERE rn = 1;   -- latest task per project
```

### 3.4 Killer Patterns

**Latest row per group:**

```sql
WITH t AS (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY project_id ORDER BY created_at DESC) AS rn
  FROM projects.tasks
)
SELECT * FROM t WHERE rn = 1;
```

**Top N per group** — `WHERE rn <= N`.

**Time gap between rows:**

```sql
SELECT
  project_id, id, created_at,
  created_at - LAG(created_at) OVER (PARTITION BY project_id ORDER BY created_at) AS gap
FROM projects.tasks;
```

**Running count / total:**

```sql
SELECT
  organization_id, id, created_at,
  COUNT(*) OVER (PARTITION BY organization_id ORDER BY created_at) AS so_far
FROM projects.projects;
```

**Reusable named window:**

```sql
SELECT id, project_id,
  ROW_NUMBER() OVER w AS rn,
  LAG(status)  OVER w AS prev_status
FROM projects.tasks
WINDOW w AS (PARTITION BY project_id ORDER BY created_at);
```

---

## 4. `GROUPING SETS`, `ROLLUP`, `CUBE`

Multiple aggregation levels in one query. `NULL` in a group column = "this column was rolled up here."

```txt
GROUPING SETS  manual list of levels
ROLLUP(a,b,c)  hierarchy: (a,b,c), (a,b), (a), ()
CUBE(a,b)      every subset: (a,b), (a), (b), ()
```

### 4.1 `GROUPING SETS` — pick exact levels

```sql
SELECT project_id, status, COUNT(*) AS task_count
FROM projects.tasks
GROUP BY GROUPING SETS (
  (project_id),    -- per project
  (status),        -- per status
  ()               -- grand total
);
```

### 4.2 `ROLLUP` — hierarchical subtotals

```sql
SELECT p.organization_id, t.project_id, COUNT(*) AS task_count
FROM projects.tasks t
JOIN projects.projects p ON p.id = t.project_id
GROUP BY ROLLUP (p.organization_id, t.project_id);
```

Produces per-project rows, per-org subtotals, and grand total.

### 4.3 `CUBE` — every combination

```sql
SELECT status, assignee_id, COUNT(*) AS task_count
FROM projects.tasks
GROUP BY CUBE (status, assignee_id);
```

2ⁿ groupings. Use sparingly.

### 4.4 `GROUPING()` — distinguish "rolled up" from real NULL

Critical when grouping on nullable columns (e.g. `assignee_id`):

```sql
SELECT
  CASE WHEN GROUPING(status)      = 1 THEN 'All statuses'   ELSE status            END AS status,
  CASE WHEN GROUPING(assignee_id) = 1 THEN 'All assignees'
       WHEN assignee_id IS NULL        THEN 'Unassigned'
       ELSE assignee_id::TEXT
  END AS assignee,
  COUNT(*) AS task_count
FROM projects.tasks
GROUP BY ROLLUP (status, assignee_id)
ORDER BY GROUPING(status), status, GROUPING(assignee_id), assignee_id;
```

```txt
GROUPING(col) = 1 -> this row aggregates over col (structural NULL)
GROUPING(col) = 0 -> this row is grouped on col (any NULL is real)
```

Filter unwanted levels in `HAVING`:

```sql
HAVING GROUPING(organization_id) = 0;   -- drop grand total
```

Memory hook:

```txt
GROUP BY  = one summary
ROLLUP    = subtotals at each level
CUBE      = every angle
GROUPING SETS = exactly these levels
```

---

## 5. `FILTER (WHERE …)`

Per-aggregate condition. Multiple sliced metrics in one scan.

```sql
SELECT
  project_id,
  COUNT(*)                                       AS total,
  COUNT(*) FILTER (WHERE status = 'todo')        AS todo,
  COUNT(*) FILTER (WHERE status = 'in_progress') AS in_progress,
  COUNT(*) FILTER (WHERE status = 'done')        AS done,
  COUNT(*) FILTER (WHERE status = 'cancelled')   AS cancelled
FROM projects.tasks
GROUP BY project_id;
```

Replaces the old `COUNT(CASE WHEN … THEN 1 END)` trick — works correctly with `COUNT`, `SUM`, `AVG`, `STRING_AGG`, etc.

```txt
WHERE   = drops rows for the whole query
FILTER  = each aggregate counts only matching rows
```

### Patterns

**Pivot rows → columns:** see example above.

**Acceptance / completion rate in one query:**

```sql
SELECT
  organization_id,
  COUNT(*)                                      AS sent,
  COUNT(*) FILTER (WHERE status = 'accepted')   AS accepted,
  ROUND(100.0 *
    COUNT(*) FILTER (WHERE status = 'accepted')
    / NULLIF(COUNT(*), 0), 1)                   AS accept_rate_pct
FROM auth.invitations
GROUP BY organization_id;
```

**Status-sliced sum:**

```sql
SELECT
  organization_id,
  SUM((metadata->>'budget')::int)                                               AS total,
  SUM((metadata->>'budget')::int) FILTER (WHERE metadata->>'status' = 'active') AS active
FROM projects.projects
GROUP BY organization_id;
```

**FILTER + window:**

```sql
SELECT
  project_id, id, status, created_at,
  COUNT(*) FILTER (WHERE status = 'done') OVER (
    PARTITION BY project_id ORDER BY created_at
  ) AS done_so_far
FROM projects.tasks;
```

### `FILTER` vs `WHERE`

```txt
                  WHERE                FILTER
Scope             whole query          single aggregate
Effect            drops rows           selective counting
Multiple metrics? no                   yes
Use for           narrowing data       per-column conditions
```

Memory hook:

```txt
FILTER = "this aggregate, but only when..."
```

---

## 6. Common Recipes

### Latest row per group

```sql
WITH t AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY g ORDER BY ts DESC) AS rn
  FROM tbl
)
SELECT * FROM t WHERE rn = 1;
```

### Top-N per group

```sql
WITH t AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY g ORDER BY score DESC) AS rn
  FROM tbl
)
SELECT * FROM t WHERE rn <= N;
```

### Wide status report (pivot)

```sql
SELECT g,
  COUNT(*) FILTER (WHERE s = 'a') AS a,
  COUNT(*) FILTER (WHERE s = 'b') AS b,
  COUNT(*) FILTER (WHERE s = 'c') AS c
FROM tbl GROUP BY g;
```

### Monthly metrics dashboard

```sql
SELECT
  DATE_TRUNC('month', occurred_at)::date AS month,
  COUNT(*)                                          AS total,
  COUNT(*) FILTER (WHERE event_type = 'x')          AS x,
  COUNT(DISTINCT actor_id)                          AS uniq_actors
FROM events.activity_log
GROUP BY 1 ORDER BY 1;
```

### Hierarchical report (org > project > task)

```sql
SELECT p.organization_id, t.project_id, COUNT(*) AS tasks
FROM projects.tasks t
JOIN projects.projects p ON p.id = t.project_id
GROUP BY ROLLUP (p.organization_id, t.project_id);
```

### Running total + percent-of-group

```sql
SELECT
  g, id, amount,
  SUM(amount) OVER (PARTITION BY g ORDER BY ts) AS running,
  amount * 1.0 / SUM(amount) OVER (PARTITION BY g) AS pct_of_group
FROM tbl;
```

### Tree walk

```sql
WITH RECURSIVE tree AS (
  SELECT id, parent_id, name, 1 AS depth, name::text AS path
  FROM t WHERE parent_id IS NULL
  UNION ALL
  SELECT c.id, c.parent_id, c.name, p.depth + 1, p.path || ' > ' || c.name
  FROM t c JOIN tree p ON c.parent_id = p.id
  WHERE p.depth < 50
)
SELECT * FROM tree;
```

### Insert + dependent insert in one statement

```sql
WITH new_row AS (
  INSERT INTO parent (...) VALUES (...) RETURNING id
)
INSERT INTO child (parent_id, ...)
SELECT id, ... FROM new_row;
```

---

## 7. Gotchas

```txt
1. WHERE cannot reference window functions or aggregates. Wrap in CTE.
2. ORDER BY inside OVER changes the default frame (running, not total).
3. NULL from CUBE/ROLLUP looks like real NULL. Use GROUPING() to tell apart.
4. RANK skips numbers after ties. DENSE_RANK doesn't. ROW_NUMBER ignores ties.
5. Recursive CTEs need a stop condition; cycles loop forever.
6. CUBE columns multiply: 2 cols = 4 groupings, 4 cols = 16. Use GROUPING SETS for control.
7. FILTER replaces COUNT(CASE WHEN ... THEN 1 END). Prefer it.
8. CTEs in PG12+ are inlined; AS MATERIALIZED forces one-time compute.
9. Always alias tables in multi-join window queries; window functions reference cols by alias-qualified name.
10. Window function ORDER BY ≠ query's final ORDER BY. They're independent.
```

---

## 8. Final Mental Model

```txt
WITH     -> name your steps
RECURSIVE -> name your steps, then loop them
OVER     -> per row, see neighbors (partition, order, frame)
ROLLUP   -> multiple summaries, hierarchical
GROUPING SETS -> multiple summaries, exact list
CUBE     -> multiple summaries, all combos
FILTER   -> per-aggregate condition
```

Combine freely. A real report often uses CTEs to stage data, window
functions inside a CTE to rank, `FILTER` in the final select to pivot,
and `ROLLUP` if subtotals are needed.