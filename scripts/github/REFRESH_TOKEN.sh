#!/bin/bash
# Token refresh script

echo "Current token being used:"
echo $GITHUB_TOKEN | head -c 30
echo "..."

echo ""
echo "To use your updated token with all permissions:"
echo ""
echo "1. Close this terminal completely"
echo "2. Open a new terminal"
echo "3. Run these commands:"
echo ""
echo "   source /home/locotoki/projects/alfred-agent-platform-v2/.env.dev"
echo "   export GITHUB_TOKEN=\$GITHUB_TOKEN"
echo ""
echo "4. Then create the PR:"
echo ""
echo "   cd /home/locotoki/projects/alfred-agent-platform-v2"
echo "   gh pr create --title \"feat: ML weekly retrain scheduler\" \\"
echo "     --body \"Implements ML model retraining scheduler for issue #155\" \\"
echo "     --base feat/phase8.4-sprint5"
echo ""
echo "If that still fails, you may need to add the 'public_repo' scope to your token."
