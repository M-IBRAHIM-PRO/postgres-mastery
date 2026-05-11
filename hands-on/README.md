# Hands-On Workspace

This folder contains the runnable code for the PostgreSQL learning project.

The current exercise now covers the Day 3 workflow: create the schema, load
seed data, practice SQL queries, and run a small Go app that fetches real rows
from PostgreSQL.

## Structure

```txt
hands-on/
├── cmd/
│   └── main.go
├── go.mod
├── go.sum
├── internal/
│   └── users/
├── sql/
│   ├── queries/
│   └── seeds/
└── README.md
```

The matching notes are in:

```txt
../Postgres-Mastery/day-01/
../Postgres-Mastery/day-02/
../Postgres-Mastery/day-03/
```

## Current Exercise

- Language: Go
- Module: `postgres-mastery`
- PostgreSQL driver: `github.com/jackc/pgx/v5`
- Database: `teamsync`
- Entry point: `cmd/main.go`
- SQL setup: `sql/queries/day-02.sql`
- SQL practice: `sql/queries/day-03.sql`
- Seed data: `sql/seeds/day-03.sql`

## Target Database Shape

Day 3 works with a small SaaS-style schema:

```txt
teamsync database
├── auth
│   ├── organizations
│   ├── users
│   └── memberships
└── projects
    └── projects
```

This gives you enough structure to practice:

- joins across users, memberships, organizations, and projects
- constraints like `PRIMARY KEY`, `UNIQUE`, and `FOREIGN KEY`
- indexes on common lookup columns
- transactions for multi-step writes

## Prerequisites

- PostgreSQL running locally
- Go installed
- A database named `teamsync`
- A PostgreSQL role that can connect to `teamsync`

The app reads these values from `hands-on/.env`:

```txt
DB_HOST=localhost
DB_PORT=5432
DB_USER=your_user
DB_PASSWORD=your_password
DB_NAME=teamsync
```

Change them to match your local PostgreSQL setup.

## Setup The Database

From the repo root:

```bash
psql -d teamsync -f hands-on/sql/queries/day-02.sql
psql -d teamsync -f hands-on/sql/seeds/day-03.sql
```

This creates the Day 2 schema and loads repeatable Day 3 practice data.

## Run The App

From the `hands-on` directory:

```bash
go run cmd/main.go
```

If the connection works, the app:

```txt
Found user: Muhammad Ibrahim (ibrahim@teamsync.dev)
Organization 1 members:
- Muhammad Ibrahim <ibrahim@teamsync.dev> role=owner
- Sarah Khan <sarah@teamsync.dev> role=member
- Ali Raza <ali@teamsync.dev> role=member
```

This confirms that Go can connect to PostgreSQL and run parameterized queries
against the seeded schema.

## Useful psql Commands

```sql
\l
\c teamsync
\dn
\dt
\d auth.users
\q
```

For deeper SQL practice, use:

- [sql/queries/day-03.sql](sql/queries/day-03.sql)
- [sql/seeds/day-03.sql](sql/seeds/day-03.sql)

## What This Validates

- The local PostgreSQL server is running
- The `teamsync` database is reachable
- The configured role can authenticate through `.env`
- The Go module can use `pgx`
- Parameterized queries can safely fetch users and organization members
- The Day 2 schema and Day 3 seed data are usable from application code

## Related Notes

- [Day 1 Concepts](../Postgres-Mastery/day-01/concepts.md)
- [Day 1 Commands](../Postgres-Mastery/day-01/commands.md)
- [Day 2 Relationships](../Postgres-Mastery/day-02/relationships.md)
- [Day 3 Querying](../Postgres-Mastery/day-03/querying.md)
- [Day 3 JOINs](../Postgres-Mastery/day-03/joins.md)
- [Day 3 Transactions](../Postgres-Mastery/day-03/transactions.md)

## Next Steps

- Add a project repository for project listing queries
- Move from raw SQL files toward migrations
- Add inserts and transactions from Go, not only reads
- Expand the app from `users` into `organizations` and `projects`
