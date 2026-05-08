# PostgreSQL Relationships

Relationships are how separate tables become one connected system.

Beginner memory model:

```txt
Table        = one kind of thing
Primary key  = the row's identity
Foreign key  = a pointer to another row
Relationship = the rule between those things
```

Day 2 moves from one table to a small SaaS-style model:

```txt
organizations
users
memberships
projects
```

---

## 1. The Tables In This Schema

```txt
auth.organizations
auth.users
auth.memberships
projects.projects
```

Simple meaning:

| Table | Meaning |
| --- | --- |
| `auth.organizations` | companies, teams, workspaces |
| `auth.users` | people who can use the app |
| `auth.memberships` | which users belong to which organizations |
| `projects.projects` | projects owned by an organization |

The schema is not just storing data. It is modeling rules:

- an organization can have many projects
- a user can create many projects
- a user can belong to many organizations
- an organization can have many users
- a user should not be added to the same organization twice

---

## 2. Primary Keys

A primary key uniquely identifies one row.

```sql
id BIGSERIAL PRIMARY KEY
```

In this project, tables use `id` as the internal database identity.

Example:

```txt
auth.users.id = 1
```

That means "this exact user row."

Memory hook:

```txt
Primary key = row's passport inside the database.
```

---

## 3. Foreign Keys

A foreign key points to a primary key in another table.

Example:

```sql
organization_id BIGINT NOT NULL REFERENCES auth.organizations(id)
```

This says:

```txt
This row must belong to a real organization.
```

PostgreSQL will reject invalid data. You cannot create a project with an
`organization_id` that does not exist in `auth.organizations`.

Memory hook:

```txt
Foreign key = trustworthy pointer to another row.
```

---

## 4. One-To-Many

One-to-many means one row in table A can be connected to many rows in table B.

In this schema:

```txt
organization -> projects
```

One organization can have many projects.

SQL:

```sql
CREATE TABLE projects.projects (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL REFERENCES auth.organizations(id),
    name TEXT NOT NULL
);
```

The foreign key lives on the "many" side.

```txt
One organization
└── many projects
```

So `projects.projects` stores `organization_id`.

Memory hook:

```txt
The many side carries the foreign key.
```

---

## 5. Another One-To-Many: User Created Projects

This column:

```sql
created_by BIGINT NOT NULL REFERENCES auth.users(id)
```

means:

```txt
One user can create many projects.
Each project has one creator.
```

Relationship picture:

```txt
auth.users
└── projects.projects.created_by
```

This is separate from organization ownership. A project belongs to an
organization, but it was created by a user.

That gives two different meanings:

| Column | Meaning |
| --- | --- |
| `organization_id` | who owns the project |
| `created_by` | who created the project |

---

## 6. Many-To-Many

Many-to-many means many rows on both sides can connect to each other.

In this schema:

```txt
users <-> organizations
```

A user can belong to many organizations.

An organization can have many users.

You do not store this by putting arrays of ids inside either table. Instead, you
create a join table.

```txt
auth.users
    |
    | through auth.memberships
    |
auth.organizations
```

Memory hook:

```txt
Many-to-many needs a middle table.
```

---

## 7. Join Table: memberships

`auth.memberships` connects users and organizations.

```sql
CREATE TABLE auth.memberships (
    id BIGSERIAL PRIMARY KEY,
    organization_id BIGINT NOT NULL REFERENCES auth.organizations(id),
    user_id BIGINT NOT NULL REFERENCES auth.users(id),
    role TEXT NOT NULL DEFAULT 'member',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (organization_id, user_id)
);
```

Each row means:

```txt
This user belongs to this organization with this role.
```

Example data:

| organization_id | user_id | role |
| --- | --- | --- |
| `1` | `10` | `owner` |
| `1` | `11` | `member` |
| `2` | `10` | `admin` |

This means user `10` belongs to organization `1` and organization `2`.

---

## 8. Why UNIQUE Matters In memberships

This line is very important:

```sql
UNIQUE (organization_id, user_id)
```

It prevents duplicate memberships.

Without it, this bad data would be possible:

| organization_id | user_id | role |
| --- | --- | --- |
| `1` | `10` | `member` |
| `1` | `10` | `admin` |

That creates confusion:

```txt
Is user 10 a member or admin in organization 1?
```

The unique constraint says:

```txt
One user can appear only once inside the same organization.
```

Memory hook:

```txt
Foreign keys connect rows.
Unique constraints prevent duplicate meaning.
```

---

## 9. Relationship Diagram

```txt
auth.organizations
    id
    |
    | one-to-many
    v
projects.projects
    organization_id


auth.users
    id
    |
    | one-to-many
    v
projects.projects
    created_by


auth.organizations
    id
    |
    | one-to-many
    v
auth.memberships
    organization_id
    user_id
    ^
    | one-to-many
    |
auth.users
    id
```

Simpler picture:

```txt
users <-> memberships <-> organizations -> projects
users -------------------------------> projects created_by
```

---

## 10. How To Think About Deletes

Foreign keys also affect deletes.

If a project references an organization, PostgreSQL must decide what happens
when that organization is deleted.

Common options:

| Option | Meaning |
| --- | --- |
| `RESTRICT` / `NO ACTION` | do not allow delete if children exist |
| `CASCADE` | delete child rows too |
| `SET NULL` | keep child row, clear the foreign key |
| `SET DEFAULT` | keep child row, set foreign key to default |

Your current schema does not specify delete behavior, so PostgreSQL uses the
default behavior, which prevents deleting a referenced parent row.

That is often good for beginners because it protects data.

Example:

```txt
Cannot delete organization 1 if projects still point to it.
```

---

## 11. Soft Deletes

This schema uses nullable `deleted_at` columns:

```sql
deleted_at TIMESTAMPTZ
```

That means rows can be "deleted" without being physically removed.

Example:

```sql
UPDATE auth.users
SET deleted_at = NOW()
WHERE id = 10;
```

The row still exists, but the app treats it as deleted.

Why this matters:

- audit history is preserved
- relationships do not break suddenly
- deleted records can sometimes be restored
- reporting stays more complete

Memory hook:

```txt
Hard delete removes the row.
Soft delete marks the row as inactive/deleted.
```

---

## 12. Common Query Patterns

Find all projects for an organization:

```sql
SELECT *
FROM projects.projects
WHERE organization_id = 1;
```

Find all users in an organization:

```sql
SELECT u.*
FROM auth.users u
JOIN auth.memberships m ON m.user_id = u.id
WHERE m.organization_id = 1;
```

Find all organizations for a user:

```sql
SELECT o.*
FROM auth.organizations o
JOIN auth.memberships m ON m.organization_id = o.id
WHERE m.user_id = 10;
```

Find all projects with creator details:

```sql
SELECT p.name, u.full_name AS creator
FROM projects.projects p
JOIN auth.users u ON u.id = p.created_by;
```

---

## 13. Practical Design Rules

Use these rules when designing relationships:

- Put the foreign key on the "many" side.
- Use a join table for many-to-many relationships.
- Add `UNIQUE` constraints when duplicate meaning should be impossible.
- Use internal `BIGINT` ids for joins.
- Use `UUID public_id` for external APIs.
- Prefer real foreign keys over storing ids inside `JSONB`.
- Think carefully before using `ON DELETE CASCADE`.
- Use `deleted_at` when the business needs history.

---

## 14. Final Memory Map

```txt
Primary key  = identifies this row
Foreign key  = points to another row
One-to-many  = parent row has many child rows
Many-to-many = two sides connected by a join table
Join table   = relationship table
UNIQUE       = prevents duplicate meaning
deleted_at   = soft delete marker
```

For this project:

```txt
organizations -> projects
users -> projects
users <-> memberships <-> organizations
```
