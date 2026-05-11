# Day 3 Architecture

Day 2 modeled the system shape:

```txt
users <-> memberships <-> organizations -> projects
```

See [[day-02/day-02 - Architecture|Day 2 Architecture]] for the structural map.

Day 3 does not mainly change the schema shape.
Day 3 changes how the backend works with that schema:

```txt
query data
protect data
speed up data access
group writes safely
```

Use [[querying]], [[joins]], [[constraints]], [[indexing]], and
[[transactions]] for the deeper topic notes.

---

## 1. System Shift

The progression becomes:

```txt
Day 1 = PostgreSQL foundations
Day 2 = schema and relationships
Day 3 = production-style data access
```

That means the learner now needs to think in four layers:

```txt
Model truth     -> tables and relationships
Read truth      -> SELECT and JOINs
Protect truth   -> constraints
Scale truth     -> indexes
Protect writes  -> transactions
```

---

## 2. Existing Schema, New Behaviors

Day 3 mostly works on the existing SaaS schema:

```txt
auth.users
auth.organizations
auth.memberships
projects.projects
```

The important change is not new tables first.
The important change is learning how to operate this schema correctly.

Examples:

- create users and organizations safely
- prevent duplicate memberships
- query organization members with JOINs
- paginate projects
- add indexes for common lookups
- wrap multi-step writes in transactions

---

## 3. Constraint Layer

The schema should now enforce more truth directly.

Examples:

```txt
email should be unique
membership pairs should not duplicate
roles should be valid
required columns should not be null
```

This is the shift from:

```txt
the table can store data
```

to:

```txt
the table can reject invalid data
```

---

## 4. Query Layer

Backend systems rarely need isolated rows.
They need connected answers:

```txt
Which users belong to an organization?
Which projects were created by this user?
How many projects does each organization have?
```

That is why Day 3 centers heavily on [[joins]] and [[querying]].

---

## 5. Performance Layer

Day 3 introduces the idea that correct SQL is not the whole job.

The database must also answer efficiently.

First tools:

- indexes
- `EXPLAIN ANALYZE`
- understanding sequential scan vs index scan

This is the beginning of performance thinking, not deep tuning yet.

---

## 6. Reliability Layer

Transactions protect multi-step operations.

Example:

```txt
Create organization
Add owner membership
If one fails, roll back both
```

This is the first strong move from single-statement SQL into backend workflow design.

---

## 7. Future Day 3 Extensions

The notes suggest a few natural next tables:

```txt
invitations
project_members
activity_logs
```

These are useful because they create real reasons to practice:

- constraints
- indexing
- relational querying
- JSONB
- audit-style timestamps

Important:

```txt
These are good Day 3 evolution ideas, not required current schema facts.
```
