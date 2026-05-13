# `pg_stat_statements`

`EXPLAIN` tells you about **one query you suspect**. `pg_stat_statements` tells you **which queries you should suspect** — by tracking every statement that runs and how much time it consumed.

```txt
EXPLAIN          = zoom in on a single query.
pg_stat_statements = the leaderboard of all queries.
```

---

## 1. What It Is

A bundled PostgreSQL extension that records execution statistics for every SQL statement, grouped by **normalized query shape** (parameters stripped out).

```txt
SELECT * FROM users WHERE id = 5;   ─┐
SELECT * FROM users WHERE id = 99;   ├─→ one entry, called 5,000 times
SELECT * FROM users WHERE id = 412;  ─┘
```

So `100,000` parameterized lookups appear as **one row** with `calls = 100000`.

---

## 2. Enable It

Two steps. The extension is preinstalled with PostgreSQL but not active by default.

**Step 1** — load the library at server start. In `postgresql.conf`:

```conf
shared_preload_libraries = 'pg_stat_statements'
```

Then restart PostgreSQL.

**Step 2** — create the extension in each database you want to track:

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

Verify:

```sql
SELECT * FROM pg_extension WHERE extname = 'pg_stat_statements';
```

---

## 3. The View

Once active, all data lives in a single view:

```sql
SELECT * FROM pg_stat_statements LIMIT 1;
```

Most useful columns:

| Column                  | Meaning                                                         |
| ----------------------- | --------------------------------------------------------------- |
| `query`                 | normalized SQL text (params shown as `$1`, `$2`)                |
| `calls`                 | how many times the query ran                                    |
| `total_exec_time`       | cumulative ms across all calls                                  |
| `mean_exec_time`        | average ms per call                                             |
| `min_exec_time` / `max_exec_time` | fastest / slowest single run                           |
| `stddev_exec_time`      | variability — high stddev = unstable performance                |
| `rows`                  | total rows returned across all calls                            |
| `shared_blks_hit/read`  | cache vs disk pages (like `EXPLAIN BUFFERS`)                    |

---

## 4. The Top Queries

### Slowest in total (biggest wins live here)

```sql
SELECT
  query,
  calls,
  round(total_exec_time::numeric, 1) AS total_ms,
  round(mean_exec_time::numeric, 2)  AS avg_ms,
  rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

### Slowest per call

```sql
SELECT query, calls, round(mean_exec_time::numeric, 2) AS avg_ms
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

### Most frequently run

```sql
SELECT query, calls, round(mean_exec_time::numeric, 2) AS avg_ms
FROM pg_stat_statements
ORDER BY calls DESC
LIMIT 10;
```

### Worst cache hit ratio

```sql
SELECT
  query,
  calls,
  shared_blks_hit,
  shared_blks_read,
  round(
    100.0 * shared_blks_hit
    / NULLIF(shared_blks_hit + shared_blks_read, 0),
    1
  ) AS hit_pct
FROM pg_stat_statements
WHERE shared_blks_hit + shared_blks_read > 0
ORDER BY shared_blks_read DESC
LIMIT 10;
```

---

## 5. Total Time vs Mean Time

The most important rule when reading this view:

| Sort by              | Finds                                              | Optimize because…                          |
| -------------------- | -------------------------------------------------- | ------------------------------------------ |
| `total_exec_time`    | queries eating the most cumulative DB time         | biggest aggregate wins                     |
| `mean_exec_time`     | individually slow queries                          | user-facing latency                        |
| `calls`              | hot paths                                          | even small wins multiply                   |
| `stddev_exec_time`   | unstable queries                                   | bad plans / parameter sniffing             |

```txt
A 5 ms query called 1,000,000 times
beats a 5 s query called 10 times
on the total_exec_time leaderboard.
```

---

## 6. Reset Between Tests

```sql
SELECT pg_stat_statements_reset();
```

Workflow:

```txt
1. reset
2. run load / wait an hour
3. query the view
4. identify top offenders
5. EXPLAIN (ANALYZE, BUFFERS) the worst ones
```

---

## 7. Costs

| Cost                | Reason                                              |
| ------------------- | --------------------------------------------------- |
| Tiny CPU overhead   | per-statement bookkeeping (~negligible)             |
| Small memory ring   | bounded by `pg_stat_statements.max` (default 5000)  |
| Server restart      | required once to load the library                   |

For nearly every production system, the overhead is invisible and the visibility is non-negotiable.

---

## 8. The Full Loop

```txt
pg_stat_statements   → find the worst query
EXPLAIN (ANALYZE, BUFFERS) → understand why it's bad
Index / rewrite / vacuum  → fix it
pg_stat_statements_reset() → measure the improvement
```

---

```txt
You can't optimize what you can't see.
pg_stat_statements is the "see" part.
```