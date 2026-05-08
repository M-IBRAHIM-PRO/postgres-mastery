# PostgreSQL Mastery

This repository is a learning workspace for PostgreSQL. It keeps the theory,
commands, and runnable code together so each concept can be practiced in a real
local setup.

The current focus is Day 1: PostgreSQL foundations plus a small Go program that
connects to PostgreSQL using `pgx`.

## Repository Structure

```txt
.
├── Notes/
│   └── Postgress-Mastery/
│       └── day-01/
│           ├── FAQs.md
│           ├── commands.md
│           └── concepts.md
├── hands-on/
│   ├── cmd/
│   │   └── main.go
│   ├── go.mod
│   ├── go.sum
│   └── README.md
└── README.md
```

## Main Areas

`Notes/Postgress-Mastery` contains the written learning material. Day 1 covers
clusters, schemas, roles, MVCC, WAL, useful `psql` commands, and the first Go
database connection.

`hands-on` contains the runnable Go project. The current app connects to a local
PostgreSQL database named `teamsync` and prints the PostgreSQL server version.

## Day 1 Topics

- PostgreSQL cluster vs database vs schema
- Schemas as enterprise application boundaries
- PostgreSQL roles and permissions
- MVCC for concurrent reads and writes
- WAL for durability, crash recovery, and replication
- Basic `psql` navigation
- First Go connection with `github.com/jackc/pgx/v5`

## Target Database Model

```txt
PostgreSQL cluster
└── teamsync database
    ├── auth schema
    │   └── users table
    ├── billing schema
    ├── analytics schema
    └── audit schema
```

The key PostgreSQL mindset shift:

```txt
MySQL:      database = organizational boundary
PostgreSQL: schema   = organizational boundary
```

## Quick Start

Make sure PostgreSQL is running locally and that a `teamsync` database exists.
Then run the Go exercise:

```bash
cd hands-on
go run cmd/main.go
```

Expected result:

```txt
PostgreSQL 16...
```

If your local username, password, host, port, or database name is different,
update the connection string in [hands-on/cmd/main.go](hands-on/cmd/main.go).

## Reading Order

1. [Day 1 Concepts](Notes/Postgress-Mastery/day-01/concepts.md)
2. [Day 1 Commands](Notes/Postgress-Mastery/day-01/commands.md)
3. [Day 1 FAQs](Notes/Postgress-Mastery/day-01/FAQs.md)
4. [Hands-On README](hands-on/README.md)
5. [Go entry point](hands-on/cmd/main.go)

## Current Status

The project currently proves that Go can connect to PostgreSQL and execute a
basic query. The next natural step is to add repeatable SQL setup files, then
grow the Go app into real operations against an `auth.users` table.
