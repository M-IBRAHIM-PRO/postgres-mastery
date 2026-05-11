# PostgreSQL Querying

Day 3 shifts from schema creation into working with data safely.

Use [[joins]] for relational reconstruction, [[constraints]] for integrity, and
[[indexing]] for performance.

---

## 1. Data Manipulation

Core write operations:

```sql
INSERT INTO auth.users (email, name)
VALUES ('ali@example.com', 'Ali');

UPDATE auth.users
SET is_active = false
WHERE id = 10;

DELETE FROM projects.projects
WHERE id = 25;
```

Rules:

- always use `WHERE` for `UPDATE` and `DELETE` unless you truly mean all rows
- prefer soft delete patterns for business data when recovery matters
- use `RETURNING` when the application needs the inserted or changed row

Example:

```sql
INSERT INTO auth.organizations (name)
VALUES ('Acme')
RETURNING id, public_id, created_at;
```

Multi-row insert:

```sql
INSERT INTO auth.memberships (organization_id, user_id, role)
VALUES
  (1, 10, 'owner'),
  (1, 11, 'member');
```

`TRUNCATE` vs `DELETE`:

```txt
DELETE   = row-by-row, can use WHERE
TRUNCATE = remove all rows fast, no per-row filtering
```

---

## 2. SELECT Basics

Common shape:

```sql
SELECT id, email, created_at
FROM auth.users
WHERE is_active = true
ORDER BY created_at DESC
LIMIT 20 OFFSET 0;
```

Common tools:

- specific columns
- `WHERE`
- `ORDER BY`
- `LIMIT` / `OFFSET`
- `DISTINCT`
- aliases
- `IN`
- `BETWEEN`
- `LIKE` / `ILIKE`
- `IS NULL`

Production rule:

```txt
Avoid SELECT * unless you truly need every column.
```

Why:

- returns unnecessary data
- makes API payloads noisier
- can break expectations when schema changes

---

## 3. Filtering Patterns

Examples:

```sql
SELECT id, email
FROM auth.users
WHERE email ILIKE '%@gmail.com';
```

```sql
SELECT id, name
FROM projects.projects
WHERE created_at BETWEEN '2026-01-01' AND '2026-12-31';
```

```sql
SELECT id, name
FROM auth.users
WHERE deleted_at IS NULL
  AND is_active = true;
```

Memory hook:

```txt
Filtering = tell PostgreSQL which truth you want.
```

---

## 4. Practical Query Patterns

Get all projects for one user:

```sql
SELECT p.id, p.name, p.created_at
FROM projects.projects AS p
WHERE p.created_by = 10
ORDER BY p.created_at DESC;
```

Count projects per organization:

```sql
SELECT p.organization_id, COUNT(*) AS project_count
FROM projects.projects AS p
GROUP BY p.organization_id
ORDER BY project_count DESC;
```

Paginate projects:

```sql
SELECT id, name, created_at
FROM projects.projects
WHERE organization_id = 1
ORDER BY created_at DESC
LIMIT 20 OFFSET 20;
```

Find inactive users:

```sql
SELECT id, email
FROM auth.users
WHERE is_active = false
   OR deleted_at IS NOT NULL;
```

---

## 5. Querying Mindset

Day 2 asked:

```txt
What data model should exist?
```

Day 3 asks:

```txt
How do I read and change that model safely?
```

Good production SQL is usually:

- explicit
- filtered
- ordered
- limited
- aligned with business rules
