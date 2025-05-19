# Makefile for Alfred Agent Platform v2

include .env
export $(shell sed 's/=.*//' .env)

# Docker Compose command with common options
DOCKER_COMPOSE_ALL = docker-compose -f docker-compose.combined-fixed.yml

.PHONY: help network install start stop restart clean test lint format dev deploy build update-dashboards start-all up-core up-atlas up-agents up-ui up-monitoring up-crewai-n8n logs logs-service logs-f logs-f-service ps atlas-dev atlas-down atlas-monitor atlas-index atlas-publish atlas-setup-supabase

help:
	@echo "Alfred Agent Platform v2 Makefile"
	@echo "--------------------------------"
	@echo "install              Install all dependencies"
	@echo "start                Start all services (legacy)"
	@echo "start-all            Start all services using combined config"
	@echo "up-core              Start core services (Redis, Qdrant, PubSub, Supabase)"
	@echo "up-atlas             Start Atlas services (RAG Gateway, Worker)"
	@echo "up-agents            Start agent services (Alfred Bot, Social Intel, etc.)"
	@echo "up-ui                Start UI services (Mission Control)"
	@echo "up-monitoring        Start monitoring services (Prometheus, Grafana)"
	@echo "up-crewai-n8n        Start CrewAI and n8n services"
	@echo "stop                 Stop all services"
	@echo "restart              Restart all services"
	@echo "clean                Remove all containers and volumes"
	@echo "ps                   Show all running containers"
	@echo "logs                 Show logs for all services"
	@echo "logs-service SVC=name  Show logs for a specific service"
	@echo "logs-f               Follow logs for all services"
	@echo "logs-f-service SVC=name  Follow logs for a specific service"
	@echo "test                 Run tests"
	@echo "lint                 Run linters"
	@echo "format               Format code"
	@echo "dev                  Start dev environment"
	@echo "deploy               Deploy to production"
	@echo "build                Build all services"
	@echo "update-dashboards    Reload Grafana dashboards"
	@echo ""
	@echo "Atlas commands:"
	@echo "atlas-dev            Start Atlas development stack"
	@echo "atlas-down           Stop Atlas development stack"
	@echo "atlas-monitor        Start Atlas with full monitoring (Prometheus, Grafana)"
	@echo "atlas-index DOCS_PATH=    Index documents for Atlas RAG"
	@echo "atlas-publish MSG=   Publish a task to Atlas"
	@echo "atlas-setup-supabase Set up Supabase tables for Atlas"

# Create the network if it doesn't exist
network:
	docker network create alfred-network || true

install:
	pip install -r requirements.txt
	pip install -r requirements-dev.txt

start:
	docker-compose up -d

start-all: network
	$(DOCKER_COMPOSE_ALL) up -d

# Start specific service groups
up-core: network
	$(DOCKER_COMPOSE_ALL) up -d redis qdrant pubsub-emulator supabase-db supabase-rest supabase-auth supabase-realtime

up-atlas: network
	$(DOCKER_COMPOSE_ALL) up -d rag-gateway atlas

up-agents: network
	$(DOCKER_COMPOSE_ALL) up -d alfred-bot social-intel financial-tax legal-compliance alfred-orchestrator

up-ui: network
	$(DOCKER_COMPOSE_ALL) up -d mission-control

up-monitoring: network
	$(DOCKER_COMPOSE_ALL) up -d prometheus grafana

up-crewai-n8n: network
	docker-compose -f docker-compose.yml -f docker-compose.crewai-n8n.yml up -d crewai-service workflow-n8n

stop:
	$(DOCKER_COMPOSE_ALL) down

restart:
	$(DOCKER_COMPOSE_ALL) restart

clean:
	$(DOCKER_COMPOSE_ALL) down -v --remove-orphans

ps:
	$(DOCKER_COMPOSE_ALL) ps

logs:
	$(DOCKER_COMPOSE_ALL) logs

logs-service:
	$(DOCKER_COMPOSE_ALL) logs $(SVC)

logs-f:
	$(DOCKER_COMPOSE_ALL) logs -f

logs-f-service:
	$(DOCKER_COMPOSE_ALL) logs -f $(SVC)

test:
	pytest

lint:
	flake8 .
	mypy .

format:
	black .
	isort .

dev:
	docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d

deploy:
	@echo "Deploying to production..."
	# Add deployment steps here

build:
	$(DOCKER_COMPOSE_ALL) build

update-dashboards:
	@echo "Reloading Grafana dashboards..."
	curl -X POST http://admin:admin@localhost:3005/api/admin/provisioning/dashboards/reload

# Atlas targets
atlas-dev:
	@echo "Starting Atlas development stack..."
	export $$(grep -v '^#' .env.dev | xargs) && docker-compose -f docker-compose.dev.yml up -d

atlas-down:
	@echo "Stopping Atlas development stack..."
	docker-compose -f docker-compose.dev.yml down

atlas-monitor:
	@echo "Starting Atlas with monitoring..."
	./scripts/start_atlas_with_monitoring.sh

atlas-index:
	@if [ -z "$(DOCS_PATH)" ]; then \
		echo "Error: DOCS_PATH is required. Usage: make atlas-index DOCS_PATH=/path/to/docs"; \
		exit 1; \
	fi
	@echo "Indexing documents at $(DOCS_PATH)"
	./scripts/process_docs.py "$(DOCS_PATH)"

atlas-publish:
	@if [ -z "$(MSG)" ]; then \
		echo "Error: MSG is required. Usage: make atlas-publish MSG='Design a logging ADR'"; \
		exit 1; \
	fi
	@echo "Publishing task to Atlas: $(MSG)"
	./scripts/publish_task.sh "$(MSG)"

atlas-setup-supabase:
	@echo "Setting up Supabase for Atlas..."
	./scripts/setup_supabase.sh
