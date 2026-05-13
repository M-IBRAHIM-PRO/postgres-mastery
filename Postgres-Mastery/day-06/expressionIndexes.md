# Expression Indexes

An index built on the **result of an expression**, not a raw column. Required when your query filters on a transformed value — otherwise PostgreSQL falls back to a sequential scan.

```txt
The index must match the expression in the query, exactly.
```

---

## 1. The Problem

```sql
-- Index on raw column
CREATE INDEX idx_users_email ON auth.users(email);

-- Query transforms the column → index NOT used
SELECT id FROM auth.users
WHERE LOWER(email) = 'ali@example.com';
```

`LOWER(email)` is a different value than `email`. The B-tree on `email` is useless here.

---

## 2. The Fix

```sql
CREATE INDEX idx_users_email_lower
ON auth.users(LOWER(email));
```

Now the query above uses the index.

---

## 3. Common Patterns

| Goal                                | Index                                                                      | Query that uses it                                  |
| ----------------------------------- | -------------------------------------------------------------------------- | --------------------------------------------------- |
| Case-insensitive email lookup       | `CREATE INDEX ... ON auth.users(LOWER(email));`                            | `WHERE LOWER(email) = $1`                           |
| Case-insensitive `ILIKE` prefix     | `CREATE INDEX ... ON auth.users(LOWER(email) text_pattern_ops);`           | `WHERE LOWER(email) LIKE 'ali%'`                    |
| Filter by date part of a timestamp  | `CREATE INDEX ... ON events.activity_log((created_at::date));`             | `WHERE created_at::date = '2026-05-13'`             |
| JSONB field as scalar               | `CREATE INDEX ... ON events.activity_log((payload->>'user_id'));`          | `WHERE payload->>'user_id' = '42'`                  |
| Computed length / hash              | `CREATE INDEX ... ON projects.projects((length(name)));`                   | `WHERE length(name) > 100`                          |

---

## 4. Match Rule

| Index expression          | Query expression                  | Used? |
| ------------------------- | --------------------------------- | ----- |
| `LOWER(email)`            | `LOWER(email) = 'a@b.com'`        | ✅    |
| `LOWER(email)`            | `email = 'a@b.com'`               | ❌    |
| `LOWER(email)`            | `lower(email) = 'A@B.COM'`        | ❌ (value not lowercased) |
| `(created_at::date)`      | `created_at::date = '2026-05-13'` | ✅    |
| `(created_at::date)`      | `created_at = '2026-05-13'`       | ❌    |

The query must call the **same function** on the **same column**, and the compared value must already be in the transformed form.

---

## 5. Function Requirement

The function inside the index must be **`IMMUTABLE`** — same input always returns the same output.

| Function        | Status      | Indexable? |
| --------------- | ----------- | ---------- |
| `LOWER(x)`      | IMMUTABLE   | ✅         |
| `length(x)`     | IMMUTABLE   | ✅         |
| `x::date`       | IMMUTABLE   | ✅         |
| `now()`         | VOLATILE    | ❌         |
| `random()`      | VOLATILE    | ❌         |
| `to_char(ts,…)` | STABLE      | ❌ (in indexes) |

---

## 6. Combine With Partial

Expression + partial = very tight index.

```sql
CREATE UNIQUE INDEX idx_users_email_live_ci
ON auth.users(LOWER(email))
WHERE deleted_at IS NULL;
```

Meaning:

```txt
Case-insensitive email uniqueness,
enforced only on live users.
```

---

```txt
If the query transforms the column,
the index must store the transformed value.
```
