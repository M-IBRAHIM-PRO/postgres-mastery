include .env
export

.PHONY: run build migrate-up migrate-down migrate-force

run:
	go run ./cmd/api

build:
	go build -o bin/api ./cmd/api

migrate-up:
	./scripts/migrate.sh up

migrate-down:
	./scripts/migrate.sh down "$(STEPS)"

migrate-force:
	./scripts/migrate.sh force "$(VERSION)"
