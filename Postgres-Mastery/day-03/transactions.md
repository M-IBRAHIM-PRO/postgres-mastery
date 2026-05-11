# PostgreSQL Transactions

Transactions protect multi-step work from partial failure.

Day 1 introduced [[day-01/concepts#Concept 4 — MVCC|MVCC]], which helps explain why transactional systems can stay concurrent.

---

## 1. Why Transactions Matter

Real backend work often has multiple writes that must succeed together.

Example:

```txt
Create organization
Create owner membership
Both must succeed together
```

Without a transaction:

- organization might be created
- membership might fail
- system is left in a broken state

---

## 2. Core Commands

```sql
BEGIN;

-- SQL statements

COMMIT;
```

Rollback flow:

```sql
BEGIN;

-- SQL statements

ROLLBACK;
```

Meaning:

```txt
COMMIT   = make all changes permanent
ROLLBACK = cancel all changes in this transaction
```

---

## 3. SaaS Example

```sql
BEGIN;

INSERT INTO auth.organizations (name)
VALUES ('Acme')
RETURNING id;

INSERT INTO auth.memberships (organization_id, user_id, role)
VALUES (1, 10, 'owner');

COMMIT;
```

Business meaning:

```txt
An organization should not exist without its first owner.
```

---

## 4. Why Transactions Fit Day 3

Day 2 focused on:

```txt
What relationships should exist?
```

Transactions ask:

```txt
How do I keep those relationships correct while writing data?
```

---

## 5. Beginner Rules

- use transactions for multi-step business actions
- keep them short
- do not leave transactions open longer than necessary
- combine them with constraints for stronger safety

Memory hook:

```txt
Transaction = all steps succeed, or none do.
```
