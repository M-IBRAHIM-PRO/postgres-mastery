# Concept 1 — Cluster

In PostgreSQL:
A cluster means:

> one PostgreSQL server instance managing multiple databases.

Example:

```txt id="z8u3ln"
PostgreSQL Cluster
├── postgres
├── teamsync
├── analytics
└── testing
```

Unlike MySQL terminology.

---

# Concept 2 — Schemas

Schemas are namespaces.

Example:

```txt id="n7r5ya"
auth.users
billing.invoices
analytics.events
```

This is VERY important in enterprise systems.

Most enterprise PostgreSQL systems use:

* one database
* multiple schemas

---

# Concept 3 — Roles

PostgreSQL permissions are role-based.

Roles can:

* own tables
* inherit permissions
* login
* manage schemas

This is much more powerful than MySQL users.

---

# Concept 4 — MVCC

MOST IMPORTANT PostgreSQL concept.

PostgreSQL avoids heavy locking by:

* creating row versions

Meaning:

* readers don’t block writers
* writers don’t block readers

This enables high concurrency.

---

# Concept 5 — WAL

WAL = Write Ahead Logging

Before modifying actual tables:
PostgreSQL first writes changes into WAL logs.

Purpose:

* crash recovery
* durability
* replication

```txt
Cluster (ibrahim)
 └── Database (teamsync)
      ├── auth schema
      │    └── users table
      │
      ├── billing schema
      ├── analytics schema
      └── audit schema
```