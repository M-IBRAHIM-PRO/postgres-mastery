# PostgreSQL Mastery

Compact learning workspace for PostgreSQL concepts, schema design, and Go-based
hands-on practice.

## Structure

```txt
.
├── Postgres-Mastery/
│   ├── day-01/
│   └── day-02/
├── hands-on/
│   ├── cmd/main.go
│   ├── config.go
│   ├── internal/users/
│   └── sql/
└── README.md
```

## Current Focus

Day 3 shifts the project from schema design into production-style data access:

```txt
teamsync database
├── auth
│   ├── organizations
│   ├── users
│   └── memberships
└── projects
    └── projects
```

Main ideas:

- PostgreSQL schemas organize application areas.
- JOINs reconstruct application data across related tables.
- constraints protect data integrity close to the database.
- indexes improve common lookup and join paths.
- transactions keep multi-step writes consistent.
- parameterized Go queries safely read real data from the schema.

## Hands-On

SQL files:

- [day-01.sql](hands-on/sql/queries/day-01.sql)
- [day-02.sql](hands-on/sql/queries/day-02.sql)
- [day-03.sql](hands-on/sql/queries/day-03.sql)
- [day-03 seed](hands-on/sql/seeds/day-03.sql)

Suggested local flow:

```bash
psql -d teamsync -f hands-on/sql/queries/day-02.sql
psql -d teamsync -f hands-on/sql/seeds/day-03.sql
cd hands-on
go run cmd/main.go
```

Run the Go app:

```bash
cd hands-on
go run cmd/main.go
```

The app loads database config from `hands-on/.env`, connects with `pgx`, then:

- finds one user by email
- lists the members of organization `1`

Both repository queries use PostgreSQL parameters like `$1` rather than string
concatenation.

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
