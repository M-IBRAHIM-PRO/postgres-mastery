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
│   └── day-04/
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

Day 4 shifts from raw SQL files to controlled schema migrations and adds three
new tables to the SaaS schema:

```txt
teamsync database
├── auth
│   ├── users
│   ├── organizations
│   ├── memberships
│   └── invitations
├── projects
│   ├── projects
│   └── tasks
└── events
    └── activity_log   ← partitioned by occurred_at
```

Main ideas:

- `golang-migrate` manages schema changes as numbered, reversible SQL files.
- Every `up.sql` uses `IF NOT EXISTS`; every `down.sql` uses `IF EXISTS CASCADE`.
- `auth.invitations` models the user invite flow with token, status, and expiry.
- `projects.tasks` tracks work items with assignee and status lifecycle.
- `events.activity_log` is a high-volume append-only table, partitioned by `RANGE (occurred_at)`.
- A default partition catches all rows until named monthly partitions are added.

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
- [day-03 seed](hands-on/sql/seeds/day-03.sql)
- [day-04 seed](hands-on/sql/seeds/day-04.sql)

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
