# Advanced SQL FAQs

Tricky questions, confusion points, and tradeoffs for CTEs, recursion,
window functions, multi-level aggregation, and `FILTER`.

No definitions here — only the things that actually trip people up.

For syntax, see [[Advanced SQL Cheatsheet]].

---

## CTE (`WITH`)

### 1. Does using a CTE hurt performance?

Not on PostgreSQL 12+. CTEs are **inlined by default** and optimized like
subqueries. Old advice ("CTEs are an optimization fence") only applied
before PG12.

If you want the old behavior — compute once, reuse — force it:

```sql
WITH heavy AS MATERIALIZED (
  SELECT ... -- expensive computation
)
SELECT * FROM heavy WHERE ...
UNION ALL
SELECT * FROM heavy WHERE ...
```

Rule:

```txt
PG12+:        CTE = inlined (cheap), CTE AS MATERIALIZED = forced one-time
PG11 and older: CTE = optimization fence (always materialized)
```

---

### 2. CTE vs subquery — when does it matter?

Functionally they're equivalent in PG12+. The choice is **readability**.

Pick CTE when:

- the intermediate result is **referenced more than once**
- the query has **3+ logical steps** that benefit from names
- you're writing a **data-modifying CTE** (the only thing subqueries can't do)

Pick a subquery when:

- it's used once
- it's trivially short
- naming it would add no clarity

Memory hook:

```txt
Use a CTE when you'd otherwise want to name the subquery anyway.
```

---

### 3. Can a CTE modify data?

Yes. CTEs can wrap `INSERT`, `UPDATE`, `DELETE` with `RETURNING`. This is one
of the most useful patterns — chain dependent writes in one statement:

```sql
WITH new_org AS (
  INSERT INTO auth.organizations (name) VALUES ('Acme')
  RETURNING id
)
INSERT INTO auth.memberships (organization_id, user_id, role)
SELECT id, 1, 'owner' FROM new_org;
```

The whole statement runs atomically — no half-state if step 2 fails.

Note: each modifying CTE sees the table at the **same snapshot**. A later CTE
won't see rows inserted by an earlier one. For visible chaining, use the
`RETURNING` clause as shown above.

---

## Recursive CTE

### 4. Why `UNION ALL` instead of `UNION`?

`UNION` deduplicates — which forces PostgreSQL to compare every new row against
every existing row in the CTE. That's slow.

`UNION ALL` keeps everything. Recursive CTEs almost always want `UNION ALL`.

If duplicates are possible in your traversal (e.g. a graph with multiple paths
to the same node), handle them explicitly — either with `UNION` knowingly, or
by tracking visited IDs in an array.

```txt
UNION ALL = fast, allows duplicates
UNION     = slower, removes duplicates implicitly
```

---

### 5. What happens if my data has a cycle?

The recursive CTE **runs forever** (until PostgreSQL hits a memory/time limit).
PostgreSQL doesn't detect cycles automatically.

Two defenses:

**Depth cap** — simple, always works:

```sql
WITH RECURSIVE walk AS (
  SELECT id, parent_id, 1 AS depth FROM t WHERE id = :start
  UNION ALL
  SELECT t.id, t.parent_id, w.depth + 1
  FROM t JOIN walk w ON t.parent_id = w.id
  WHERE w.depth < 100        -- stop bound
)
SELECT * FROM walk;
```

**`CYCLE` clause** — explicit cycle detection (PG14+):

```sql
WITH RECURSIVE walk AS (
  SELECT id, parent_id FROM t WHERE id = :start
  UNION ALL
  SELECT t.id, t.parent_id FROM t JOIN walk w ON t.parent_id = w.id
) CYCLE id SET is_cycle USING path
SELECT * FROM walk WHERE NOT is_cycle;
```

Rule:

```txt
Always have a stop condition. Either depth cap or CYCLE clause.
```

---

### 6. My recursive CTE returns nothing or wrong data — why?

Three common causes:

1. **Wrong join direction.** Going downward (parent → children)?
   The recursive step joins `child.parent_id = anchor.id`.
   Going upward (child → ancestors)? Join `anchor.parent_id = parent.id`.
   Swap these and you get nothing or the wrong subtree.

2. **Anchor returns no rows.** If the seed query matches nothing, the whole
   result is empty. Test the anchor alone first.

3. **Recursive member never terminates the chain.** If the join condition
   stays true forever (e.g. cycle), see FAQ 5.

Debug by running just the anchor as a regular SELECT, then add the recursive
step.

---

## Window Functions

### 7. Window function vs `GROUP BY` — when which?

```txt
"For each row, tell me something about its neighbors" -> window function
"For each group, give me one summary row"             -> GROUP BY
```

If you want to **keep every row** but add a calculation (rank, running total,
"latest per group" markers, gap-to-previous-row) → window function.

If you want **one row per group** → `GROUP BY`.

You can do both in one query: `GROUP BY` first to aggregate, then a window
function on the aggregated result.

---

### 8. Why can't I use a window function in `WHERE`?

Because of **execution order**. `WHERE` runs before window functions are
computed:

```txt
FROM -> WHERE -> GROUP BY -> HAVING -> window functions -> SELECT -> ORDER BY
```

So PostgreSQL doesn't know the `ROW_NUMBER` value yet when it evaluates `WHERE`.

Fix: wrap in a CTE or subquery and filter outside.

```sql
WITH ranked AS (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY project_id ORDER BY created_at DESC) AS rn
  FROM projects.tasks
)
SELECT * FROM ranked WHERE rn = 1;   -- latest task per project
```

Same restriction applies to `GROUP BY` and `HAVING`. Window functions only
work in `SELECT` and `ORDER BY`.

---

### 9. `ROW_NUMBER` vs `RANK` vs `DENSE_RANK` — when does the choice matter?

Only with **ties in the `ORDER BY` column**. For tie-free orderings they all
produce the same numbers.

```txt
Score 100, 100, 90, 80:
ROW_NUMBER : 1 2 3 4   ← ties broken arbitrarily, all unique
RANK       : 1 1 3 4   ← ties tie, then skip
DENSE_RANK : 1 1 2 3   ← ties tie, no gaps
```

Practical guide:

```txt
Need exactly one row per group (e.g. "latest")    -> ROW_NUMBER
Need true competition ranking (Olympics-style)    -> RANK
Need tier counting ("how many distinct levels?")  -> DENSE_RANK
```

For `ROW_NUMBER` with ties, always add a tiebreaker so results are stable:

```sql
ROW_NUMBER() OVER (PARTITION BY g ORDER BY created_at DESC, id DESC)
```

---

### 10. Why does my `SUM OVER (...)` return a running total instead of the partition total?

This is **the** window function trap. The cause is the default frame.

When `ORDER BY` is present in `OVER`, the default frame is:

```txt
RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
```

That means: "from the start of the partition to the current row." That's a
running total, not a partition total.

```sql
-- Running total (often unintended)
SUM(amount) OVER (PARTITION BY user_id ORDER BY created_at)

-- True partition total
SUM(amount) OVER (PARTITION BY user_id)

-- Or with explicit full frame
SUM(amount) OVER (
  PARTITION BY user_id ORDER BY created_at
  ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
)
```

Rule:

```txt
If a window aggregate "looks wrong", check the frame first.
ORDER BY inside OVER silently changes the default frame.
```

---

### 11. Does `ORDER BY` inside `OVER` affect the final row order?

No. They're independent.

- `ORDER BY` inside `OVER` orders rows **within the window** (so the function
  knows what "previous" or "running" means).
- `ORDER BY` at the end of the query orders the **final result**.

```sql
SELECT
  name,
  ROW_NUMBER() OVER (ORDER BY created_at) AS join_order
FROM auth.users
ORDER BY name;   -- final output is alphabetical by name, not by join_order
```

You almost always want both. Don't assume one implies the other.

---

## `GROUPING SETS`, `ROLLUP`, `CUBE`

### 12. `ROLLUP` vs `CUBE` vs `GROUPING SETS` — when each?

```txt
Hierarchy with natural levels (year > month > day)   -> ROLLUP
Cross-tab / every combination                        -> CUBE
You know exactly which levels you want               -> GROUPING SETS
```

`ROLLUP(a, b, c)` = 4 levels. `CUBE(a, b, c)` = 8 levels. `GROUPING SETS`
gives you only what you ask for.

For production reports, **prefer `GROUPING SETS`** — it's the most explicit
and the cheapest.

---

### 13. How do I tell "rolled up `NULL`" from "real `NULL`"?

They look identical in output. Use `GROUPING()`:

```txt
GROUPING(col) = 1 -> col was aggregated over (structural NULL)
GROUPING(col) = 0 -> row is grouped on col (any NULL is real data)
```

This matters when grouping on **nullable columns** like
`projects.tasks.assignee_id`:

```sql
SELECT
  CASE
    WHEN GROUPING(assignee_id) = 1 THEN 'All assignees'
    WHEN assignee_id IS NULL       THEN 'Unassigned'
    ELSE assignee_id::text
  END AS assignee,
  COUNT(*) AS task_count
FROM projects.tasks
GROUP BY ROLLUP (assignee_id);
```

Without `GROUPING()`, "unassigned tasks" and "rolled-up total" collapse into
the same-looking row, and the report lies.

---

### 14. Does column order matter in `ROLLUP`?

**Yes.** `ROLLUP(a, b)` is not the same as `ROLLUP(b, a)`.

```txt
ROLLUP(a, b) levels:    (a, b), (a),     ()
ROLLUP(b, a) levels:    (b, a), (b),     ()
```

`ROLLUP` peels from the **right**. Put the outermost level of the hierarchy
first.

For org → project → task: write `ROLLUP(org_id, project_id)`, not the
reverse.

`CUBE` doesn't care about order — it generates all subsets either way.

---

### 15. Is `CUBE` expensive?

Yes, exponentially. `CUBE(a, b, c, d)` produces **2⁴ = 16** different groupings.

For wide reports, switch to `GROUPING SETS` and list only the levels you need:

```sql
-- Expensive
GROUP BY CUBE (a, b, c, d)              -- 16 groupings

-- Explicit and cheaper
GROUP BY GROUPING SETS (
  (a, b),                                -- only what you actually need
  (a, c),
  (a),
  ()
)
```

Rule:

```txt
Be explicit. CUBE is exploratory; production reports use GROUPING SETS.
```

---

## `FILTER (WHERE …)`

### 16. `FILTER` vs `WHERE` — what's the actual difference?

`WHERE` runs once for the whole query and **drops rows**.
`FILTER` attaches to **one aggregate** and changes only what that aggregate
counts.

```sql
-- Only counts 'done' tasks. The query never sees other statuses.
SELECT COUNT(*) FROM projects.tasks WHERE status = 'done';

-- Counts all tasks, AND separately counts 'done' tasks.
SELECT
  COUNT(*)                                AS total,
  COUNT(*) FILTER (WHERE status = 'done') AS done
FROM projects.tasks;
```

```txt
WHERE   = whole-query filter, drops rows
FILTER  = per-aggregate filter, selective counting
```

Use both together when needed: `WHERE` narrows the data, `FILTER` slices the
metrics.

---

### 17. Why prefer `FILTER` over `CASE WHEN` inside an aggregate?

`COUNT(CASE WHEN cond THEN 1 END)` works but is fragile:

- Different syntax for `COUNT`, `SUM`, `AVG` (e.g. `AVG` mishandles `CASE` +
  `NULL`).
- Harder to read; reader must reverse-engineer the trick.
- Doesn't compose cleanly with `DISTINCT`.

`FILTER` is explicit, uniform across aggregates, and reads as English:

```sql
COUNT(*) FILTER (WHERE status = 'done')
SUM(amount) FILTER (WHERE currency = 'USD')
AVG(score) FILTER (WHERE attempted = true)
COUNT(DISTINCT user_id) FILTER (WHERE event_type = 'login')
```

Rule:

```txt
If you're tempted to write CASE WHEN inside an aggregate, write FILTER.
```

---

### 18. Can `FILTER` work with window functions?

Yes — and this is one of the most useful advanced patterns.

```sql
SELECT
  project_id, id, status, created_at,
  COUNT(*) FILTER (WHERE status = 'done') OVER (
    PARTITION BY project_id ORDER BY created_at
  ) AS done_so_far
FROM projects.tasks;
```

The window decides **which rows are visible** to the aggregate. The `FILTER`
decides **which of those rows are counted**.

```txt
OVER (...) defines the window
FILTER (...) defines the metric within the window
```

This combination lets you build running rates, conversion funnels over time,
and rolling status counts inside a single query.

---

## Cross-Topic

### 19. When do these tools combine naturally?

Real production queries usually stack several:

```txt
CTE                -> stage the data
window function    -> rank, lag, running totals
GROUP BY / ROLLUP  -> aggregate with subtotals
FILTER             -> pivot into wide columns
```

Typical shape of a serious analytical query:

```sql
WITH base AS (
  -- staged, joined data
  SELECT ...
),
ranked AS (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY g ORDER BY ts DESC) AS rn
  FROM base
)
SELECT
  group_col,
  COUNT(*)                                       AS total,
  COUNT(*) FILTER (WHERE status = 'done')        AS done,
  COUNT(*) FILTER (WHERE status = 'pending')     AS pending
FROM ranked
WHERE rn = 1
GROUP BY ROLLUP (group_col);
```

That's CTE + window + FILTER + ROLLUP in one query. Each tool does one job.

---

### 20. Which of these are PostgreSQL-only?

Mostly portable, with caveats:

```txt
CTE (WITH)                 SQL standard, supported almost everywhere
Recursive CTE              SQL standard, supported in MySQL 8+, PG, SQL Server, Oracle
Window functions           SQL standard, supported broadly (MySQL 8+)
GROUPING SETS/ROLLUP/CUBE  SQL standard, but some DBs (older MySQL) lack full support
FILTER (WHERE ...)         SQL standard, but MANY databases don't support it
  - PostgreSQL: yes
  - SQLite: yes (3.30+)
  - MySQL: NO (use CASE WHEN)
  - SQL Server: NO (use CASE WHEN)
```

If you're writing portable SQL, `FILTER` is the one to watch — fall back to
`CASE WHEN` when targeting MySQL or SQL Server. Everything else is broadly
safe.