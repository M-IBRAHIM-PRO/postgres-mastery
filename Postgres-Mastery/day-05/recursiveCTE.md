# Recursive CTE — Tree & Hierarchy Traversal

For recipes see [[Advanced SQL Cheatsheet#2. Recursive CTE]]. For gotchas see [[day-05 - FAQs#Recursive CTE]]. Base form: [[CTE]].

## Theory

A **recursive CTE** is a CTE that **references itself**. Used to walk parent-child data of unknown depth.

**Analogy: family tree exploration.**

To find all descendants of one person without knowing tree depth:

1. Start with the person (the **anchor**).
2. Find their direct children.
3. For each child, find *their* children.
4. Repeat until nobody has new children.
5. Combine everything found.

A recursive CTE re-runs itself, feeding its own output back as input, until no new rows come out.

```txt
Regular CTE     = one named step
Recursive CTE   = a step that keeps re-running on its own output
```

## When You Need It

Problems with **unknown depth**:

- org charts (manager → employee → their reports → …)
- folder trees
- threaded comments
- category hierarchies
- graph traversal
- generating sequences (1, 2, 3, …, N)

```txt
If you can't write the JOIN count up front, you need recursion.
```

## Syntax

```sql
WITH RECURSIVE cte_name AS (
  -- Anchor member: starting rows (runs once)
  SELECT ...

  UNION ALL

  -- Recursive member: references cte_name itself (runs repeatedly)
  SELECT ...
  FROM cte_name
  JOIN some_table ON ...
)
SELECT * FROM cte_name;
```

Three required parts:

1. **`RECURSIVE` keyword** — tells PostgreSQL the CTE refers to itself.
2. **Anchor member** — the seed rows.
3. **Recursive member** — references the CTE itself.
4. **`UNION ALL`** — combines anchor + recursive results. Why not `UNION`: see [[day-05 - FAQs#4. Why `UNION ALL` instead of `UNION`?]].

### How It Executes

```txt
Step 1: Run anchor. Result goes into a "working set."
Step 2: Run recursive member, using the working set as input.
Step 3: New rows become the next working set.
Step 4: Repeat step 2 until the recursive member returns 0 rows.
Step 5: Final result = anchor + all recursive iterations combined.
```

Visual:

```txt
Anchor:    [row A]
Iter 1:    [row A's children]
Iter 2:    [grandchildren]
Iter 3:    [great-grandchildren]
Iter 4:    []  ← stop
Final:     all combined
```

## A Setup Table for Examples

`teamsync` has no hierarchy by default. Add **employees with managers**:

```sql
CREATE TABLE auth.employees (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    manager_id BIGINT REFERENCES auth.employees(id)
);

INSERT INTO auth.employees (id, name, manager_id) VALUES
  (1, 'Ibrahim (CEO)',  NULL),
  (2, 'Sarah (CTO)',    1),
  (3, 'Ali (Eng Mgr)',  2),
  (4, 'Fatima (Dev)',   3),
  (5, 'John (Dev)',     3),
  (6, 'Hina (Designer)', 2);
```

Tree:

```txt
Ibrahim
└── Sarah
    ├── Ali
    │   ├── Fatima
    │   └── John
    └── Hina
```

## Practical Queries

### Example 1 — All employees under Ibrahim (downward)

```sql
WITH RECURSIVE org_tree AS (
  -- Anchor: start with Ibrahim
  SELECT id, name, manager_id, 1 AS depth
  FROM auth.employees
  WHERE id = 1

  UNION ALL

  -- Recursive: find people whose manager is already in the tree
  SELECT e.id, e.name, e.manager_id, ot.depth + 1
  FROM auth.employees AS e
  JOIN org_tree AS ot
    ON e.manager_id = ot.id
)
SELECT id, name, depth
FROM org_tree
ORDER BY depth, id;
```

Result:

```txt
id | name           | depth
---+----------------+------
 1 | Ibrahim (CEO)  | 1
 2 | Sarah (CTO)    | 2
 3 | Ali (Eng Mgr)  | 3
 6 | Hina           | 3
 4 | Fatima         | 4
 5 | John           | 4
```

Recursive part reads: *"add anyone whose manager is already in `org_tree`."* That single rule unfolds the whole subtree.

### Example 2 — Management chain above Fatima (upward)

Same pattern, reversed direction.

```sql
WITH RECURSIVE chain AS (
  -- Anchor: start with Fatima
  SELECT id, name, manager_id
  FROM auth.employees
  WHERE name = 'Fatima (Dev)'

  UNION ALL

  -- Recursive: walk upward to each manager
  SELECT e.id, e.name, e.manager_id
  FROM auth.employees AS e
  JOIN chain AS c
    ON c.manager_id = e.id
)
SELECT id, name FROM chain;
```

Result: Fatima → Ali → Sarah → Ibrahim.

### Example 3 — Visual path (breadcrumb)

Track the path as you walk down.

```sql
WITH RECURSIVE org_tree AS (
  SELECT
    id,
    name,
    manager_id,
    1 AS depth,
    name::TEXT AS path
  FROM auth.employees
  WHERE manager_id IS NULL

  UNION ALL

  SELECT
    e.id,
    e.name,
    e.manager_id,
    ot.depth + 1,
    ot.path || ' > ' || e.name
  FROM auth.employees AS e
  JOIN org_tree AS ot
    ON e.manager_id = ot.id
)
SELECT depth, path
FROM org_tree
ORDER BY path;
```

Each iteration appends to the previous path.

### Example 4 — Generate a number sequence (no table needed)

```sql
WITH RECURSIVE counter AS (
  SELECT 1 AS n

  UNION ALL

  SELECT n + 1
  FROM counter
  WHERE n < 10
)
SELECT n FROM counter;
-- 1, 2, 3, ..., 10
```

`WHERE n < 10` is the stopping condition.

## Termination

A recursive CTE must eventually stop, or it runs forever. See [[day-05 - FAQs#5. What happens if my data has a cycle?]] for cycle handling and the `CYCLE` clause.

Quick defense — depth cap:

```sql
JOIN org_tree AS ot ON e.manager_id = ot.id
WHERE ot.depth < 100      -- safety cap
```
