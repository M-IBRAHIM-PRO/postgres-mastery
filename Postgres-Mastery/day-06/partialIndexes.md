# Partial Indexes

An index built on **only a subset of rows** that match a `WHERE` clause. Smaller, faster, and avoids indexing rows you never query.

```txt
Full index   = every row, even rows you never read.
Partial index = only the rows the application actually queries.
```

---

## 1. Syntax

```sql
CREATE INDEX idx_users_active_email
ON auth.users(email)
WHERE deleted_at IS NULL;
```

This index contains entries **only for non-deleted users**. If 90% of your queries filter `WHERE deleted_at IS NULL`, the index is ~10× smaller than a full one.

---

## 2. When Each Wins

| Scenario                                | Use partial when…                           | Example predicate                       |
| --------------------------------------- | ------------------------------------------- | --------------------------------------- |
| Soft deletes                            | most reads exclude deleted rows             | `WHERE deleted_at IS NULL`              |
| Active/inactive flag                    | one side dominates queries                  | `WHERE is_active = true`                |
| Status with few "hot" values            | only one or two statuses are queried        | `WHERE status IN ('pending','running')` |
| Unique only among live rows             | uniqueness shouldn't apply to soft-deleted  | `WHERE deleted_at IS NULL` on `UNIQUE`  |
| Sparse columns                          | most rows have `NULL`, you query non-NULL   | `WHERE assigned_to IS NOT NULL`         |

---

## 3. Practical Examples

| Goal                                      | Index                                                                                          |
| ----------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Lookup live users by email                | `CREATE INDEX ... ON auth.users(email) WHERE deleted_at IS NULL;`                              |
| Unique email only among live users        | `CREATE UNIQUE INDEX ... ON auth.users(email) WHERE deleted_at IS NULL;`                       |
| Open tasks per project                    | `CREATE INDEX ... ON projects.tasks(project_id) WHERE status <> 'done';`                       |
| Pending invitations                       | `CREATE INDEX ... ON auth.invitations(email) WHERE accepted_at IS NULL;`                       |

---

## 4. The Match Rule

The query's `WHERE` must **logically imply** the index's `WHERE`, or PostgreSQL won't use it.

| Index predicate                | Query predicate                       | Used? |
| ------------------------------ | ------------------------------------- | ----- |
| `WHERE deleted_at IS NULL`     | `WHERE deleted_at IS NULL AND id = 5` | ✅    |
| `WHERE deleted_at IS NULL`     | `WHERE id = 5` (no deleted filter)    | ❌    |
| `WHERE status = 'pending'`     | `WHERE status = 'pending'`            | ✅    |
| `WHERE status IN ('a','b')`    | `WHERE status = 'a'`                  | ✅    |
| `WHERE status = 'a'`           | `WHERE status IN ('a','b')`           | ❌    |

---

## 5. Why It Wins

| Benefit         | Reason                                                  |
| --------------- | ------------------------------------------------------- |
| Smaller         | fewer entries → fits in cache, faster lookups           |
| Cheaper writes  | inserts/updates outside the predicate skip the index    |
| Scoped UNIQUE   | enforce uniqueness only where it makes business sense   |
| Better plans    | planner sees a tighter row estimate                     |

---

```txt
If your WHERE clause is on almost every query,
bake it into the index.
```