# Table Partitioning

Partitioning splits one logical table into many physical child tables.
PostgreSQL routes rows automatically based on a partition key.

For the Day 4 system picture, see [[day-04 - Architecture]].
For the activity_log table design, see [[new-tables#3. events.activity_log|events.activity_log]].

---

## 1. Why Partitioning

A high-volume append-only table like `events.activity_log` will grow to millions of rows.

Problems without partitioning:

```txt
Full table scans become slow even with indexes
Vacuuming the whole table takes longer over time
Deleting old data (retention policy) requires scanning to find old rows
```

Partitioning solves these by dividing the data physically:

```txt
Query only touches partitions that match the WHERE clause
Old partitions can be dropped instantly (no row-by-row delete)
Vacuuming runs per partition, not the whole table
```

---

## 2. PARTITION BY RANGE

Range partitioning assigns rows to partitions based on a column value range.

Most common partition key for time-series and audit tables: `TIMESTAMPTZ`.

```sql
PARTITION BY RANGE (occurred_at)
```

Each child partition covers a specific range:

```sql
-- future example
CREATE TABLE events.activity_log_2025_01
    PARTITION OF events.activity_log
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
```

Postgres routes every `INSERT` automatically:

```txt
occurred_at = '2025-01-15' → goes into activity_log_2025_01
occurred_at = '2025-02-10' → goes into activity_log_2025_02
```

---

## 3. Partition-Ready Shape

`events.activity_log` is declared with `PARTITION BY RANGE` but only has a default partition today.

This is called a partition-ready shape:

```txt
The table is declared as partitioned
Inserts work immediately via the default partition
Named partitions get added later without schema changes
```

The primary key must include the partition key:

```sql
PRIMARY KEY (id, occurred_at)
```

Why:

```txt
PostgreSQL requires the partition key to be part of every unique constraint.
Without occurred_at in the PK, Postgres cannot guarantee uniqueness across partitions.
```

---

## 4. Default Partition

```sql
CREATE TABLE IF NOT EXISTS events.activity_log_default
    PARTITION OF events.activity_log DEFAULT;
```

The default partition catches every row that does not match any explicit range.

```txt
No monthly partitions yet  → all rows go to default
Monthly partition added    → rows in that range go there; default catches the rest
```

Without a default partition, inserts that do not match any range would fail.

---

## 5. Adding a Named Partition

When volume grows, add a monthly partition:

```sql
CREATE TABLE events.activity_log_2025_05
    PARTITION OF events.activity_log
    FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');
```

That partition now handles all May 2025 rows automatically.

---

## 6. Dropping Old Data

Without partitioning:

```sql
-- slow, locks rows, requires vacuum
DELETE FROM events.activity_log WHERE occurred_at < '2024-01-01';
```

With partitioning:

```sql
-- instant, no row scan, no vacuum needed
DROP TABLE events.activity_log_2023_12;
```

This is the main operational benefit of range partitioning for audit tables.

---

## 7. When Not to Partition

Partitioning adds complexity.

Do not use it when:

```txt
Table is small (under a few million rows)
No clear partition key exists
Query patterns do not align with the partition key
```

Use it when:

```txt
Table grows continuously with time-series or audit data
You need fast range queries by time
You need cheap data retention / archival by time range
```
