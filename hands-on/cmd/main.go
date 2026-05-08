package main

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	handson "postgres-mastery"
)

func main() {
	ctx := context.Background()

	cfg, err := handson.LoadConfig()
	if err != nil {
		panic(err)
	}

	conn, err := pgx.Connect(ctx, cfg.DatabaseURL())
	if err != nil {
		panic(err)
	}

	defer conn.Close(ctx)

	var version string

	err = conn.QueryRow(
		ctx,
		"SELECT version()",
	).Scan(&version)

	if err != nil {
		panic(err)
	}

	fmt.Println(version)
}
