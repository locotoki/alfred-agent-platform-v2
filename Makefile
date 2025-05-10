# Makefile for Alfred Agent Platform v2

include .env
export $(shell sed 's/=.*//' .env)

.PHONY: help install start stop restart clean test lint format dev deploy build update-dashboards

help:
	@echo "Alfred Agent Platform v2 Makefile"
	@echo "--------------------------------"
	@echo "install              Install all dependencies"
	@echo "start                Start all services"
	@echo "stop                 Stop all services"
	@echo "restart              Restart all services"
	@echo "clean                Remove all containers and volumes"
	@echo "test                 Run tests"
	@echo "lint                 Run linters"
	@echo "format               Format code"
	@echo "dev                  Start dev environment"
	@echo "deploy               Deploy to production"
	@echo "build                Build all services"
	@echo "update-dashboards    Reload Grafana dashboards"

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
	docker-compose build

update-dashboards:
	@echo "Reloading Grafana dashboards..."
	curl -X POST http://admin:admin@localhost:3002/api/admin/provisioning/dashboards/reload