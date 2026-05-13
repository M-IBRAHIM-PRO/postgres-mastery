# Reading Scan Types

Every `EXPLAIN` output starts with a **scan node** — how PostgreSQL pulls rows from a table. Four matter most. Knowing which one you got tells you whether your index strategy worked.

```txt
Scan type = the access pattern PostgreSQL chose
            to fetch rows from a table.
```

---

## 1. The Four Scan Types

| Scan type            | What it does                                                    | Touches heap?   | Typical when                                              |
| -------------------- | --------------------------------------------------------------- | --------------- | --------------------------------------------------------- |
| **Seq Scan**         | reads every row of the table top-to-bottom                      | ✅ all of it    | no usable index, or query returns most of the table       |
| **Index Scan**       | walks the index, fetches each matching row from the heap        | ✅ per match    | selective filter, few matching rows, need extra columns   |
| **Index Only Scan**  | answers entirely from the index, skips the heap                 | ❌ (usually)    | all needed columns are in the index, table well-vacuumed  |
| **Bitmap Heap Scan** | builds a bitmap of matching row locations, then reads heap once | ✅ batched      | medium number of matches, or combining multiple indexes   |

---

## 2. Seq Scan

```txt
Seq Scan on projects.projects  (cost=0.00..18334.00 rows=1000000 width=36)
  Filter: (organization_id = 1)
  Rows Removed by Filter: 999988
```

| Signal                                | Meaning                                          |
| ------------------------------------- | ------------------------------------------------ |
| `Filter:` line + many rows removed    | post-scan filtering, no index used               |
| Returns most of the table             | Seq Scan can actually be the right choice        |
| Small table                           | also fine — index overhead isn't worth it        |

When to worry:

```txt
Seq Scan + huge "Rows Removed by Filter"
+ small result set
→ missing or unused index.
```

---

## 3. Index Scan

```txt
Index Scan using idx_projects_org on projects
  (cost=0.43..8.45 rows=12 width=36)
  Index Cond: (organization_id = 1)
```

| Field         | Meaning                                                                |
| ------------- | ---------------------------------------------------------------------- |
| `Index Cond:` | conditions resolved **inside the index** (good)                        |
| `Filter:`     | conditions checked **after** fetching the row (less good)              |

```txt
Index Cond  = used the index
Filter      = checked after fetching from heap
```

If you see `Filter:` doing most of the work, the index isn't selective enough — extend it or change column order.

---

## 4. Index Only Scan

```txt
Index Only Scan using idx_projects_org_covering on projects
  (cost=0.43..4.45 rows=12 width=24)
  Index Cond: (organization_id = 1)
  Heap Fetches: 0
```

| Field            | Meaning                                                         |
| ---------------- | --------------------------------------------------------------- |
| `Heap Fetches: 0`| ideal — no trip back to the table                               |
| `Heap Fetches: N`| visibility map stale → run `VACUUM (ANALYZE)`                   |

Requirements:

- every column in `SELECT`, `WHERE`, `ORDER BY` is in the index (key or `INCLUDE`)
- the visibility map is fresh enough (recent `VACUUM`)

```txt
Heap Fetches = 0 is the gold medal of read performance.
```

---

## 5. Bitmap Heap Scan

```txt
Bitmap Heap Scan on projects.projects
  Recheck Cond: (organization_id = 1)
  Heap Blocks: exact=42
  ->  Bitmap Index Scan on idx_projects_org
        Index Cond: (organization_id = 1)
```

How it works:

```txt
1. Bitmap Index Scan: walk index, mark matching block locations
2. Sort the bitmap into block order
3. Bitmap Heap Scan: read each block once, in disk order
```

Strengths:

- great for medium-sized result sets (too many for Index Scan, too few for Seq Scan)
- can **combine indexes** via `BitmapAnd` / `BitmapOr`

```txt
Bitmap Index Scan on idx_a
Bitmap Index Scan on idx_b
BitmapAnd → Bitmap Heap Scan
```

Watch for:

| Signal                   | Meaning                                                       |
| ------------------------ | ------------------------------------------------------------- |
| `Heap Blocks: exact=N`   | precise row locations — efficient                             |
| `Heap Blocks: lossy=N`   | bitmap too big for memory → rechecks whole blocks, slower     |
| `Recheck Cond:`          | re-applies the filter after fetching (normal, but lossy hurts)|

If `lossy` is large, raise `work_mem` for that session.

---

## 6. Side-by-Side

| Result set size       | Best scan                | Why                              |
| --------------------- | ------------------------ | -------------------------------- |
| 1 row                 | Index Scan / Index Only  | minimal heap work                |
| Tens to a few thousand| Bitmap Heap Scan         | batched, ordered heap reads      |
| Most of the table     | Seq Scan                 | index overhead exceeds benefit   |
| All columns in index  | Index Only Scan          | skip heap entirely               |

---

## 7. Quick Diagnosis Checklist

When you see a slow plan, ask in this order:

| Question                                                       | If yes…                                          |
| -------------------------------------------------------------- | ------------------------------------------------ |
| Seq Scan with many rows removed by filter?                     | add or fix an index                              |
| Index Scan with heavy `Filter:` work?                          | extend index columns or reorder them             |
| Index Only Scan with non-zero `Heap Fetches`?                  | `VACUUM (ANALYZE)` the table                     |
| Bitmap Heap Scan with `lossy` blocks?                          | bump `work_mem`                                  |
| Estimated rows wildly different from actual rows?              | `ANALYZE` the table; check statistics target     |

---

```txt
Seq Scan         → scan everything.
Index Scan       → jump to matches, fetch each row.
Index Only Scan  → answer from the index, never touch the table.
Bitmap Heap Scan → collect matches, read the heap in one efficient sweep.
```
