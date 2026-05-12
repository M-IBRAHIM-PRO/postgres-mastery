# CTE — Common Table Expressions

For recipes see [[Advanced SQL Cheatsheet#1. CTE (`WITH`)]]. For gotchas see [[day-05 - FAQs#CTE (`WITH`)]]. Recursive form: [[recursiveCTE]].

## Theory

A **CTE (Common Table Expression)** is a named temporary result set scoped to one query.

**Analogy: scratch paper before the final answer.**

Solving a math word problem, you don't write everything in one giant equation. You write intermediate steps with names. The final answer references those steps.

A CTE works the same way. Name an intermediate result, then use that name later as if it were a table.

```txt
Without CTE = one big nested query
With CTE    = named steps that read like a recipe
```

## Why CTEs Matter

1. **Readability** — sequence of named steps instead of inside-out nested subqueries.
2. **Reuse** — reference the same intermediate result multiple times.
3. **Decomposition** — large problems break into small, named pieces.

**Without CTE — nested subquery:**

```sql
SELECT *
FROM (
  SELECT organization_id, COUNT(*) AS project_count
  FROM projects.projects
  GROUP BY organization_id
) AS counts
WHERE project_count > 2;
```

**With CTE — named step:**

```sql
WITH project_counts AS (
  SELECT organization_id, COUNT(*) AS project_count
  FROM projects.projects
  GROUP BY organization_id
)
SELECT *
FROM project_counts
WHERE project_count > 2;
```

Same result. Second reads as: *"first compute `project_counts`, then filter it."*

## Syntax

```sql
WITH cte_name AS (
  -- any SELECT
)
SELECT ...
FROM cte_name;
```

Multiple CTEs in one query (comma-separated, no repeated `WITH`):

```sql
WITH
  cte_a AS (...),
  cte_b AS (...),
  cte_c AS (...)
SELECT ...
FROM cte_a
JOIN cte_b ON ...
JOIN cte_c ON ...;
```

## Practical Queries

### Example 1 — Active users with their organization count

```sql
WITH active_users AS (
  SELECT id, email, full_name
  FROM auth.users
  WHERE is_active = true
    AND deleted_at IS NULL
),
user_org_counts AS (
  SELECT user_id, COUNT(*) AS org_count
  FROM auth.memberships
  GROUP BY user_id
)
SELECT
  au.email,
  au.full_name,
  COALESCE(uoc.org_count, 0) AS organizations_count
FROM active_users AS au
LEFT JOIN user_org_counts AS uoc
  ON uoc.user_id = au.id
ORDER BY organizations_count DESC;
```

Reads as: get active users → count memberships per user → combine.

### Example 2 — Organizations with above-average project counts (CTE used twice)

Shows **reuse** — CTE referenced twice in same query.

```sql
WITH org_project_counts AS (
  SELECT
    organization_id,
    COUNT(*) AS project_count
  FROM projects.projects
  GROUP BY organization_id
)
SELECT
  o.name,
  opc.project_count
FROM org_project_counts AS opc
JOIN auth.organizations AS o
  ON o.id = opc.organization_id
WHERE opc.project_count > (
  SELECT AVG(project_count) FROM org_project_counts
);
```

Without a CTE, you'd write that aggregation twice.

### Example 3 — Multi-step business question

*"For each organization, show its name, total members, total projects."*

```sql
WITH member_counts AS (
  SELECT organization_id, COUNT(*) AS members
  FROM auth.memberships
  GROUP BY organization_id
),
project_counts AS (
  SELECT organization_id, COUNT(*) AS projects
  FROM projects.projects
  GROUP BY organization_id
)
SELECT
  o.name,
  COALESCE(mc.members, 0)  AS member_count,
  COALESCE(pc.projects, 0) AS project_count
FROM auth.organizations AS o
LEFT JOIN member_counts  AS mc ON mc.organization_id = o.id
LEFT JOIN project_counts AS pc ON pc.organization_id = o.id
ORDER BY o.name;
```

Each CTE answers one small question. Final `SELECT` stitches them.

### Example 4 — Data-modifying CTE

CTEs can wrap `INSERT`/`UPDATE`/`DELETE` with `RETURNING`:

```sql
WITH new_org AS (
  INSERT INTO auth.organizations (name)
  VALUES ('Orbit Labs')
  RETURNING id
)
INSERT INTO auth.memberships (organization_id, user_id, role)
SELECT id, 1, 'owner'
FROM new_org;
```

Do step 1, capture its result, feed it into step 2 — all in one statement. See [[day-05 - FAQs#3. Can a CTE modify data?]].
