package main

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
)

func main() {

	conn, err := pgx.Connect(
		context.Background(),
		"postgres://ibrahim:123456@localhost:5432/teamsync",
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