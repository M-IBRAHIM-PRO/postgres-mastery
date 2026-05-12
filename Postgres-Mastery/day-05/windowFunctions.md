# Window Functions — `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `LAG`, `LEAD`

For recipes see [[Advanced SQL Cheatsheet#3. Window Functions]]. For gotchas see [[day-05 - FAQs#Window Functions]]. Window mechanics: [[overClause]].

## Theory

A **window function** computes across a set of rows related to the current row — **without collapsing them into one row**.

This is the key difference from `GROUP BY`.

**Analogy: a runner looking at the leaderboard mid-race.**

At any moment, you can see your time, who is in front, who is behind, your rank. You haven't been merged with anyone — but you can see information about the group around you.

```txt
GROUP BY        = merge runners into one summary row per group
Window function = each runner stays separate, but sees position in the group
```

## The Core Distinction

Same data, two questions.

**`GROUP BY` — collapses rows:**

```sql
SELECT organization_id, COUNT(*) AS project_count
FROM projects.projects
GROUP BY organization_id;
```

One row per organization. Individual projects lost.

**Window function — keeps rows:**

```sql
SELECT
  id,
  name,
  organization_id,
  COUNT(*) OVER (PARTITION BY organization_id) AS project_count
FROM projects.projects;
```

Every project row stays. Each row shows its organization's project count.

```txt
GROUP BY = summarize and lose detail
Window   = summarize alongside the detail
```

## The `OVER (...)` Clause

Every window function uses `OVER (...)`. Full mental model in [[overClause]]. Short version:

```sql
function_name(...) OVER (
  PARTITION BY some_column     -- which group is the "window"?
  ORDER BY some_column         -- order inside that window
)
```

Without `PARTITION BY`, the window is the entire result set.

## The Five Functions

Two families.

### Ranking family — assign a position

| Function | What it does | Ties |
|---|---|---|
| `ROW_NUMBER()` | 1, 2, 3, … | unique numbers, ties broken arbitrarily |
| `RANK()` | ranks rows | ties tie, then **skips** |
| `DENSE_RANK()` | ranks rows | ties tie, no gaps |

For tie behavior detail and when to pick which, see [[day-05 - FAQs#9. `ROW_NUMBER` vs `RANK` vs `DENSE_RANK` — when does the choice matter?]].

### Offset family — peek at neighboring rows

| Function | What it does |
|---|---|
| `LAG(col)` | value from **previous** row in window |
| `LEAD(col)` | value from **next** row in window |

```txt
row 1: LAG = NULL,   LEAD = 10:05
row 2: LAG = 10:00,  LEAD = 10:12
row 3: LAG = 10:05,  LEAD = NULL
```

Both default to `NULL` at the edge, or accept a default: `LAG(col, 1, 0)`.

## Practical Queries

### Example 1 — Number projects inside each organization

```sql
SELECT
  organization_id,
  name,
  created_at,
  ROW_NUMBER() OVER (
    PARTITION BY organization_id
    ORDER BY created_at
  ) AS project_position
FROM projects.projects;
```

Number resets per organization because of `PARTITION BY`.

### Example 2 — Latest row per group (the killer pattern)

*"Most recently created project per organization."*

```sql
WITH ranked AS (
  SELECT
    id,
    organization_id,
    name,
    created_at,
    ROW_NUMBER() OVER (
      PARTITION BY organization_id
      ORDER BY created_at DESC
    ) AS rn
  FROM projects.projects
)
SELECT id, organization_id, name, created_at
FROM ranked
WHERE rn = 1;
```

Pattern: number rows inside each group ordered by what makes one "best", keep `rn = 1`. Works for latest order per customer, top score per player, current address per user.

For top-N per group, use `WHERE rn <= N`.

### Example 3 — `RANK` vs `DENSE_RANK` on organization size

```sql
WITH member_counts AS (
  SELECT organization_id, COUNT(*) AS members
  FROM auth.memberships
  GROUP BY organization_id
)
SELECT
  o.name,
  mc.members,
  RANK()       OVER (ORDER BY mc.members DESC) AS rank_with_gaps,
  DENSE_RANK() OVER (ORDER BY mc.members DESC) AS dense_rank_no_gaps
FROM member_counts mc
JOIN auth.organizations o ON o.id = mc.organization_id;
```

### Example 4 — Time between consecutive projects with `LAG`

```sql
SELECT
  organization_id,
  name,
  created_at,
  LAG(created_at) OVER (
    PARTITION BY organization_id
    ORDER BY created_at
  ) AS previous_project_at,
  created_at - LAG(created_at) OVER (
    PARTITION BY organization_id
    ORDER BY created_at
  ) AS gap
FROM projects.projects
ORDER BY organization_id, created_at;
```

First project per organization has `NULL` for both — no previous row.

Real uses for `LAG`: time between logins, diff between payments, detecting status changes.

### Example 5 — Looking forward with `LEAD`

```sql
SELECT
  organization_id,
  name,
  created_at,
  LEAD(created_at) OVER (
    PARTITION BY organization_id
    ORDER BY created_at
  ) AS next_project_at
FROM projects.projects;
```

### Example 6 — Multi-column tiebreaker

```sql
SELECT
  organization_id,
  name,
  ROW_NUMBER() OVER (
    PARTITION BY organization_id
    ORDER BY created_at DESC, id DESC
  ) AS rn
FROM projects.projects;
```

Without tiebreaker, rows with identical `created_at` could swap positions across runs.

## Where Window Functions Cannot Live

Window functions can only appear in `SELECT` and `ORDER BY` — **not** `WHERE`, `GROUP BY`, `HAVING`. Wrap in a CTE/subquery to filter on a window result. Reason and pattern: [[day-05 - FAQs#8. Why can't I use a window function in `WHERE`?]].
