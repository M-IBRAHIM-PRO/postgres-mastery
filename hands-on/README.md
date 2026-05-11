# Hands-On Workspace

This folder contains the runnable code for the PostgreSQL learning project.

Day 4 introduces controlled schema migrations with `golang-migrate` and adds
three new tables: `auth.invitations`, `projects.tasks`, and a partitioned
`events.activity_log`.

## Structure

```txt
hands-on/
├── cmd/
│   └── api/
│       └── main.go
├── scripts/
│   └── migrate.sh
├── internal/
│   └── users/
├── sql/
│   ├── migrations/
│   │   ├── 000001_init_extensions_and_schemas.{up,down}.sql
│   │   ├── 000002_create_auth_tables.{up,down}.sql
│   │   ├── 000003_create_projects_tables.{up,down}.sql
│   │   ├── 000004_add_auth_invitations.{up,down}.sql
│   │   ├── 000005_add_projects_tasks.{up,down}.sql
│   │   └── 000006_add_events_activity_log.{up,down}.sql
│   ├── queries/
│   └── seeds/
├── Makefile
├── config.go
├── go.mod
└── go.sum
```

The matching notes are in:

```txt
../Postgres-Mastery/day-01/
../Postgres-Mastery/day-02/
../Postgres-Mastery/day-03/
../Postgres-Mastery/day-04/
```

## Current Exercise

- Language: Go
- Module: `postgres-mastery`
- PostgreSQL driver: `github.com/jackc/pgx/v5`
- Migration tool: `golang-migrate` CLI
- Database: `teamsync`
- Entry point: `cmd/api/main.go`

## Target Database Shape

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

## Prerequisites

- PostgreSQL running locally
- Go installed
- `golang-migrate` CLI installed
- A database named `teamsync`
- A PostgreSQL role that can connect to `teamsync`

The app and migration script read config from `hands-on/.env`:

```txt
DB_HOST=localhost
DB_PORT=5432
DB_USER=your_user
DB_PASSWORD=your_password
DB_NAME=teamsync
```

## Setup The Database

From the `hands-on` directory:

```bash
make migrate-up
```

This applies all 6 migrations in order and creates the full schema.

To load seed data:

```bash
psql "$DB_URL" -f sql/seeds/day-03.sql
psql "$DB_URL" -f sql/seeds/day-04.sql
```

## Run The App

```bash
make run
```

If the connection works, the app:

```txt
Found user: Muhammad Ibrahim (ibrahim@teamsync.dev)
Organization 1 members:
- Muhammad Ibrahim <ibrahim@teamsync.dev> role=owner
- Sarah Khan <sarah@teamsync.dev> role=member
- Ali Raza <ali@teamsync.dev> role=member
```

## Migration Commands

```bash
make migrate-up                  # apply all pending migrations
make migrate-down                # roll back 1 step
make migrate-down STEPS=3        # roll back N steps
make migrate-force VERSION=4     # force-set version (fix dirty state)
make migrate-create name=<slug>  # create a new up/down file pair
```

## Useful psql Commands

```sql
\l
\c teamsync
\dn
\dt auth.*
\dt projects.*
\dt events.*
\d events.activity_log
\q
```

## What This Validates

- Local PostgreSQL is running and reachable
- All 6 migrations apply and roll back cleanly
- `events.activity_log` is a partitioned table with a default partition
- The Go module connects via `pgx` and runs parameterized queries
- `make run` and `make build` work from the `hands-on` directory

## Related Notes

- [Day 1 Concepts](../Postgres-Mastery/day-01/concepts.md)
- [Day 2 Relationships](../Postgres-Mastery/day-02/relationships.md)
- [Day 3 Querying](../Postgres-Mastery/day-03/querying.md)
- [Day 3 Transactions](../Postgres-Mastery/day-03/transactions.md)
- [Day 4 Architecture](<../Postgres-Mastery/day-04/day-04 - Architecture.md>)
- [Day 4 Migrations](../Postgres-Mastery/day-04/migrations.md)
- [Day 4 New Tables](../Postgres-Mastery/day-04/new-tables.md)
- [Day 4 Partitioning](../Postgres-Mastery/day-04/partitioning.md)

## Next Steps

- Add repository methods for `invitations`, `tasks`, `activity_log`
- Query `activity_log` by `event_type` and `organization_id`
- Add named monthly partitions to `activity_log`
- Move from single `*pgx.Conn` to a connection pool (`pgxpool`)
- Add inserts and transactions from Go, not only reads
