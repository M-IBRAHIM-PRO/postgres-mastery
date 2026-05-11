# PostgreSQL Constraints

Constraints are how PostgreSQL protects the data model from invalid states.

For the Day 2 relationship model, see [[day-02/relationships|relationships]].
For delete behavior, see [[day-03 - Architecture]] and [[day-03 - FAQs]].

---

## 1. Why Constraints Matter

Without constraints, the database accepts bad data too easily:

- duplicate emails
- empty required values
- invalid roles
- broken references

Memory hook:

```txt
Constraints turn business rules into database rules.
```

---

## 2. `NOT NULL`

Use `NOT NULL` when a value must always exist.

```sql
name TEXT NOT NULL,
email TEXT NOT NULL
```

Good for:

- emails
- organization names
- foreign keys that are required

---

## 3. `UNIQUE`

Use `UNIQUE` when duplicates should be impossible.

Examples:

```sql
email TEXT UNIQUE
```

```sql
UNIQUE (organization_id, user_id)
```

Common SaaS uses:

- one user email per system
- one membership per user/organization pair
- one public identifier per row

---

## 4. `CHECK`

Use `CHECK` when a column must obey a rule.

Examples:

```sql
role TEXT CHECK (role IN ('owner', 'member'))
```

```sql
name TEXT CHECK (char_length(name) > 2)
```

Good for:

- allowed role values
- positive numeric values
- simple formatting boundaries

---

## 5. `DEFAULT`

Use `DEFAULT` when PostgreSQL should provide the normal value automatically.

Examples:

```sql
role TEXT NOT NULL DEFAULT 'member'
is_active BOOLEAN NOT NULL DEFAULT true
created_at TIMESTAMPTZ NOT NULL DEFAULT now()
```

Rule:

```txt
DEFAULT reduces repetitive insert logic.
```

---

## 6. `REFERENCES`

Foreign key constraints make relationships real.

Example:

```sql
organization_id BIGINT NOT NULL REFERENCES auth.organizations(id)
```

This guarantees:

- the organization row exists
- the project cannot point to a fake organization id

This does not automatically guarantee every business rule.

Example:

```txt
created_by exists
```

is not the same as:

```txt
created_by belongs to that organization
```

---

## 7. ON DELETE Behavior

Common actions:

```txt
CASCADE   = delete dependent rows too
RESTRICT  = block delete if children exist
SET NULL  = remove the reference
NO ACTION = enforce check at constraint time
```

Think carefully before using `CASCADE` on important business data.

Example question:

```txt
If an organization is deleted, should memberships and projects also disappear?
```

That is both a data rule and a product decision.

---

## 8. Constraint Mindset

Application code should validate inputs.
Database constraints should protect truth.

Best practice:

- put obvious invariants in PostgreSQL
- keep business workflows in the app when they span many conditions
- strengthen the database more as the system matures
