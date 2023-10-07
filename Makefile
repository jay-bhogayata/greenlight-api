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
git_description = $(shell git describe --always --dirty --tags --long)
linker_flags = '-s -X main.buildTime=${current_time} -X main.version=${git_description}'

## build/api: build the cmd/api application
.PHONY: build/api
build/api:
	@echo 'Building cmd/api...'
	go build -ldflags=${linker_flags} -o=./bin/api ./cmd/api ;
	GOOS=linux GOARCH=amd64 go build -ldflags=${linker_flags} -o=./bin/linux_amd64/api ./cmd/api ;

# ==================================================================================== #
# PRODUCTION
# ==================================================================================== #

production_host_ip = '143.244.138.222'

## production/connect: connect to the production server
.PHONY: production/connect
production/connect:
	ssh -i ~/.ssh/id_rsa_greenlight  greenlight@${production_host_ip}

## production/deploy/api: deploy the api to production
.PHONY: production/deploy/api
production/deploy/api:
	rsync -P ./bin/linux_amd64/api -i ~/.ssh/id_rsa_greenlight greenlight@${production_host_ip}:~
	
	rsync -rP --delete ./migrations -i ~/.ssh/id_rsa_greenlight greenlight@${production_host_ip}:~
	
	rsync -P ./remote/production/api.service -i ~/.ssh/id_rsa_greenlight  greenlight@${production_host_ip}:~

	rsync -P ./remote/production/Caddyfile -i ~/.ssh/id_rsa_greenlight  greenlight@${production_host_ip}:~


	ssh -t -i ~/.ssh/id_rsa_greenlight greenlight@${production_host_ip}  ' migrate -path ~/migrations -database $$GREENLIGHT_DB_DSN up &&  sudo mv ~/api.service /etc/systemd/system/ && sudo systemctl enable api && sudo systemctl restart api && sudo mv ~/Caddyfile /etc/caddy && sudo systemctl restart caddy ' 
	
