# Day 3 FAQs

These FAQs focus on production-style confusion points, not base definitions.

Use the source notes for full explanations:

- Querying: [[querying]]
- JOINs: [[joins]]
- Constraints: [[constraints]]
- Indexing: [[indexing]]
- Transactions: [[transactions]]
- Day-level system picture: [[day-03 - Architecture]]

---

## 1. Why avoid `SELECT *` in production?

Because it often returns more data than needed.

That creates three problems:

- unnecessary I/O
- noisier API payloads
- fragile assumptions when new columns are added later

Use [[querying#2. SELECT Basics|SELECT Basics]].

---

## 2. When should I use `INNER JOIN` vs `LEFT JOIN`?

Use:

```txt
INNER JOIN = only rows with a matching relationship
LEFT JOIN  = keep left-side rows even if the right side is missing
```

Example:

```txt
Users with memberships only      -> INNER JOIN
All users, even with no projects -> LEFT JOIN
```

Use [[joins#2. INNER JOIN|INNER JOIN]] and [[joins#3. LEFT JOIN|LEFT JOIN]].

---

## 3. Why are constraints not enough for all business rules?

Constraints are excellent for obvious invariants:

- required values
- uniqueness
- valid references
- simple allowed values

But some rules are broader than one row or one column.

Example:

```txt
User exists
```

is easy for a foreign key.

```txt
User belongs to this organization and may create this project
```

is a larger business rule that often starts in application logic.

Use [[constraints#6. REFERENCES|REFERENCES]].

---

## 4. Should I always add an index to foreign keys?

Not always, but very often in real systems.

Indexes are especially useful when the foreign key column is used often for:

- joins
- filtering
- sorting inside a scope

Example:

```txt
projects.organization_id
memberships.user_id
memberships.organization_id
```

Use [[indexing#5. When Indexes Help|When Indexes Help]].

---

## 5. Why not index every column?

Because indexes also slow down writes and consume storage.

Every extra index has a cost on:

- inserts
- updates
- deletes

Use [[indexing#6. When Too Many Indexes Hurt|When Too Many Indexes Hurt]].

---

## 6. What is the first thing I should learn from `EXPLAIN ANALYZE`?

Start simple:

```txt
Did PostgreSQL scan the whole table,
or did it use a better lookup path?
```

You do not need optimizer internals yet.

Focus first on:

- sequential scan
- index scan
- rough runtime difference

Use [[indexing#7. EXPLAIN Basics|EXPLAIN Basics]].

---

## 7. When do I need a transaction?

When one business action needs multiple SQL statements to succeed together.

Classic example:

```txt
Create organization
Create first owner membership
```

If one step fails, the whole action should fail.

Use [[transactions#1. Why Transactions Matter|Why Transactions Matter]].

---

## 8. Are transactions only for failures?

No.

They are also for correctness.

Transactions define a safe boundary around related writes so the database treats them as one unit of work.

Use [[transactions#2. Core Commands|Core Commands]].

---

## 9. Is `TRUNCATE` just a faster `DELETE`?

It is faster for clearing whole tables, but it is not the same tool.

```txt
DELETE   = row-level removal, can filter with WHERE
TRUNCATE = fast full-table reset
```

Use [[querying#1. Data Manipulation|Data Manipulation]].

---

## 10. What is the main Day 3 mindset change?

Day 2 asked:

```txt
What should the schema model?
```

Day 3 asks:

```txt
How do I query, protect, and optimize that schema in production?
```

Use [[day-03 - Architecture]].
