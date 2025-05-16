# Makefile for Alfred Agent Platform v2

include .env
export $(shell sed 's/=.*//' .env)

.PHONY: help install start stop restart clean test test-unit test-integration test-e2e lint format dev deploy build update-dashboards setup-metrics compose-generate up down

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
	flake8 --config=.flake8 .
	mypy_fix/run-mypy-fixed.sh .
	bandit -r agents/ libs/ services/ -c pyproject.toml

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