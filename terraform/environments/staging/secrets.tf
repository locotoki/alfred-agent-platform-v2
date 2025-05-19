# Feature flags for staging environment

module "staging_secrets" {
  source = "../../modules/secrets"

  environment = "staging"

  secrets = {
    # Alert grouping feature flag
    ALERT_GROUPING_ENABLED = "true"

    # Other existing secrets
    SLACK_BOT_TOKEN        = var.slack_bot_token
    SLACK_APP_TOKEN        = var.slack_app_token
    DATABASE_URL           = var.database_url
  }
}

# GitHub environment secrets
resource "github_actions_environment_secret" "alert_grouping_flag" {
  repository      = "alfred-agent-platform-v2"
  environment     = "staging"
  secret_name     = "ALERT_GROUPING_ENABLED"
  encrypted_value = "true"
}
