package main

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	handson "postgres-mastery"
	"postgres-mastery/internal/users"
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

	userRepo := users.NewRepository(conn)

	user, err := userRepo.FindByEmail(ctx, "ibrahim@teamsync.dev")
	if err != nil {
		panic(err)
	}

	members, err := userRepo.ListOrganizationMembers(ctx, 1)
	if err != nil {
		panic(err)
	}

	fmt.Printf("Found user: %s (%s)\n", user.FullName, user.Email)
	fmt.Println("Organization 1 members:")
	for _, member := range members {
		fmt.Printf("- %s <%s> role=%s\n", member.FullName, member.Email, member.Role)
	}
}
