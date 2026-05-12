# PostgreSQL Mastery

Compact learning workspace for PostgreSQL concepts, schema design, and Go-based
hands-on practice.

## Structure

```txt
.
├── Postgres-Mastery/
│   ├── day-01/
│   ├── day-02/
│   ├── day-03/
│   ├── day-04/
│   └── day-05/
├── hands-on/
│   ├── cmd/api/main.go
│   ├── config.go
│   ├── internal/users/
│   ├── scripts/migrate.sh
│   ├── sql/
│   │   ├── migrations/
│   │   ├── queries/
│   │   └── seeds/
│   └── Makefile
└── README.md
```

## Current Focus

Day 5 covers advanced read-only SQL on the existing `teamsync` schema — no new
tables, just deeper query power.

Topics:

- **CTE (`WITH`)** — name intermediate steps, reuse subqueries, write data-modifying CTEs with `RETURNING`.
- **Recursive CTE** — tree/hierarchy traversal (org charts, threaded comments), with `UNION ALL`, termination, and the `CYCLE` clause.
- **Window functions** — `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `LAG`, `LEAD`; the latest-row-per-group and top-N-per-group patterns.
- **`OVER (PARTITION BY … ORDER BY …)`** — partition / order / frame mental model; the default-frame trap (`ORDER BY` silently turns sum into running sum).
- **`GROUPING SETS` / `ROLLUP` / `CUBE`** — multi-level subtotals in one query; `GROUPING()` to separate structural `NULL` from real `NULL`.
- **`FILTER (WHERE …)`** — per-aggregate condition; pivot rows to columns; replaces the old `COUNT(CASE WHEN … THEN 1 END)` trick.

## Hands-On

Migration flow:

```bash
cd hands-on
make migrate-up                  # apply all migrations
make migrate-down                # roll back 1 step
make migrate-down STEPS=3        # roll back N steps
make migrate-force VERSION=4     # fix dirty state
```

Run and build:

```bash
make run     # go run ./cmd/api
make build   # go build -o bin/api ./cmd/api
```

SQL files:

- [day-01.sql](hands-on/sql/queries/day-01.sql)
- [day-02.sql](hands-on/sql/queries/day-02.sql)
- [day-03.sql](hands-on/sql/queries/day-03.sql)
- [day-05.sql](hands-on/sql/queries/day-05.sql)
- [day-03 seed](hands-on/sql/seeds/day-03.sql)
- [day-04 seed](hands-on/sql/seeds/day-04.sql)
- [day-05 seed](hands-on/sql/seeds/day-05.sql)

## Notes

- [Documentation Workflow](<Postgres-Mastery/Documentation Workflow.md>)
- [Day 1](Postgres-Mastery/day-01)
- [Day 2 Data Types](Postgres-Mastery/day-02/datatypes.md)
- [Day 2 Relationships](Postgres-Mastery/day-02/relationships.md)
- [Day 2 Architecture](<Postgres-Mastery/day-02/day-02 - Architecture.md>)
- [Day 2 FAQs](<Postgres-Mastery/day-02/day-02 - FAQs.md>)
- [Day 3 Querying](Postgres-Mastery/day-03/querying.md)
- [Day 3 JOINs](Postgres-Mastery/day-03/joins.md)
- [Day 3 Indexing](Postgres-Mastery/day-03/indexing.md)
- [Day 3 Transactions](Postgres-Mastery/day-03/transactions.md)
- [Day 4 Architecture](<Postgres-Mastery/day-04/day-04 - Architecture.md>)
- [Day 4 Migrations](Postgres-Mastery/day-04/migrations.md)
- [Day 4 New Tables](Postgres-Mastery/day-04/new-tables.md)
- [Day 4 Partitioning](Postgres-Mastery/day-04/partitioning.md)
- [Day 4 FAQs](<Postgres-Mastery/day-04/day-04 - FAQs.md>)
- [Day 5 CTE](Postgres-Mastery/day-05/CTE.md)
- [Day 5 Recursive CTE](Postgres-Mastery/day-05/recursiveCTE.md)
- [Day 5 Window Functions](Postgres-Mastery/day-05/windowFunctions.md)
- [Day 5 OVER Clause](Postgres-Mastery/day-05/overClause.md)
- [Day 5 Multi-Level Aggregation](Postgres-Mastery/day-05/multi-levelAggregation.md)
- [Day 5 FILTER on Aggregates](Postgres-Mastery/day-05/filterOnAggregates.md)
- [Day 5 Cheatsheet](Postgres-Mastery/day-05/cheatsheet.md)
- [Day 5 FAQs](<Postgres-Mastery/day-05/day-05 - FAQs.md>)
