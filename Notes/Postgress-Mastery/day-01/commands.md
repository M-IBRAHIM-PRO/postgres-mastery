## List databases

```sql id="g4u7px"
\l
```

---

## Connect database

```sql id="t2x8fa"
\c teamsync
```

---

## List schemas

```sql id="r9q3vh"
\dn
```

---

## List tables

```sql id="n1w6sk"
\dt
```

---

## Describe table

```sql id="v8m4zy"
\d auth.users
```

---

## Exit

```sql id="p3t7lx"
\q
```

---

# STEP 9 — Connect Go with PostgreSQL

Inside project root:

Initialize module if not done:

```bash id="z6q2mr"
go mod init postgres-mastery
```

Install pgx:

```bash id="k5v8pa"
go get github.com/jackc/pgx/v5
```

---

# STEP 10 — Create First Go Database Connection

Create:

```txt id="u1n4xy"
cmd/main.go
```

Add:

```go id="e9r2mh"
package main

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
)

func main() {

	conn, err := pgx.Connect(
		context.Background(),
		"postgres://postgres:YOUR_PASSWORD@localhost:5432/teamsync",
	)

	if err != nil {
		panic(err)
	}

	defer conn.Close(context.Background())

	var version string

	err = conn.QueryRow(
		context.Background(),
		"SELECT version()",
	).Scan(&version)

	if err != nil {
		panic(err)
	}

	fmt.Println(version)
}
```

Replace:

```txt id="g8m3fw"
YOUR_PASSWORD
```

with your PostgreSQL password.

---

# STEP 11 — Run Go App

```bash id="y4n9vs"
go run cmd/main.go
```

Expected output:

```txt id="m2r7ck"
PostgreSQL 16...
```

---

# STEP 12 — Create architecture.md

Inside:

```txt id="a7q4pn"
architecture.md
```

Write:

```txt id="f1v8zu"
Cluster
 └── Database (teamsync)
      ├── auth schema
      │    └── users table
      │
      ├── billing schema
      ├── analytics schema
      └── audit schema
```

This is how enterprise PostgreSQL systems are commonly organized.

---

# STEP 13 — Document Learnings

Inside:

```txt id="b5w2xr"
notes.md
```

Answer:

```txt id="z4u7ks"
1. Difference between schema and database
2. What MVCC solves
3. Why PostgreSQL uses WAL
4. Why TIMESTAMPTZ matters
5. Why PostgreSQL schemas are powerful
6. Difference between PostgreSQL roles and MySQL users
```

---

# STEP 14 — Git Commit

```bash id="r8n5vm"
git add .
git commit -m "phase-01 day-01 postgres foundations"
```

---

# WHAT YOU SHOULD UNDERSTAND TODAY

If Day 1 is successful:
you should clearly understand:

```txt id="h3m8qa"
✓ PostgreSQL architecture basics
✓ Cluster vs Database vs Schema
✓ WAL basics
✓ MVCC basics
✓ PostgreSQL CLI
✓ Enterprise schema organization
✓ Go connection using pgx
✓ Basic table creation
```

---

# IMPORTANT MINDSET SHIFT

In MySQL:

```txt id="k9r1tz"
database = organizational boundary
```

In PostgreSQL:

```txt id="x7m4un"
schema = organizational boundary
```

This becomes extremely important in enterprise SaaS systems.
