#!/bin/bash
# safe-sync.sh - Safely sync repository with GitHub without unintended changes

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Alfred Agent Platform Safe GitHub Sync ===${NC}"
echo -e "${BLUE}This script safely synchronizes your local repository with GitHub${NC}"

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed. Please install git first.${NC}"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    echo -e "${RED}Error: Not in a git repository. Please run this script from the repository root.${NC}"
    exit 1
fi

# Check for uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo -e "${YELLOW}Warning: You have uncommitted changes.${NC}"
    echo -e "1. Commit these changes"
    echo -e "2. Discard these changes"
    echo -e "3. View changes and decide later"
    echo -e "4. Proceed anyway (not recommended)"
    read -p "Choose an option (1-4): " choice
    
    case $choice in
        1)
            echo -e "${BLUE}Committing changes...${NC}"
            git status
            read -p "Enter commit message: " commit_message
            git add .
            git commit -m "$commit_message"
            ;;
        2)
            echo -e "${YELLOW}Discarding changes...${NC}"
            git reset --hard HEAD
            ;;
        3)
            echo -e "${BLUE}Current changes:${NC}"
            git status
            git diff
            echo -e "${YELLOW}Please handle these changes before syncing. Exiting.${NC}"
            exit 0
            ;;
        4)
            echo -e "${YELLOW}Proceeding with uncommitted changes...${NC}"
            ;;
        *)
            echo -e "${RED}Invalid option. Exiting.${NC}"
            exit 1
            ;;
    esac
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${BLUE}Current branch: ${CURRENT_BRANCH}${NC}"

# Verify remote
echo -e "${BLUE}Verifying remote connections...${NC}"
git remote -v

# Fetch updates without merging
echo -e "${BLUE}Fetching updates from remote...${NC}"
git fetch

# Check if local branch is behind remote
BEHIND=$(git rev-list --count HEAD..origin/$CURRENT_BRANCH 2>/dev/null)
if [ -z "$BEHIND" ]; then
    BEHIND=0
fi

# Check if local branch is ahead of remote
AHEAD=$(git rev-list --count origin/$CURRENT_BRANCH..HEAD 2>/dev/null)
if [ -z "$AHEAD" ]; then
    AHEAD=0
fi

echo -e "${BLUE}Branch status: ${AHEAD} commits ahead, ${BEHIND} commits behind origin/${CURRENT_BRANCH}${NC}"

# If local is behind remote
if [ $BEHIND -gt 0 ]; then
    echo -e "${YELLOW}Your branch is behind the remote branch.${NC}"
    echo -e "1. Pull changes (merge)"
    echo -e "2. Pull changes (rebase)"
    echo -e "3. View what would change and decide later"
    echo -e "4. Skip pulling changes"
    read -p "Choose an option (1-4): " pull_choice
    
    case $pull_choice in
        1)
            echo -e "${BLUE}Pulling changes with merge...${NC}"
            git pull
            ;;
        2)
            echo -e "${BLUE}Pulling changes with rebase...${NC}"
            git pull --rebase
            ;;
        3)
            echo -e "${BLUE}Changes that would be pulled:${NC}"
            git log HEAD..origin/$CURRENT_BRANCH --oneline
            echo -e "${YELLOW}Please run git pull manually when ready. Exiting.${NC}"
            exit 0
            ;;
        4)
            echo -e "${YELLOW}Skipping pull...${NC}"
            ;;
        *)
            echo -e "${RED}Invalid option. Exiting.${NC}"
            exit 1
            ;;
    esac
fi

# If local is ahead of remote
if [ $AHEAD -gt 0 ]; then
    echo -e "${YELLOW}Your branch is ahead of the remote branch by ${AHEAD} commits.${NC}"
    echo -e "1. Push changes to remote"
    echo -e "2. View commits to be pushed"
    echo -e "3. Skip pushing changes"
    read -p "Choose an option (1-3): " push_choice
    
    case $push_choice in
        1)
            echo -e "${BLUE}Pushing changes to remote...${NC}"
            git push
            ;;
        2)
            echo -e "${BLUE}Commits that would be pushed:${NC}"
            git log origin/$CURRENT_BRANCH..HEAD --oneline
            echo -e "${YELLOW}Please run git push manually when ready. Exiting.${NC}"
            exit 0
            ;;
        3)
            echo -e "${YELLOW}Skipping push...${NC}"
            ;;
        *)
            echo -e "${RED}Invalid option. Exiting.${NC}"
            exit 1
            ;;
    esac
fi

# Clean up
echo -e "${BLUE}Checking for untracked and ignored files...${NC}"
git clean -fxdn

echo -e "${YELLOW}Would you like to clean these files? (y/n)${NC}"
read -p "Choice: " clean_choice

if [[ $clean_choice == "y" || $clean_choice == "Y" ]]; then
    echo -e "${BLUE}Cleaning untracked and ignored files...${NC}"
    git clean -fxd
    echo -e "${GREEN}Cleanup complete.${NC}"
else
    echo -e "${YELLOW}Skipping cleanup.${NC}"
fi

echo -e "${GREEN}Repository sync process complete!${NC}"
echo -e "${BLUE}Final repository status:${NC}"
git status

exit 0