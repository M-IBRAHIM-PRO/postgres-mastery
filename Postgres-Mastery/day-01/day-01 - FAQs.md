# Day 1 FAQs

These FAQs are for the parts that usually feel confusing on Day 1. The short definitions live in [[concepts]], and the database picture lives in [[day-01 - Architecture]].

---

## 1. What is the difference between a schema and a database?

For the short definition, start with [[concepts#Concept 2 — Schemas|Schemas]].

The tricky part is the mental model:

```txt
PostgreSQL server = office building
Database          = company office
Schema            = department inside the office
Table             = filing cabinet inside a department
Row               = one file inside the cabinet
```

So in `teamsync`, schemas like `auth` and `projects` are not separate
databases. They are named sections inside the same database.

Memory hook:

```txt
Database = big container
Schema   = named section inside the container
```

---

## 2. Why are PostgreSQL schemas powerful?

For the basic schema definition, see [[concepts#Concept 2 — Schemas|Schemas]].
For the current project layout, see [[day-01 - Architecture]].

Schemas are powerful because they let one database stay organized as the system
grows.

Example:

```txt
auth.users
projects.projects
billing.invoices
analytics.events
```

Without schemas, table names often become noisy:

```txt
auth_users
project_projects
billing_invoices
analytics_events
```

The schema gives the table a home.

Memory hook:

```txt
Schemas = folders for tables.
```

---

## 3. What problem does MVCC solve?

For the short definition, see [[concepts#Concept 4 — MVCC|MVCC]].

The confusing part is this: PostgreSQL does not need every reader and writer to
stand in one line.

Imagine a shared document. While one person is editing, another person can still
read the previous stable version. PostgreSQL does something similar with row
versions.

This helps because:

- readers do not block writers
- writers do not block readers
- each transaction can see a consistent snapshot

Memory hook:

```txt
MVCC = row versions for smooth concurrency.
```

---

## 4. Why does PostgreSQL use WAL?

For the short definition, see [[concepts#Concept 5 — WAL|WAL]].

The beginner-friendly analogy: WAL is PostgreSQL's safety notebook.

Before PostgreSQL changes the actual table files, it records the change in the
write-ahead log. If the server crashes, PostgreSQL can look at that log and
recover committed work.

WAL matters for:

- durability
- crash recovery
- replication

Memory hook:

```txt
WAL = write the plan before changing the data.
```

---

## 5. Why does TIMESTAMPTZ matter?

`TIMESTAMPTZ` means timestamp with time zone. This concept is introduced here
because real applications need accurate event times.

The tricky part:

```txt
2026-05-08 10:00
```

That is incomplete unless you know the timezone. Is it 10:00 in Karachi, UTC,
London, or New York?

Use `TIMESTAMPTZ` for real events:

- signup time
- payment time
- login time
- order creation time
- audit logs

Memory hook:

```txt
TIMESTAMP   = wall clock date/time
TIMESTAMPTZ = real moment in time
```

---

## 6. What is the difference between PostgreSQL roles and MySQL users?

For the short PostgreSQL definition, see [[concepts#Concept 3 — Roles|Roles]].

The tricky part is that a PostgreSQL role can act like:

- a login user
- a permission group
- an owner of database objects

Think of roles like access badges. One badge lets someone log in. Another badge
allows read-only access. Another allows managing billing tables.

Example:

```txt
app_user      = can log in from the application
readonly_role = can read tables
billing_admin = can manage billing data
```

Memory hook:

```txt
PostgreSQL role = user, group, or permission badge.
```
