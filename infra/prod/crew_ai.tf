# CrewAI Production Infrastructure Configuration
# This file defines the GCP resources for CrewAI production deployment

# GCP Service Account for CrewAI
resource "google_service_account" "crewai_prod_sa" {
  account_id   = "crewai-prod-sa"
  display_name = "CrewAI Production Service Account"
  description  = "Service account for CrewAI production environment"
  project      = var.project_id
}

# Grant necessary permissions to the service account
resource "google_project_iam_member" "crewai_sa_roles" {
  for_each = toset([
    "roles/logging.logWriter",     # Write logs
    "roles/monitoring.metricWriter", # Write metrics
    "roles/iam.serviceAccountTokenCreator", # Create tokens
  ])
  
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.crewai_prod_sa.email}"
}

# Workload Identity Pool for GitHub Actions
resource "google_iam_workload_identity_pool" "crewai_pool" {
  workload_identity_pool_id = "crewai-github-pool"
  display_name              = "CrewAI GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions to authenticate as CrewAI service account"
  project                   = var.project_id
}

# Workload Identity Provider for GitHub Actions
resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.crewai_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "crewai-github-provider"
  display_name                       = "CrewAI GitHub Provider"
  
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.aud"        = "assertion.aud"
  }
  
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  project = var.project_id
}

# Allow GitHub Actions to impersonate the service account
resource "google_service_account_iam_binding" "workload_identity_binding" {
  service_account_id = google_service_account.crewai_prod_sa.name
  role               = "roles/iam.workloadIdentityUser"
  
  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.crewai_pool.name}/attribute.repository/locotoki/alfred-agent-platform-v2",
  ]
}

# Outputs for GitHub Actions workflow
output "crewai_a2a_pool" {
  value = google_iam_workload_identity_pool.crewai_pool.name
  description = "Workload Identity Pool for CrewAI"
}

output "crewai_a2a_provider" {
  value = google_iam_workload_identity_pool_provider.github.name
  description = "Workload Identity Pool Provider for GitHub Actions"
}

output "crewai_client_id" {
  value = google_service_account.crewai_prod_sa.email
  description = "Service Account Email for CrewAI"
}