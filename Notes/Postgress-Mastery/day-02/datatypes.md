# PostgreSQL Data Types

Data types tell PostgreSQL what kind of truth a column stores.

```txt
Type = meaning + rules + storage + performance
```

For Day 2, focus on the types used in the schema. Do not try to memorize every
PostgreSQL type yet.

---

## 1. Types Used Today

From the Day 2 schema:

| Column pattern | Type | Why |
| --- | --- | --- |
| `id` | `BIGSERIAL` | fast internal primary key |
| `public_id` | `UUID` | safe public/API identifier |
| `name`, `email`, `description` | `TEXT` | normal PostgreSQL string |
| `is_active` | `BOOLEAN` | true/false state |
| `preferences`, `metadata` | `JSONB` | flexible settings/details |
| `created_at`, `updated_at`, `deleted_at` | `TIMESTAMPTZ` | real moment in time |
| `organization_id`, `user_id`, `created_by` | `BIGINT` | foreign key to another row |

Memory map:

```txt
BIGSERIAL   = private id
UUID        = public id
TEXT        = string
BOOLEAN     = yes/no
JSONB       = flexible object
TIMESTAMPTZ = real moment
BIGINT      = stored id / foreign key
```

---

## 2. `BIGSERIAL` vs `UUID`

Use both when building SaaS-style systems:

```sql
id BIGSERIAL PRIMARY KEY,
public_id UUID NOT NULL DEFAULT gen_random_uuid()
```

`BIGSERIAL` is best for internal joins:

- smaller indexes
- faster joins
- easy debugging

`UUID` is best for public references:

- hard to guess
- safer in URLs
- good for external APIs

Rule:

```txt
BIGSERIAL id   = internal database identity
UUID public_id = external/public identity
```

---

## 3. `BIGSERIAL` vs `BIGINT`

This is a common beginner confusion.

```txt
BIGSERIAL = creates a new auto-incrementing id
BIGINT    = stores a large integer
```

Use `BIGSERIAL` for a table's own primary key:

```sql
id BIGSERIAL PRIMARY KEY
```

Use `BIGINT` for foreign keys:

```sql
organization_id BIGINT NOT NULL REFERENCES auth.organizations(id)
```

The foreign key should point to an existing id, not create a new one.

---

## 4. `TIMESTAMP` vs `TIMESTAMPTZ`

For application event times, prefer:

```sql
created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
```

`TIMESTAMP` is just date + time without timezone meaning.

`TIMESTAMPTZ` represents a real moment in time and is safer for global systems.

Use `TIMESTAMPTZ` for:

- created time
- updated time
- deleted time
- login time
- payment time
- audit logs

Memory hook:

```txt
TIMESTAMP   = wall clock date/time
TIMESTAMPTZ = real moment in time
```

---

## 5. `TEXT` vs `VARCHAR`

In PostgreSQL, `TEXT` is usually the right default.

```sql
email TEXT NOT NULL UNIQUE
name TEXT NOT NULL
description TEXT
```

Use `VARCHAR(n)` only when the limit is a real rule:

```sql
country_code VARCHAR(2)
```

Avoid arbitrary limits like:

```sql
name VARCHAR(255)
```

Rule:

```txt
TEXT = normal string
VARCHAR(n) = string with a meaningful limit
```

---

## 6. `JSONB`

Use `JSONB` for flexible data:

```sql
preferences JSONB NOT NULL DEFAULT '{}'
metadata JSONB NOT NULL DEFAULT '{}'
```

Good use cases:

- preferences
- metadata
- feature flags
- optional settings

Do not use `JSONB` for core relationships.

Bad idea:

```json
{
  "organization_id": 1,
  "user_id": 10,
  "role": "admin"
}
```

That belongs in a real table like `auth.memberships`.

Rule:

```txt
JSONB = flexible details, not relationship design.
```

---

## 7. Practical Defaults

Use this table when designing normal SaaS tables:

| Need | Use |
| --- | --- |
| internal id | `BIGSERIAL PRIMARY KEY` |
| public id | `UUID DEFAULT gen_random_uuid()` |
| foreign key | `BIGINT REFERENCES ...` |
| string | `TEXT` |
| true/false | `BOOLEAN` |
| flexible object | `JSONB` |
| event time | `TIMESTAMPTZ` |
| money | `NUMERIC(12, 2)` |
| exact count | `INTEGER` or `BIGINT` |

---

## 8. Other PostgreSQL Types Exist

You do not need these for Day 2, but know the families:

| Family | Examples |
| --- | --- |
| numeric | `smallint`, `integer`, `bigint`, `numeric`, `real`, `double precision` |
| strings | `text`, `varchar`, `char` |
| time | `date`, `time`, `timestamp`, `timestamptz`, `interval` |
| structured | `json`, `jsonb`, arrays, composite types |
| search | `tsvector`, `tsquery` |
| network | `inet`, `cidr`, `macaddr` |
| special | `uuid`, `bytea`, `enum`, ranges, domains |

Look them up when a real use case appears. For now, master the Day 2 types.

