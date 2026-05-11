# PostgreSQL JOINs

JOINs turn separate tables into usable application data.

For the Day 2 relationship model, see [[day-02/relationships|relationships]].
For general query syntax, see [[querying]].

---

## 1. Why JOINs Matter

Real backend data is usually spread across tables:

```txt
users
memberships
organizations
projects
```

APIs still need combined answers:

```txt
Which users belong to this organization?
Which projects were created by this user?
Which organization owns this project?
```

Memory hook:

```txt
Tables store truth separately.
JOINs rebuild the full story.
```

---

## 2. INNER JOIN

Use `INNER JOIN` when you only want rows with a matching relationship.

Example: get all members of an organization.

```sql
SELECT u.id, u.email, m.role
FROM auth.memberships AS m
JOIN auth.users AS u
  ON u.id = m.user_id
WHERE m.organization_id = 1;
```

Meaning:

```txt
Only return users that actually have a membership row.
```

---

## 3. LEFT JOIN

Use `LEFT JOIN` when you want all rows from the left side, even if no match exists on the right.

Example: show all users even if they have created no projects.

```sql
SELECT u.id, u.email, p.name AS project_name
FROM auth.users AS u
LEFT JOIN projects.projects AS p
  ON p.created_by = u.id;
```

Meaning:

```txt
Keep every user.
Project columns become NULL when no project exists.
```

---

## 4. Multi-Table JOINs

Example path:

```txt
users -> memberships -> organizations -> projects
```

Query:

```sql
SELECT
  u.email,
  o.name AS organization_name,
  p.name AS project_name
FROM auth.users AS u
JOIN auth.memberships AS m
  ON m.user_id = u.id
JOIN auth.organizations AS o
  ON o.id = m.organization_id
JOIN projects.projects AS p
  ON p.organization_id = o.id
WHERE u.id = 10;
```

This is how relational systems reconstruct business context.

---

## 5. Reliable JOIN Rules

Why foreign keys matter:

- they prove referenced rows exist
- they reduce broken relationships
- they make join logic trustworthy

Rule:

```txt
Bad schema design creates confusing JOINs.
Good foreign keys create reliable JOINs.
```

---

## 6. Common Day 3 JOIN Patterns

Get organization members:

```sql
SELECT u.id, u.email, m.role
FROM auth.organizations AS o
JOIN auth.memberships AS m
  ON m.organization_id = o.id
JOIN auth.users AS u
  ON u.id = m.user_id
WHERE o.id = 1;
```

Get all projects for one organization with creator email:

```sql
SELECT p.id, p.name, u.email AS creator_email
FROM projects.projects AS p
JOIN auth.users AS u
  ON u.id = p.created_by
WHERE p.organization_id = 1;
```

---

## 7. Beginner Mistakes

- joining on the wrong columns
- forgetting table aliases in multi-table queries
- using `LEFT JOIN` when `INNER JOIN` is what the business question needs
- accidentally multiplying rows because the relationship is one-to-many

Memory check:

```txt
First ask:
What row set do I want?

Then ask:
Which table relationships produce that row set?
```
