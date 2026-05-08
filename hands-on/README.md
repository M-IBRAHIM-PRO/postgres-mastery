# Hands-On Workspace

This folder contains the runnable code for the PostgreSQL learning project.

The current exercise is intentionally small: a Go program connects to a local
PostgreSQL database named `teamsync`, runs `SELECT version()`, and prints the
server version. It is the first proof that the app can talk to PostgreSQL.

## Structure

```txt
hands-on/
├── cmd/
│   └── main.go
├── go.mod
├── go.sum
└── README.md
```

The matching Day 1 notes are in:

```txt
../Notes/Postgress-Mastery/day-01/
├── FAQs.md
├── commands.md
└── concepts.md
```

## Current Exercise

- Language: Go
- Module: `postgres-mastery`
- PostgreSQL driver: `github.com/jackc/pgx/v5`
- Database: `teamsync`
- Entry point: `cmd/main.go`

## Target Database Shape

Day 1 uses one database with multiple schemas:

```txt
PostgreSQL cluster
└── teamsync database
    ├── auth schema
    │   └── users table
    ├── billing schema
    ├── analytics schema
    └── audit schema
```

The main idea:

```txt
MySQL:      database = organizational boundary
PostgreSQL: schema   = organizational boundary
```

In PostgreSQL, schemas are namespaces inside a database. This makes it natural to
keep related application areas such as `auth`, `billing`, `analytics`, and
`audit` inside the same database while still separating their tables.

## Prerequisites

- PostgreSQL running locally
- Go installed
- A database named `teamsync`
- A PostgreSQL role that can connect to `teamsync`

The current connection string is hardcoded in `cmd/main.go`:

```txt
postgres://ibrahim:123456@localhost:5432/teamsync
```

Change the username, password, host, port, or database name if your local
PostgreSQL setup is different.

## Run The App

From the `hands-on` directory:

```bash
go run cmd/main.go
```

If the connection works, the app prints the PostgreSQL version:

```txt
PostgreSQL 16...
```

This confirms that Go can connect to PostgreSQL and run a query.

## Useful psql Commands

```sql
\l
\c teamsync
\dn
\dt
\d auth.users
\q
```

For the full Day 1 command list, see
[../Notes/Postgress-Mastery/day-01/commands.md](../Notes/Postgress-Mastery/day-01/commands.md).

## What This Validates

- The local PostgreSQL server is running
- The `teamsync` database is reachable
- The configured role can authenticate
- The Go module can use `pgx`
- A basic query can be executed from Go

## Related Notes

- [Concepts](../Notes/Postgress-Mastery/day-01/concepts.md)
- [Commands](../Notes/Postgress-Mastery/day-01/commands.md)
- [FAQs](../Notes/Postgress-Mastery/day-01/FAQs.md)

## Next Steps

- Move the connection string into an environment variable
- Add SQL files for creating schemas and tables
- Create migrations for repeatable database setup
- Add CRUD examples for `auth.users`
- Add a small repository layer in Go
