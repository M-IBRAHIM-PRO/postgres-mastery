# Day 1 FAQs

These answers are written to build memory, not just definitions. PostgreSQL
becomes much easier when the mental models are clear.

## 1. What is the difference between a schema and a database?

A database is a separate container of data inside a PostgreSQL server. A schema
is a namespace inside one database.

Think of a PostgreSQL server like an office building:

```txt
PostgreSQL server = office building
Database          = company office
Schema            = department inside the office
Table             = filing cabinet inside a department
Row               = one file inside the cabinet
```

Example:

```txt
teamsync database
├── auth schema
│   └── users table
├── billing schema
│   └── invoices table
└── analytics schema
    └── events table
```

The database is `teamsync`. Inside it, schemas such as `auth`, `billing`, and
`analytics` organize tables by feature area.

In MySQL, people often use separate databases for organization. In PostgreSQL,
you usually use schemas for that.

Memory hook:

```txt
Database = big container
Schema   = named section inside the container
```

## 2. What problem does MVCC solve?

MVCC means Multi-Version Concurrency Control. It helps PostgreSQL handle many
readers and writers at the same time without forcing everyone to wait on each
other.

Imagine a document in Google Docs. If someone is editing a paragraph, another
person can still read the previous stable version instead of being blocked.
PostgreSQL does something similar with rows.

When a row is updated, PostgreSQL does not simply overwrite it in place. It
creates a new version of that row. Different transactions can see the version
that makes sense for their point in time.

This means:

- Readers do not block writers
- Writers do not block readers
- Applications can handle more users at the same time
- Queries can see a consistent snapshot of data

Example idea:

```txt
Old row version: balance = 100
New row version: balance = 150
```

One transaction may still see `100`, while a newer transaction sees `150`,
depending on when each transaction started.

Memory hook:

```txt
MVCC = PostgreSQL keeps row versions so readers and writers can work together.
```

## 3. Why does PostgreSQL use WAL?

WAL means Write-Ahead Logging. PostgreSQL writes changes to a log before it
changes the actual table data.

Think of WAL like writing an order in a notebook before the kitchen starts
cooking. If the power goes out, the restaurant can look at the notebook and know
which orders were accepted.

PostgreSQL uses WAL for three big reasons:

- Durability: committed data should not disappear
- Crash recovery: PostgreSQL can recover after a shutdown or crash
- Replication: changes can be copied to another PostgreSQL server

The basic flow is:

```txt
1. Write change to WAL
2. Confirm the change is safely recorded
3. Apply the change to table data
```

If PostgreSQL crashes after step 2, it can replay the WAL and finish the work.

Memory hook:

```txt
WAL = PostgreSQL's safety notebook.
```

## 4. Why does TIMESTAMPTZ matter?

`TIMESTAMPTZ` means timestamp with time zone. It stores a moment in time in a
timezone-aware way.

This matters because modern applications often have users, servers, background
jobs, and reports in different time zones.

Imagine a meeting scheduled at:

```txt
2026-05-08 10:00
```

That time is incomplete. Is it 10:00 in Karachi, London, New York, or UTC? Those
are different real moments.

`TIMESTAMPTZ` helps PostgreSQL understand the actual point in time. PostgreSQL
stores it internally in a normalized form and can display it according to the
session time zone.

Use `TIMESTAMPTZ` for things like:

- User signup time
- Payment time
- Login time
- Order creation time
- Audit logs
- Background job scheduling

Be careful with plain `TIMESTAMP`. It stores a date and time without timezone
meaning. That can be fine for things like "store opens at 09:00 every day", but
it is risky for real-world events.

Memory hook:

```txt
TIMESTAMP  = wall clock text
TIMESTAMPTZ = real moment in time
```

## 5. Why are PostgreSQL schemas powerful?

Schemas let you organize one database into clean sections.

In a real product, everything should not live in one messy pile of tables. A SaaS
application might have users, billing, analytics, audit logs, and notifications.
Schemas let each area have its own namespace.

Example:

```txt
auth.users
billing.invoices
analytics.events
audit.login_events
```

This is powerful because:

- Table names can be cleaner
- Feature areas are easier to understand
- Permissions can be managed per schema
- Large systems can stay organized
- Teams can own different parts of the database

Without schemas, you may end up with names like:

```txt
auth_users
billing_invoices
analytics_events
audit_login_events
```

That works for small projects, but schemas give PostgreSQL a more natural
organization system.

Memory hook:

```txt
Schemas = folders for tables.
```

## 6. What is the difference between PostgreSQL roles and MySQL users?

In PostgreSQL, permissions are based on roles. A role can behave like a user, a
group, or both.

A role can:

- Log in
- Own databases, schemas, and tables
- Receive permissions
- Pass permissions to other roles
- Act like a group of permissions

Think of roles like badges in a company. One badge may let a person enter the
building. Another badge may allow access to the finance room. Another may allow
admin actions.

Example:

```txt
app_user       = can log in from the application
readonly_role  = can read tables
billing_admin  = can manage billing tables
```

The application user can be granted one or more roles depending on what it needs.

In many MySQL setups, the word "user" is the main mental model. In PostgreSQL,
the better mental model is "role". Some roles can log in like users, and some
roles only exist to group permissions.

Memory hook:

```txt
PostgreSQL role = user, group, or permission badge.
```

## Final Day 1 Picture

Keep this full picture in your head:

```txt
PostgreSQL cluster
└── teamsync database
    ├── auth schema
    │   └── users table
    ├── billing schema
    ├── analytics schema
    └── audit schema
```

And remember:

```txt
Schemas organize tables.
Roles control access.
MVCC handles concurrency.
WAL protects changes.
TIMESTAMPTZ records real moments.
```
