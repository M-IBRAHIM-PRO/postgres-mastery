# PostgreSQL Indexing

Indexes are the first major performance tool in PostgreSQL.

Use [[querying]] for the SQL shape that indexes support.

---

## 1. What An Index Is

Conceptually:

```txt
Without index = PostgreSQL may scan many rows
With index    = PostgreSQL can jump closer to the answer
```

Memory hook:

```txt
Table = full book
Index = back-of-book lookup
```

---

## 2. Basic Index

Example:

```sql
CREATE INDEX idx_users_email
ON auth.users(email);
```

This helps queries like:

```sql
SELECT id, email
FROM auth.users
WHERE email = 'ali@example.com';
```

---

## 3. Composite Index

Use a composite index when queries filter by multiple columns together.

Example:

```sql
CREATE INDEX idx_memberships_user_org
ON auth.memberships(user_id, organization_id);
```

Good for:

- frequent multi-column filtering
- join-heavy access patterns
- common pagination scopes

Important:

```txt
Column order matters in composite indexes.
```

---

## 4. UNIQUE Index

A `UNIQUE` constraint is also an indexing strategy.

Example:

```sql
CREATE UNIQUE INDEX idx_users_email_unique
ON auth.users(email);
```

Meaning:

```txt
Speed lookup + prevent duplicates
```

---

## 5. When Indexes Help

Indexes usually help when queries:

- filter by a column often
- join by a column often
- sort by a column often
- look up a small subset from a large table

Common Day 3 candidates:

- `auth.users(email)`
- `auth.memberships(user_id, organization_id)`
- `projects.projects(organization_id)`
- `projects.projects(created_by)`

---

## 6. When Too Many Indexes Hurt

Indexes are not free.

Costs:

- slower inserts
- slower updates on indexed columns
- slower deletes
- more storage

Rule:

```txt
Index for real query patterns, not for decoration.
```

---

## 7. `EXPLAIN` Basics

Start with:

```sql
EXPLAIN ANALYZE
SELECT id, email
FROM auth.users
WHERE email = 'ali@example.com';
```

Beginner terms:

- sequential scan
- index scan
- cost estimate
- actual execution timing

Goal:

```txt
Learn to ask:
Did PostgreSQL scan everything, or did it use a better path?
```

INDEX NOTE
- PostgreSQL automatically creates indexes for:
    1. PRIMARY KEY constraints
    2. UNIQUE constraints
- PostgreSQL does NOT automatically create indexes for:
    1. FOREIGN KEY constraints

