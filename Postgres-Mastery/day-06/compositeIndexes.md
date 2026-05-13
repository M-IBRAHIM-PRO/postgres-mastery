# Composite Index Column Order

A composite index spans multiple columns. The **order of those columns decides which queries can use it**. This is the most-misunderstood indexing rule, and the cause of countless "I have an index, why is it slow?" tickets.

```txt
Composite index = phonebook sorted by (last_name, first_name).
Find by last_name      → fast
Find by first_name only → useless
```

---

## 1. The Rule

Given:

```sql
CREATE INDEX idx_memberships_uo
ON auth.memberships(user_id, organization_id);
```

The index is usable **left-to-right**:

| Query filters on               | Uses index?            |
| ------------------------------ | ---------------------- |
| `user_id`                      | ✅ full                |
| `user_id` + `organization_id`  | ✅ full                |
| `organization_id` alone        | ❌ (skips leading col) |
| `organization_id` + `user_id`  | ✅ (order in WHERE doesn't matter) |

The order in your `WHERE` clause is irrelevant — what matters is **which columns appear**, starting from the leftmost.

---

## 2. Range Stops the Chain

Equality on earlier columns lets later columns stay useful. A **range** on an earlier column halts further index seeking — later columns become filter-only.

| Index `(a, b, c)`               | Query                                  | What's indexed                |
| ------------------------------- | -------------------------------------- | ----------------------------- |
| `(a, b, c)`                     | `a = 1 AND b = 2 AND c = 3`            | all three                     |
| `(a, b, c)`                     | `a = 1 AND b > 5 AND c = 3`            | `a`, `b` (c becomes filter)   |
| `(a, b, c)`                     | `a > 1 AND b = 2`                      | `a` only (b becomes filter)   |
| `(a, b, c)`                     | `b = 2 AND c = 3`                      | not used                      |

```txt
Equality columns first. Range column last.
```

---

## 3. Picking Column Order

| Heuristic                            | Why                                                              |
| ------------------------------------ | ---------------------------------------------------------------- |
| Equality before range                | range freezes the index after it                                 |
| Most selective column first*         | filters out more rows earlier                                    |
| Columns used in every query first    | only those queries can use the index at all                      |
| `ORDER BY` matches index order       | enables index-driven sorting, skips a sort step                  |

*Selectivity matters less than the "equality before range" and "must-be-leftmost" rules. Get those right first.

---

## 4. Practical Examples

```sql
-- A: list memberships for a user, scoped by org
CREATE INDEX idx_memberships_user_org
ON auth.memberships(user_id, organization_id);
```

| Query                                                     | Uses it? |
| --------------------------------------------------------- | -------- |
| `WHERE user_id = 10`                                      | ✅       |
| `WHERE user_id = 10 AND organization_id = 1`              | ✅       |
| `WHERE organization_id = 1`                               | ❌       |

```sql
-- B: paginate an org's projects by newest first
CREATE INDEX idx_projects_org_created
ON projects.projects(organization_id, created_at DESC);
```

| Query                                                                           | Uses it? |
| ------------------------------------------------------------------------------- | -------- |
| `WHERE organization_id = 1 ORDER BY created_at DESC LIMIT 20`                   | ✅ (sort too) |
| `WHERE organization_id = 1 AND created_at > '2026-01-01'`                       | ✅       |
| `ORDER BY created_at DESC` (no org filter)                                      | ❌       |

```sql
-- C: tasks dashboard — open tasks per project, newest first
CREATE INDEX idx_tasks_proj_status_created
ON projects.tasks(project_id, status, created_at DESC);
```

Equality (`project_id`, `status`), then ordering (`created_at`) — the textbook shape.

---

## 5. Don't Stack Single-Column Indexes Instead

A common mistake: creating `idx_x(a)`, `idx_x(b)`, `idx_x(c)` and hoping the planner combines them. It can (via BitmapAnd), but it's almost always slower than one well-ordered composite for the queries you actually run.

```txt
Three single-column indexes ≠ one composite (a, b, c)
```

---

## 6. The Mental Picture

```txt
Index (user_id, organization_id, created_at)

user_id=1 ─ org=10 ─ 2026-01-01
            org=10 ─ 2026-02-15
            org=20 ─ 2026-01-10
user_id=2 ─ org=10 ─ 2026-03-01
            org=30 ─ 2026-04-05
...
```

To use the index, you must enter from `user_id`. Once inside a `user_id`, you can navigate by `organization_id`. Once inside that, by `created_at`.

```txt
Skip the leftmost column → you can't enter the tree.
```

---

```txt
Composite indexes reward
the queries that match their column order
and ignore the ones that don't.
```
