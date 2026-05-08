# PostgreSQL Mastery

Compact learning workspace for PostgreSQL concepts, schema design, and Go-based
hands-on practice.

## Structure

```txt
.
├── Postgress-Mastery/
│   ├── day-01/
│   └── day-02/
├── hands-on/
│   ├── cmd/main.go
│   ├── config.go
│   ├── internal/users/
│   └── sql/queries/
└── README.md
```

## Current Focus

Day 2 expands the project from a simple users table into a SaaS-style schema:

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
- `BIGSERIAL` is used for internal ids.
- `UUID public_id` is used for public/API-safe ids.
- `TIMESTAMPTZ` is used for real event times.
- `JSONB` is used for flexible metadata/preferences.
- `memberships` models the many-to-many relationship between users and organizations.

## Hands-On

SQL files:

- [day-01.sql](hands-on/sql/queries/day-01.sql)
- [day-02.sql](hands-on/sql/queries/day-02.sql)

Run the Go app:

```bash
cd hands-on
go run cmd/main.go
```

The app loads database config from `hands-on/.env` and connects to PostgreSQL
with `pgx`.

## Notes

- [Day 1](Postgress-Mastery/day-01)
- [Day 2 Data Types](Postgress-Mastery/day-02/datatypes.md)
- [Day 2 Relationships](Postgress-Mastery/day-02/relationships.md)
- [Day 2 Architecture](<Postgress-Mastery/day-02/day-02 - Architecture.md>)
- [Day 2 FAQs](<Postgress-Mastery/day-02/day-02 - FAQs.md>)
