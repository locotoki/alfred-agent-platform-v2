.PHONY: phase0
phase0:
	docker-compose -f docker-compose-clean.yml build
	./start-platform.sh -a start -e dev
	sleep 120
	./scripts/verify-service-health.sh
	./scripts/validate-monitoring.sh        # <-- new
	./start-platform.sh -a stop -e dev