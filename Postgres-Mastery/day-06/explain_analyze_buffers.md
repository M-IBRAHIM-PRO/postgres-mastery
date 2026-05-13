# `EXPLAIN` vs `EXPLAIN ANALYZE` vs `EXPLAIN (ANALYZE, BUFFERS)`

These three commands answer three different questions about a query.

```txt
EXPLAIN                    = what does PostgreSQL plan to do?
EXPLAIN ANALYZE            = what did it actually do, and how long?
EXPLAIN (ANALYZE, BUFFERS) = ...and how much I/O did it cost?
```

---

## 1. The Three Levels

| Command                         | Runs the query? | Shows estimates? | Shows actual times? | Shows I/O (cache vs disk)? |
| ------------------------------- | --------------- | ---------------- | ------------------- | -------------------------- |
| `EXPLAIN`                       | ❌              | ✅               | ❌                  | ❌                         |
| `EXPLAIN ANALYZE`               | ✅              | ✅               | ✅                  | ❌                         |
| `EXPLAIN (ANALYZE, BUFFERS)`    | ✅              | ✅               | ✅                  | ✅                         |

---

## 2. `EXPLAIN` — the plan

```sql
EXPLAIN
SELECT id, name FROM projects.projects
WHERE organization_id = 1;
```

Output (trimmed):

```txt
Index Scan using idx_projects_org on projects  (cost=0.29..8.45 rows=12 width=36)
  Index Cond: (organization_id = 1)
```

| Field        | Meaning                                                      |
| ------------ | ------------------------------------------------------------ |
| `cost=A..B`  | startup cost `A`, total cost `B` (arbitrary units, not ms)   |
| `rows=N`     | **estimated** rows returned                                  |
| `width=W`    | average row size in bytes                                    |

Use when:

- you want a fast sanity check
- the query is expensive or destructive (you don't want to run it)
- you're comparing plans before / after adding an index

```txt
EXPLAIN never executes — safe on DELETE/UPDATE.
```

---

## 3. `EXPLAIN ANALYZE` — what actually happened

```sql
EXPLAIN ANALYZE
SELECT id, name FROM projects.projects
WHERE organization_id = 1;
```

Adds a second line per node:

```txt
Index Scan using idx_projects_org on projects
  (cost=0.29..8.45 rows=12 width=36)
  (actual time=0.018..0.041 rows=14 loops=1)
  Index Cond: (organization_id = 1)
Planning Time: 0.112 ms
Execution Time: 0.078 ms
```

| Field             | Meaning                                              |
| ----------------- | ---------------------------------------------------- |
| `actual time=A..B`| ms to return first row `A`, last row `B`             |
| `rows=N`          | **actual** rows returned                             |
| `loops=L`         | how many times this node ran (matters in joins)     |
| `Planning Time`   | time to build the plan                               |
| `Execution Time`  | time to run it                                       |

**The single most useful diagnostic:** compare `rows=` (estimated) against `actual rows=`. A big mismatch means the planner has bad statistics and may be choosing the wrong plan.

```txt
Estimated 10 rows, actual 500,000 → run ANALYZE on the table.
```

Warning: `EXPLAIN ANALYZE` **executes** the query. For `INSERT`/`UPDATE`/`DELETE`, wrap it:

```sql
BEGIN;
EXPLAIN ANALYZE DELETE FROM projects.tasks WHERE id = 99;
ROLLBACK;
```

---

## 4. `EXPLAIN (ANALYZE, BUFFERS)` — adds I/O

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, name FROM projects.projects
WHERE organization_id = 1;
```

Adds a `Buffers:` line per node:

```txt
Buffers: shared hit=4 read=2
```

| Term            | Meaning                                            |
| --------------- | -------------------------------------------------- |
| `shared hit=N`  | pages served from PostgreSQL's cache (fast)        |
| `shared read=N` | pages read from disk / OS cache (slow)             |
| `shared dirtied`| pages modified by this query                       |
| `temp read/write`| disk spill (sorts/hashes too big for `work_mem`)  |

Why it matters:

```txt
Same query, run twice:
  Run 1: shared read=10000  → cold cache, hitting disk
  Run 2: shared hit=10000   → warm cache, fast
```

Without `BUFFERS`, you can't tell whether a query is fast because it's *efficient* or fast because it's *cached*.

---

## 5. Useful Extra Options

```sql
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT JSON) <query>;
```

| Option           | What it adds                                            |
| ---------------- | ------------------------------------------------------- |
| `VERBOSE`        | output column lists, schema-qualified names             |
| `SETTINGS`       | any non-default planner settings active for the query   |
| `WAL`            | WAL bytes generated (for write queries)                 |
| `FORMAT JSON`    | machine-readable output (good for tools like depesz)    |

---

## 6. Daily Workflow

| Situation                                   | Use                                |
| ------------------------------------------- | ---------------------------------- |
| "Will this query use my new index?"         | `EXPLAIN`                          |
| "Why is this query slow in prod?"           | `EXPLAIN (ANALYZE, BUFFERS)`       |
| "Did my refactor change the plan?"          | `EXPLAIN` before & after           |
| "DELETE/UPDATE — am I about to nuke it?"    | `EXPLAIN` (no ANALYZE)             |
| Sharing a plan for help (e.g. depesz.com)   | `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)` |

---

## 7. Reading Tip

Plans are trees — read **bottom-up, innermost-first**. Each node's time *includes* the time of its children. The expensive node is usually the one whose `actual time` accounts for most of `Execution Time`.

```txt
Find the bottleneck node, not the total time.
```

---

```txt
EXPLAIN tells you the plan.
ANALYZE tells you the truth.
BUFFERS tells you whether the truth was cheap.
```
