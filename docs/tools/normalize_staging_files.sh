#!/bin/bash
# Normalize filenames in the staging-area directory
# This script provides an easy way to run the normalize_filenames.py script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="${SCRIPT_DIR}/normalize_filenames.py"
STAGING_DIR="/home/locotoki/projects/alfred-agent-platform-v2/docs/staging-area"
MAPPING_FILE="${SCRIPT_DIR}/outputs/filename_mapping_$(date +%Y%m%d_%H%M%S).csv"

# Create outputs directory if it doesn't exist
mkdir -p "${SCRIPT_DIR}/outputs"

# Make sure the script is executable
chmod +x "${PYTHON_SCRIPT}"

# Function to display help
function show_help {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --dry-run           Show what would be done without actually renaming files"
    echo "  --directory=DIR     Specify a different staging directory"
    echo "  --mapping=FILE      Specify a different mapping file"
    echo "  --keep-zone-files   Don't remove .Zone.Identifier files"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  Run the script with default options"
    echo "  $0 --dry-run        Show what would be done without making changes"
    echo ""
}

# Parse command line arguments
DRY_RUN=""
ZONE_OPTION=""

for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN="--dry-run"
            shift
            ;;
        --directory=*)
            STAGING_DIR="${arg#*=}"
            shift
            ;;
        --mapping=*)
            MAPPING_FILE="${arg#*=}"
            shift
            ;;
        --keep-zone-files)
            ZONE_OPTION="--no-remove-zone-identifier"
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            show_help
            exit 1
            ;;
    esac
done

echo "Starting filename normalization..."
echo "Staging directory: ${STAGING_DIR}"
echo "Mapping file: ${MAPPING_FILE}"
echo ""

COMMAND_OPTIONS="--staging-dir=\"${STAGING_DIR}\" --output-mapping=\"${MAPPING_FILE}\""
if [ -n "$ZONE_OPTION" ]; then
    COMMAND_OPTIONS="${COMMAND_OPTIONS} ${ZONE_OPTION}"
fi
if [ -n "$DRY_RUN" ]; then
    COMMAND_OPTIONS="${COMMAND_OPTIONS} ${DRY_RUN}"
fi

# Run the Python script
if [ -n "$DRY_RUN" ]; then
    echo "DRY RUN MODE: No files will be modified"
    python3 "${PYTHON_SCRIPT}" --staging-dir="${STAGING_DIR}" --output-mapping="${MAPPING_FILE}" ${ZONE_OPTION} --dry-run
else
    echo "Normalizing filenames..."
    python3 "${PYTHON_SCRIPT}" --staging-dir="${STAGING_DIR}" --output-mapping="${MAPPING_FILE}" ${ZONE_OPTION}

    # Make a backup of the mapping file
    cp "${MAPPING_FILE}" "${SCRIPT_DIR}/outputs/latest_filename_mapping.csv"
    echo "Latest mapping file also saved to ${SCRIPT_DIR}/outputs/latest_filename_mapping.csv"
fi

echo ""
echo "Done!"
