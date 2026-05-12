# `OVER (PARTITION BY … ORDER BY …)` Mental Model

For recipes see [[Advanced SQL Cheatsheet#3.2 `OVER (PARTITION BY … ORDER BY …)`]]. For gotchas see [[day-05 - FAQs#Window Functions]]. Functions that use this clause: [[windowFunctions]].

## Theory

`OVER` defines **the window** — the set of rows the function can see when computing a value for the current row.

**Analogy: a moving spotlight on a stage.**

Imagine a stage full of performers in a line. A spotlight moves from one performer to the next. For each performer:

- the spotlight has a **width** — how many neighbors it illuminates
- the stage may be divided by **curtains** — spotlight never crosses a curtain
- performers stand in some **order** within their section

```txt
PARTITION BY = curtains that divide the stage into sections
ORDER BY     = the order performers stand in within a section
Frame        = how wide the spotlight is around the current performer
```

## The Three Pieces of `OVER`

```sql
function(...) OVER (
  PARTITION BY ...   -- 1. Which rows belong to my window?
  ORDER BY ...       -- 2. What order are they in?
  ROWS BETWEEN ...   -- 3. Which subset can I see right now?
)
```

Each piece is optional. Each changes the window.

### 1. `PARTITION BY` — the curtains

Splits rows into independent groups. The window function restarts inside each group.

```sql
ROW_NUMBER() OVER (PARTITION BY organization_id ORDER BY created_at)
```

Rows of org 1 form one window. Rows of org 2 form another. Counter restarts at 1 per group.

Without `PARTITION BY`, the whole table is one window.

### 2. `ORDER BY` (inside `OVER`) — the sequence

Defines order **within** the window. Required for ranking functions, offset functions, and running totals.

**Independent from the query's final `ORDER BY`:**

```sql
SELECT
  name,
  ROW_NUMBER() OVER (ORDER BY created_at) AS rn
FROM projects.projects
ORDER BY name;   -- final output is by name, not by rn
```

See [[day-05 - FAQs#11. Does `ORDER BY` inside `OVER` affect the final row order?]].

### 3. The Frame — the spotlight width

Even after `PARTITION BY` and `ORDER BY`, the function may not see all rows in the partition. It sees a **frame** — a subset relative to the current row.

```sql
ROWS BETWEEN <start> AND <end>
```

Boundaries:

```txt
UNBOUNDED PRECEDING   = from the very first row in the partition
N PRECEDING           = N rows before current
CURRENT ROW           = the row being processed
N FOLLOWING           = N rows after current
UNBOUNDED FOLLOWING   = to the very last row in the partition
```

#### The default frame: the hidden trap

When `ORDER BY` is present without an explicit frame, default is:

```txt
RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
```

Without `ORDER BY`, default is the whole partition.

This is why running sums work automatically:

```sql
SUM(amount) OVER (PARTITION BY user_id ORDER BY created_at)
-- = running total: "everything from the start up to here"
```

And why this does NOT give an overall average:

```sql
AVG(amount) OVER (PARTITION BY user_id ORDER BY created_at)
-- = running average up to each row
```

For true partition average, drop `ORDER BY` or set frame explicitly:

```sql
AVG(amount) OVER (
  PARTITION BY user_id
  ORDER BY created_at
  ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
)
```

Full discussion: [[day-05 - FAQs#10. Why does my `SUM OVER (...)` return a running total instead of the partition total?]].

#### `ROWS` vs `RANGE`

- `ROWS` counts **physical rows** ("the 3 rows before me").
- `RANGE` looks at **values** ("rows with the same `ORDER BY` value as me, plus everything before").

Ranking functions don't use frames. For aggregates with ties in the order column, the difference matters. Start with `ROWS`.

## Putting It Together

Per row PostgreSQL processes:

```txt
1. Which partition am I in?           -> PARTITION BY
2. Where am I in the partition order? -> ORDER BY inside OVER
3. What rows around me can I see?     -> the frame
4. Run the function over visible rows -> result for this row
```

## Practical Queries

### Example 1 — Same function, four different windows

`COUNT(*)` four ways.

```sql
SELECT
  organization_id,
  name,
  created_at,

  -- (a) total rows in the whole table
  COUNT(*) OVER ()                                     AS total_projects,

  -- (b) total rows in this organization
  COUNT(*) OVER (PARTITION BY organization_id)         AS org_projects,

  -- (c) running count within the organization
  COUNT(*) OVER (
    PARTITION BY organization_id
    ORDER BY created_at
  )                                                    AS running_count,

  -- (d) running count across the whole table
  COUNT(*) OVER (ORDER BY created_at)                  AS global_running_count

FROM projects.projects
ORDER BY organization_id, created_at;
```

- (a) Empty `OVER ()` → window is everything.
- (b) `PARTITION BY` only → window is the org.
- (c) `PARTITION BY` + `ORDER BY` → "rows in org up to and including me."
- (d) `ORDER BY` only → one big partition, "rows up to and including me."

This single query is the whole mental model.

### Example 2 — Each project's share of its organization

```sql
SELECT
  organization_id,
  name,
  1.0 / COUNT(*) OVER (PARTITION BY organization_id) AS share_of_org
FROM projects.projects;
```

For an org with 3 projects, each row shows `0.333…`.

### Example 3 — Explicit frame: 3-row moving window

```sql
SELECT
  organization_id,
  name,
  created_at,
  AVG(EXTRACT(EPOCH FROM created_at)) OVER (
    PARTITION BY organization_id
    ORDER BY created_at
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS avg_epoch_last_3
FROM projects.projects;
```

Frame is "me and the 2 rows behind me, within my org." Moving averages.

### Example 4 — Default-frame gotcha, made visible

```sql
SELECT
  organization_id,
  name,
  created_at,

  -- Looks like "total per org," but is a running count
  COUNT(*) OVER (PARTITION BY organization_id ORDER BY created_at) AS looks_like_total,

  -- Actual total per org
  COUNT(*) OVER (PARTITION BY organization_id)                     AS real_total
FROM projects.projects
ORDER BY organization_id, created_at;
```

Two columns differ. That difference is the default frame at work.

### Example 5 — Naming a window with `WINDOW`

When several functions share a window:

```sql
SELECT
  organization_id,
  name,
  ROW_NUMBER() OVER w  AS rn,
  COUNT(*)      OVER w AS org_total,
  LAG(name)     OVER w AS prev_project
FROM projects.projects
WINDOW w AS (PARTITION BY organization_id ORDER BY created_at)
ORDER BY organization_id, created_at;
```
