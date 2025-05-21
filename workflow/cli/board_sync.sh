#!/bin/bash
set -euo pipefail

# Board Sync Automation Script
# Moves linked GitHub issues to "Done" column after PR merge
# Usage: ./board_sync.sh <ISSUE_URL_OR_NUMBER> [--dry-run]

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly OWNER="locotoki"
readonly REPO="alfred-agent-platform-v2"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Global variables
DRY_RUN=false
VERBOSE=false
ISSUE_NUMBER=""
PROJECT_ID=""
ITEM_ID=""
DONE_COLUMN_ID=""

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_debug() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $*"
    fi
}

# Usage function
usage() {
    cat << EOF
Usage: $SCRIPT_NAME <ISSUE_URL_OR_NUMBER> [OPTIONS]

Move GitHub issue to "Done" column in project board after PR merge.

Arguments:
  ISSUE_URL_OR_NUMBER    GitHub issue URL or issue number

Options:
  --dry-run             Show what would be done without making changes
  --verbose             Enable debug output
  -h, --help           Show this help message

Examples:
  $SCRIPT_NAME 174
  $SCRIPT_NAME https://github.com/locotoki/alfred-agent-platform-v2/issues/174
  $SCRIPT_NAME 174 --dry-run
  $SCRIPT_NAME 174 --verbose

Environment Variables:
  GITHUB_TOKEN         GitHub token with repo and project permissions
  DRY_RUN              Set to 'true' to enable dry-run mode

EOF
}

# Parse command line arguments
parse_args() {
    # Check for help first
    for arg in "$@"; do
        if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
            usage
            exit 0
        fi
    done

    if [[ $# -eq 0 ]]; then
        log_error "Missing required argument: ISSUE_URL_OR_NUMBER"
        usage
        exit 1
    fi

    local issue_input=""
    local found_issue=false

    # Parse all arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                log_info "Dry-run mode enabled"
                shift
                ;;
            --verbose)
                VERBOSE=true
                log_debug "Verbose mode enabled"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [[ "$found_issue" == "false" ]]; then
                    issue_input="$1"
                    found_issue=true
                else
                    log_error "Multiple issue arguments provided: '$issue_input' and '$1'"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    if [[ "$found_issue" == "false" ]]; then
        log_error "Missing required argument: ISSUE_URL_OR_NUMBER"
        usage
        exit 1
    fi

    # Extract issue number from URL or use directly if it's a number
    if [[ "$issue_input" =~ ^https://github.com/.*/issues/([0-9]+) ]]; then
        ISSUE_NUMBER="${BASH_REMATCH[1]}"
        log_debug "Extracted issue number $ISSUE_NUMBER from URL"
    elif [[ "$issue_input" =~ ^[0-9]+$ ]]; then
        ISSUE_NUMBER="$issue_input"
        log_debug "Using issue number $ISSUE_NUMBER directly"
    else
        log_error "Invalid issue format: $issue_input"
        log_error "Expected: issue number (e.g., 174) or GitHub issue URL"
        exit 1
    fi

    # Check environment variables
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        DRY_RUN=true
        log_info "Dry-run mode enabled via environment variable"
    fi
}

# Check prerequisites
check_prerequisites() {
    log_debug "Checking prerequisites..."

    # Check if gh CLI is available
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed or not in PATH"
        exit 1
    fi

    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI is not authenticated"
        log_error "Run: gh auth login"
        exit 1
    fi

    # Check token permissions
    local scopes
    if ! scopes=$(gh auth status 2>&1 | grep -oE "Token scopes: .*"); then
        log_warn "Could not verify token scopes"
    else
        log_debug "$scopes"
        if [[ ! "$scopes" =~ read:project ]] && [[ ! "$scopes" =~ project ]]; then
            log_warn "Token may be missing project permissions"
            log_warn "If this fails, run: gh auth refresh -s read:project"
        fi
    fi

    log_debug "Prerequisites check completed"
}

# Find the issue and validate it exists
validate_issue() {
    log_debug "Validating issue #$ISSUE_NUMBER..."

    if ! gh issue view "$ISSUE_NUMBER" --repo "$OWNER/$REPO" &> /dev/null; then
        log_error "Issue #$ISSUE_NUMBER not found in $OWNER/$REPO"
        exit 1
    fi

    local issue_state
    issue_state=$(gh issue view "$ISSUE_NUMBER" --repo "$OWNER/$REPO" --json state --jq '.state')

    if [[ "$issue_state" == "CLOSED" ]]; then
        log_success "Issue #$ISSUE_NUMBER is already closed"
    else
        log_info "Issue #$ISSUE_NUMBER is open (state: $issue_state)"
    fi

    log_debug "Issue validation completed"
}

# Find project boards and the target project
find_project() {
    log_debug "Finding project board..."

    # List projects and find the one containing our issue
    local projects_json
    if ! projects_json=$(gh project list --owner "$OWNER" --format json 2>/dev/null); then
        log_error "Failed to list projects. Missing project permissions?"
        log_error "Try: gh auth refresh -s read:project"
        exit 1
    fi

    # Look for common project names first
    local project_candidates=("Alfred-core Sprint Board" "Sprint" "Alfred Platform" "Main")

    for candidate in "${project_candidates[@]}"; do
        PROJECT_ID=$(echo "$projects_json" | jq -r ".[] | select(.title == \"$candidate\") | .number" | head -1)
        if [[ -n "$PROJECT_ID" && "$PROJECT_ID" != "null" ]]; then
            log_info "Found project: '$candidate' (ID: $PROJECT_ID)"
            break
        fi
    done

    # If no common name found, use the first project
    if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "null" ]]; then
        PROJECT_ID=$(echo "$projects_json" | jq -r '.[0].number')
        local project_title=$(echo "$projects_json" | jq -r '.[0].title')

        if [[ -n "$PROJECT_ID" && "$PROJECT_ID" != "null" ]]; then
            log_warn "Using first available project: '$project_title' (ID: $PROJECT_ID)"
        else
            log_error "No projects found for $OWNER"
            exit 1
        fi
    fi

    log_debug "Project discovery completed"
}

# Find the issue in the project board
find_issue_in_project() {
    log_debug "Looking for issue #$ISSUE_NUMBER in project $PROJECT_ID..."

    local items_json
    if ! items_json=$(gh project item-list "$PROJECT_ID" --owner "$OWNER" --format json 2>/dev/null); then
        log_error "Failed to list project items for project $PROJECT_ID"
        exit 1
    fi

    # Find the issue in the project
    ITEM_ID=$(echo "$items_json" | jq -r ".[] | select(.content.number == $ISSUE_NUMBER and .content.type == \"Issue\") | .id" | head -1)

    if [[ -z "$ITEM_ID" || "$ITEM_ID" == "null" ]]; then
        log_warn "Issue #$ISSUE_NUMBER not found in project $PROJECT_ID"
        log_info "Issue may not be linked to the project board"
        return 1
    fi

    local current_status=$(echo "$items_json" | jq -r ".[] | select(.id == \"$ITEM_ID\") | .status")
    log_info "Found issue #$ISSUE_NUMBER in project (Item ID: $ITEM_ID, Status: $current_status)"

    # Check if already in Done
    if [[ "$current_status" =~ ^[Dd]one$ ]] || [[ "$current_status" =~ ^[Cc]omplete ]]; then
        log_success "Issue #$ISSUE_NUMBER is already in Done status: $current_status"
        return 2
    fi

    log_debug "Issue found in project and not in Done status"
    return 0
}

# Find the "Done" column ID
find_done_column() {
    log_debug "Finding Done column in project $PROJECT_ID..."

    local fields_json
    if ! fields_json=$(gh project field-list "$PROJECT_ID" --owner "$OWNER" --format json 2>/dev/null); then
        log_error "Failed to get project fields for project $PROJECT_ID"
        exit 1
    fi

    # Look for Status field
    local status_field_id
    status_field_id=$(echo "$fields_json" | jq -r '.[] | select(.name == "Status") | .id' | head -1)

    if [[ -z "$status_field_id" || "$status_field_id" == "null" ]]; then
        log_error "Could not find Status field in project $PROJECT_ID"
        exit 1
    fi

    # Get field options to find Done option
    local field_options
    if ! field_options=$(gh api "graphql" -f query="
        query {
            node(id: \"$status_field_id\") {
                ... on ProjectV2SingleSelectField {
                    options {
                        id
                        name
                    }
                }
            }
        }
    " 2>/dev/null); then
        log_error "Failed to get Status field options"
        exit 1
    fi

    # Find Done option (case-insensitive)
    DONE_COLUMN_ID=$(echo "$field_options" | jq -r '.data.node.options[] | select(.name | test("^[Dd]one$|^[Cc]omplete")) | .id' | head -1)

    if [[ -z "$DONE_COLUMN_ID" || "$DONE_COLUMN_ID" == "null" ]]; then
        log_error "Could not find 'Done' status option in project $PROJECT_ID"
        log_info "Available status options:"
        echo "$field_options" | jq -r '.data.node.options[] | "  - \(.name)"'
        exit 1
    fi

    local done_name=$(echo "$field_options" | jq -r ".data.node.options[] | select(.id == \"$DONE_COLUMN_ID\") | .name")
    log_info "Found Done status: '$done_name' (ID: $DONE_COLUMN_ID)"

    log_debug "Done column discovery completed"
}

# Move the issue to Done
move_to_done() {
    log_info "Moving issue #$ISSUE_NUMBER to Done status..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "[DRY RUN] Would move issue #$ISSUE_NUMBER (Item ID: $ITEM_ID) to Done (Column ID: $DONE_COLUMN_ID)"
        return 0
    fi

    # Use GitHub CLI to update the project item
    if gh project item-edit --project-id "$PROJECT_ID" --id "$ITEM_ID" --field-id Status --single-select-option-id "$DONE_COLUMN_ID" --owner "$OWNER" &> /dev/null; then
        log_success "Successfully moved issue #$ISSUE_NUMBER to Done status"
    else
        log_error "Failed to move issue #$ISSUE_NUMBER to Done status"
        exit 1
    fi
}

# Main execution function
main() {
    log_info "Starting board sync for issue #$ISSUE_NUMBER..."

    check_prerequisites
    validate_issue
    find_project

    # Try to find and move the issue
    local find_result
    set +e  # Temporarily disable exit on error
    find_issue_in_project
    find_result=$?
    set -e  # Re-enable exit on error

    case $find_result in
        0)
            # Issue found and not in Done
            find_done_column
            move_to_done
            ;;
        1)
            # Issue not found in project
            log_warn "Board sync skipped - issue not in project board"
            exit 0
            ;;
        2)
            # Issue already in Done
            log_success "Board sync not needed - issue already completed"
            exit 0
            ;;
    esac

    log_success "Board sync completed successfully!"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_args "$@"
    main
fi
