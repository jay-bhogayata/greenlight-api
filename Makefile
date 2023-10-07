include .env

# ==================================================================================== #
# HELPERS# ==================================================================================== #

## help: print this help message
.PHONY: help
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |sed -e 's/^/ /'

## confirm: confirm the action
.PHONY: confirm
confirm:
	@echo -n 'Are you sure? [y/N] ' && read ans && [ $${ans:-N} = y ]

# ==================================================================================== #
# DEVELOPMENT # ==================================================================================== #

## run/api: run the cmd/api application
.PHONY: run/api
run/api:
	go run ./cmd/api -db-dsn=${GREENLIGHT_DB_DSN} ;

## db/psql: connect to the database using psql
.PHONY: db/psql
db/psql:
	psql ${GREENLIGHT_DB_DSN}

## db/migrations/new name=$1: create a new database migration
.PHONY: db/migration/new
db/migration/new:
	@echo "creating migration file for ${name}"
	migrate create -seq -ext=.sql -dir=./migrations ${name}

## db/migrations/up: apply all up database migrations
.PHONY: db/migration/up
db/migration/up: confirm
	@echo "running Up migrations"
	migrate -path ./migrations -database ${GREENLIGHT_DB_DSN} up


# ==================================================================================== #
# QUALITY CONTROL
# ==================================================================================== #

## audit: tidy dependencies and format code , vet and test all code
.PHONY: audit
audit:
	@echo	"formatting code"
	go fmt ./... ;
	@echo "vetting code"
	go vet ./... ;
	staticcheck ./... ;
	@echo "running tests"
	go test -race -vet=off ./... ;

## vendor: tidy and vendor dependencies
.PHONY: vendor
vendor:
	@echo "tidying and vendoring dependencies"
	go mod tidy ;
	go mod verify ;
	@echo "vendoring dependencies"
	go mod vendor ;

# ==================================================================================== #
# BUILD
# ==================================================================================== #

current_time = $(shell date --iso-8601=seconds)
git_description = $(shell git describe --always --dirty)
linker_flags = '-s -X main.buildTime=${current_time}'

## build/api: build the cmd/api application
.PHONY: build/api
build/api:
	@echo 'Building cmd/api...'
	go build -ldflags=${linker_flags} -o=./bin/api ./cmd/api ;
	GOOS=linux GOARCH=amd64 go build -ldflags=${linker_flags} -o=./bin/linux_amd64/api ./cmd/api ;