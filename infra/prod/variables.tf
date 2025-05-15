# Variables for CrewAI Production Infrastructure
# These variables are used in the crew_ai.tf configuration

variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
  default     = "alfred-agent-platform-prod"  # Replace with your actual project ID
}

variable "region" {
  description = "The GCP region where resources will be created"
  type        = string
  default     = "us-central1"  # Replace with your preferred region
}

variable "github_repo" {
  description = "The GitHub repository name"
  type        = string
  default     = "locotoki/alfred-agent-platform-v2"
}