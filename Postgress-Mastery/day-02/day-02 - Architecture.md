# Day 2 Architecture

Day 1 introduced the basic PostgreSQL shape in [[day-01 - Architecture|Day 1 Architecture]]:

```txt
Cluster (ibrahim)
 └── Database (teamsync)
      ├── auth schema
      │    └── users table
      └── projects schema
```

Day 2 evolves that into a small enterprise/SaaS-style system.

For relationship details, use [[relationships]]. For column type choices, use [[datatypes]].

---

## 1. Full Database Shape

```txt
Cluster (ibrahim)
 └── Database (teamsync)
      ├── auth schema
      │    ├── organizations table
      │    ├── users table
      │    └── memberships table
      │
      └── projects schema
           └── projects table
```

The important shift:

```txt
Day 1 = tables exist
Day 2 = tables model business relationships
```

---

## 2. Schema Responsibilities

### auth schema

The `auth` schema owns identity and access concepts.

```txt
auth.organizations = teams, companies, workspaces
auth.users         = people using the app
auth.memberships   = who belongs to which organization
```

This is where you model:

- users
- organizations
- roles
- membership rules
- access boundaries

### projects schema

The `projects` schema owns project-related business data.

```txt
projects.projects = work/projects created inside organizations
```

This is separate from `auth` because projects are application/business data, not identity data.

Memory hook:

```txt
auth schema     = who can use the system
projects schema = what work exists in the system
```

---

## 3. Table Meanings

| Table | Purpose |
| --- | --- |
| `auth.organizations` | stores companies, teams, or workspaces |
| `auth.users` | stores application users |
| `auth.memberships` | connects users to organizations with a role |
| `projects.projects` | stores projects owned by organizations |

Each table represents one business concept. That keeps the schema clean.

---

## 4. Relationship Picture

```txt
auth.users
    │
    │ many-to-many through memberships
    ▼
auth.memberships
    ▲
    │ many-to-many through memberships
    │
auth.organizations
    │
    │ one-to-many
    ▼
projects.projects
```

Another way to read it:

```txt
users <-> memberships <-> organizations -> projects
users -------------------------------> projects.created_by
```

Meaning:

- users can belong to many organizations
- organizations can have many users
- memberships store the user role inside an organization
- organizations own projects
- users create projects

This note only shows the architecture-level picture. For the relationship rules,
foreign keys, join table behavior, and query examples, see [[relationships]].

---

## 5. Why memberships Exists

Do not put `organization_id` directly on `auth.users` if users can belong to many organizations.

Bad for multi-organization SaaS:

```txt
users.organization_id
```

Better:

```txt
users <-> memberships <-> organizations
```

`auth.memberships` is a join table. It also stores extra relationship data:

```sql
role TEXT NOT NULL DEFAULT 'member'
```

That makes it the beginning of an RBAC/access-control model. For the deeper many-to-many explanation, see [[relationships#7. Join Table memberships|Join Table: memberships]].

Memory hook:

```txt
memberships is not just a link.
memberships is the user's role inside an organization.
```

---

## 6. Why projects Has Two User/Organization Links

`projects.projects` has:

```sql
organization_id BIGINT NOT NULL REFERENCES auth.organizations(id)
created_by BIGINT NOT NULL REFERENCES auth.users(id)
```

These mean different things:

| Column | Meaning |
| --- | --- |
| `organization_id` | which organization owns the project |
| `created_by` | which user created the project |

This allows queries like:

```txt
Show all projects in organization 1.
Show all projects created by user 10.
```

Ownership and authorship are separate concepts. For the relationship-level explanation, see [[relationships#5. Another One-To-Many User Created Projects|User Created Projects]].

---

## 7. Final Architecture Map

```txt
teamsync database
├── auth
│   ├── organizations
│   │   └── owns many projects
│   │
│   ├── users
│   │   ├── belongs to organizations through memberships
│   │   └── creates projects
│   │
│   └── memberships
│       ├── organization_id -> organizations.id
│       ├── user_id -> users.id
│       └── role
│
└── projects
    └── projects
        ├── organization_id -> auth.organizations.id
        └── created_by -> auth.users.id
```

Remember:

```txt
Schemas separate responsibility.
Tables represent business concepts.
Foreign keys connect concepts.
Join tables model many-to-many relationships.
```
