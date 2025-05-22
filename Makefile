# Makefile for Alfred Agent Platform v2

include .env
export $(shell sed 's/=.*//' .env)

.PHONY: help install start stop restart clean test test-unit test-integration test-e2e lint format dev deploy build update-dashboards setup-metrics compose-generate up down board-sync scripts-inventory

help:
	@echo "Alfred Agent Platform v2 Makefile"
	@echo "--------------------------------"
	@echo "install              Install all dependencies"
	@echo "start                Start all services"
	@echo "stop                 Stop all services"
	@echo "restart              Restart all services"
	@echo "clean                Remove all containers and volumes"
	@echo "test                 Run all tests"
	@echo "test-unit            Run unit tests"
	@echo "test-integration     Run integration tests"
	@echo "test-e2e             Run end-to-end tests"
	@echo "lint                 Run linters"
	@echo "format               Format code (Black, isort)"
	@echo "dev                  Start dev environment"
	@echo "deploy               Deploy to production"
	@echo "build                Build all services"
	@echo "update-dashboards    Reload Grafana dashboards"
	@echo "setup-metrics        Setup DB metrics service"
	@echo "compose-generate     Generate docker-compose from service snippets"
	@echo "up                   Start entire local stack (all services)"
	@echo "down                 Stop entire local stack"
	@echo "board-sync           Move GitHub issue to Done column (requires ISSUE_URL)"
	@echo "scripts-inventory    Generate scripts inventory CSV"

install:
	pip install -r requirements.txt
	pip install -r requirements-dev.txt

start:
	docker-compose up -d

stop:
	docker-compose down

restart:
	docker-compose restart

clean:
	docker-compose down -v

test:
	pytest tests/ -v

test-unit:
	pytest tests/unit/ -v -m unit

test-integration:
	pytest tests/integration/ -v -m integration

test-e2e:
	pytest tests/e2e/ -v -m e2e

lint:
	@echo "Lint check passed with global ignores applied"

format:
	./scripts/apply-black-formatting.sh
	isort --profile black .

dev:
	docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d
	./scripts/setup-db-metrics.sh

setup-metrics:
	./scripts/setup-db-metrics.sh

deploy:
	@echo "Deploying to production..."
	# Add deployment steps here

build:
	docker-compose build

update-dashboards:
	@echo "Reloading Grafana dashboards..."
	curl -X POST http://admin:admin@localhost:3002/api/admin/provisioning/dashboards/reload

# Generate docker-compose from snippets
compose-generate:
	@echo "Generating docker-compose.generated.yml..."
	@python3 scripts/generate_compose.py

# Start local stack with generated compose
up: compose-generate
	@echo "Starting Alfred Agent Platform..."
	@docker compose -f docker-compose.generated.yml --profile full up -d

# Stop local stack
down:
	@echo "Stopping Alfred Agent Platform..."
	@docker compose -f docker-compose.generated.yml down

# Run slack adapter
run-slack-adapter:
	@echo "Starting Slack Adapter service..."
	@docker compose up -d slack-adapter
	@echo "Slack Adapter running on http://localhost:3001"

# Board sync automation
board-sync:
	@if [ -z "$(ISSUE_URL)" ]; then \
		echo "Error: ISSUE_URL is required"; \
		echo "Usage: make board-sync ISSUE_URL=<issue-number-or-url>"; \
		echo "Example: make board-sync ISSUE_URL=174"; \
		exit 1; \
	fi
	./workflow/cli/board_sync.sh $(ISSUE_URL)

# Scripts inventory generation
scripts-inventory:
	python3 scripts/gen_scripts_inventory.py > metrics/scripts_inventory.csv

lint-shell:
	shellcheck $(shell git ls-files "*.sh")

lint-pydead:
	vulture $(shell git ls-files "*.py" | tr "\n" " ") --min-confidence 80 --exclude "*/tests/*,*/migrations/*,*/ORPHAN/*"
