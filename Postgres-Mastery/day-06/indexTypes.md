# B-tree, Hash, GIN, GiST, BRIN

```txt
Index type follows data shape, not column name.
```

---

## 1. Quick Comparison

| Type       | Best for                                          | Supports                                | Skip when                          |
| ---------- | ------------------------------------------------- | --------------------------------------- | ---------------------------------- |
| **B-tree** | scalar columns (id, email, fk, timestamp)         | `=` `<` `>` `BETWEEN` `IN` `ORDER BY` `LIKE 'a%'` | almost never — this is the default |
| **Hash**   | equality-only on huge equality-heavy workloads    | `=` only                                | you need ranges, sorts, or `LIKE`  |
| **GIN**    | rows holding many values (JSONB, arrays, tsvector)| `@>` `<@` `?` `?`| `?&` `@@`            | plain scalar columns               |
| **GiST**   | geometry, ranges, nearest-neighbor, exclusion     | `&&` `<->` overlap / distance ops       | plain equality / sorting           |
| **BRIN**   | huge tables ordered on disk (time-series, logs)   | range filters on correlated data        | data is randomly ordered           |

---

## 2. Syntax Reference

| Type   | Example                                                                 |
| ------ | ----------------------------------------------------------------------- |
| B-tree | `CREATE INDEX idx_users_email ON auth.users(email);`                    |
| Hash   | `CREATE INDEX idx_x ON t USING HASH (col);`                             |
| GIN    | `CREATE INDEX idx_x ON t USING GIN (jsonb_col);`                        |
| GiST   | `CREATE INDEX idx_x ON t USING GIST (range_col);`                       |
| BRIN   | `CREATE INDEX idx_x ON t USING BRIN (created_at);`                      |

---

## 3. Memory Hooks

| Type   | Hook                                                |
| ------ | --------------------------------------------------- |
| B-tree | sorted, balanced, general-purpose — if unsure, here |
| Hash   | equality and nothing else                           |
| GIN    | "row contains many things, find ones holding X"     |
| GiST   | shapes, ranges, distances, overlaps                 |
| BRIN   | huge table + insert-ordered = tiny index            |

---

```txt
Default to B-tree.
Reach for others only when data shape demands it.
```