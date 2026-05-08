# Day 2 FAQs

These FAQs are for tricky questions that connect multiple Day 2 ideas.

Use the source notes for full explanations:

- System shape: [[day-02 - Architecture]]
- Type choices: [[datatypes]]
- Table relationships: [[relationships]]

---

## 1. Why use both `id` and `public_id`?

Short answer:

```txt
id        = private database identity
public_id = public/API identity
```

`id` is fast for internal joins. `public_id` is safer to expose in URLs and APIs.

For the full type explanation, see
[[datatypes#2. BIGSERIAL vs UUID|BIGSERIAL vs UUID]].

---

## 2. Why are foreign keys `BIGINT` instead of `BIGSERIAL`?

`BIGSERIAL` creates a new id. `BIGINT` stores an existing id.

Foreign keys point to existing rows, so they use `BIGINT`.

For the relationship explanation, see [[relationships#3. Foreign Keys|Foreign Keys]].
For the type details, see [[datatypes#Numeric Types|Numeric Types]].

---

## 3. Why not use UUID as the only primary key?

You can, but Day 2 uses the common SaaS compromise:

```txt
BIGSERIAL id   = fast internal joins
UUID public_id = safe external references
```

See [[datatypes#2. BIGSERIAL vs UUID|BIGSERIAL vs UUID]].

---

## 4. Why use `TEXT` instead of `VARCHAR(255)`?

In PostgreSQL, `TEXT` is the normal flexible string type. Use `VARCHAR(n)` only when the limit is a real business rule.

See [[datatypes#4. TEXT vs VARCHAR|TEXT vs VARCHAR]].

---

## 5. When should I use `JSONB`?

Use `JSONB` for flexible details like preferences or metadata.

Do not use `JSONB` for core relationships, permissions, or data that needs foreign keys.

See [[datatypes#5. JSON vs JSONB|JSON vs JSONB]].

---

## 6. Why use `TIMESTAMPTZ` for `created_at` and `updated_at`?

Because those columns represent real moments in time.

Use `TIMESTAMPTZ` for application event timestamps.

See [[datatypes#3. TIMESTAMP vs TIMESTAMPTZ|TIMESTAMP vs TIMESTAMPTZ]].

---

## 7. Why does `deleted_at` allow `NULL`?

Because most rows are not deleted.

```txt
deleted_at = NULL      -> active row
deleted_at = timestamp -> soft deleted row
```

See [[relationships#11. Soft Deletes|Soft Deletes]].

---

## 8. Why have both `is_active` and `deleted_at`?

They answer different questions:

```txt
is_active = can this account operate?
deleted_at = is this row removed from normal use?
```

`is_active = false` can mean suspended or disabled. `deleted_at` means soft deleted.

See [[relationships#11. Soft Deletes|Soft Deletes]].

---

## 9. Why do we need `memberships`?

Because users and organizations are many-to-many:

```txt
users <-> memberships <-> organizations
```

`memberships` also stores the user's role inside the organization.

See [[relationships#6. Many-To-Many|Many-To-Many]] and
[[relationships#7. Join Table memberships|Join Table: memberships]].

---

## 10. Why is `UNIQUE (organization_id, user_id)` important?

It prevents the same user from having duplicate membership rows in the same organization.

See [[relationships#8. Why UNIQUE Matters In memberships|Why UNIQUE Matters In memberships]].

---

## 11. Why does `projects.projects` have both `organization_id` and `created_by`?

Because ownership and authorship are different:

```txt
organization_id = who owns the project
created_by      = who created the project
```

See [[day-02 - Architecture#7. Why projects Has Two UserOrganization Links|Why projects Has Two User/Organization Links]]
and [[relationships#5. Another One-To-Many User Created Projects|User Created Projects]].

---

## 12. Should the database enforce that `created_by` is a member of `organization_id`?

Foreign keys prove that rows exist. They do not automatically prove business permission.

The current schema guarantees:

- the organization exists
- the creator user exists

It does not guarantee:

```txt
the creator belongs to that organization
```

That rule can start in application logic and later move into stronger database constraints or triggers if needed.

See [[relationships#3. Foreign Keys|Foreign Keys]].

---

## 13. Why not store project members in `projects.metadata` JSONB?

Project membership is relationship data. Relationship data needs tables, foreign keys, uniqueness rules, and joins.

Use `JSONB` for flexible details, not core relationships.

See [[datatypes#5. JSON vs JSONB|JSON vs JSONB]] and
[[relationships#6. Many-To-Many|Many-To-Many]].

---

## 14. Should `role` be `TEXT` or an `ENUM`?

For learning, `TEXT` is simple. For stronger protection, use `TEXT` with a `CHECK` constraint or an enum.

```txt
TEXT         = flexible
TEXT + CHECK = flexible but protected
ENUM         = strict but harder to evolve
```

See [[datatypes#Enumerated Types|Enumerated Types]].

---

## 15. What is the difference between schema design and table creation?

Table creation is syntax.

Schema design is modeling:

```txt
What concepts exist?
How do they relate?
What should be impossible?
What should PostgreSQL protect?
```

For the Day 2 system model, see [[day-02 - Architecture]].