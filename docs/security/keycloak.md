# Keycloak Hardening

* **TLS everywhere** – ingress terminated with cert-manager.
* **Admin console disabled** – set `KC_SPI_CONSOLE_ENABLED=false`.
* **Realm bootstrap** – secured secret-based export job.
* **Health probes** – `/health/ready` on port 8080.

Update secrets and hostname per environment.
