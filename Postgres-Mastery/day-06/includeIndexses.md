# Covering Indexes with `INCLUDE`

A covering index stores **extra columns alongside the index key** so the query can be answered from the index alone — no trip back to the table heap.

```txt
Key columns    = used for searching / sorting.
INCLUDE columns = carried along for free reads.
```

---

## 1. The Problem

```sql
CREATE INDEX idx_projects_org
ON projects.projects(organization_id);

-- Query
SELECT id, name, created_at
FROM projects.projects
WHERE organization_id = 1;
```

PostgreSQL uses the index to find matching rows, then **goes back to the table** to fetch `name` and `created_at`. That extra trip is called a **heap fetch**.

---

## 2. The Fix

```sql
CREATE INDEX idx_projects_org_covering
ON projects.projects(organization_id)
INCLUDE (name, created_at);
```

Now `name` and `created_at` live inside the index leaf pages. The planner can do an **Index Only Scan** — heap not touched.

---

## 3. Key vs INCLUDE

| Aspect                    | Key columns (`(...)`)         | INCLUDE columns                |
| ------------------------- | ----------------------------- | ------------------------------ |
| Used for `WHERE` matching | ✅                            | ❌                             |
| Used for `ORDER BY`       | ✅                            | ❌                             |
| Used for joins            | ✅                            | ❌                             |
| Returned in `SELECT`      | ✅                            | ✅                             |
| Affects sort order        | ✅                            | ❌                             |
| Counts toward uniqueness  | ✅                            | ❌                             |

---

## 4. When It Wins

| Scenario                                    | Why INCLUDE helps                              |
| ------------------------------------------- | ---------------------------------------------- |
| Hot read query selects a fixed small set    | answer fully from index, skip heap            |
| Lookup by one column, return a few others   | classic Index Only Scan case                  |
| Wide table where most columns are unused    | avoid bringing whole rows into memory         |
| You want UNIQUE on `(a)` but also fetch `b` | put `b` in INCLUDE, doesn't break uniqueness  |

---

## 5. Practical Examples

| Goal                                                   | Index                                                                                          |
| ------------------------------------------------------ | ---------------------------------------------------------------------------------------------- |
| Look up user by email, return name                     | `CREATE INDEX ... ON auth.users(email) INCLUDE (name);`                                        |
| List org's projects with name + created_at             | `CREATE INDEX ... ON projects.projects(organization_id) INCLUDE (name, created_at);`           |
| Unique email, return id without heap fetch             | `CREATE UNIQUE INDEX ... ON auth.users(email) INCLUDE (id);`                                   |
| Membership lookup, return role                         | `CREATE INDEX ... ON auth.memberships(user_id, organization_id) INCLUDE (role);`               |

---

## 6. Costs

| Cost                  | Reason                                                       |
| --------------------- | ------------------------------------------------------------ |
| Larger index size     | INCLUDE columns are duplicated into the index                |
| Slower writes         | every update to an included column updates the index too     |
| Vacuum sensitivity    | Index Only Scan needs the **visibility map** up to date      |

---

## 7. The Visibility Catch

Index Only Scan only works when PostgreSQL **knows the rows are visible to all transactions** — tracked via the visibility map. If the table has many recent writes and hasn't been vacuumed, the planner falls back to heap fetches even with a perfect covering index.

```txt
Heap Fetches: 0   ← ideal
Heap Fetches: N   ← VACUUM needed
```

Fix with:

```sql
VACUUM (ANALYZE) projects.projects;
```

---

```txt
INCLUDE columns ride along for free,
but only if the table is well-vacuumed.
```
