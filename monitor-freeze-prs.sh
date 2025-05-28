#!/usr/bin/env bash
# monitor-freeze-prs.sh - Check PRs 544 and 545 until merged
set -euo pipefail

REPO="Digital-Native-Ventures/alfred-agent-platform-v2"
PRS=(544 545)
POLL=120  # 2 minutes

echo "🔍 Monitoring PRs #544 and #545 for merge status..."
echo "   Will check every 2 minutes until both are merged."
echo ""

while true; do
    all_merged=true
    
    for pr in "${PRS[@]}"; do
        state=$(gh pr view "$pr" --repo "$REPO" --json state -q .state 2>/dev/null || echo "ERROR")
        
        if [[ "$state" != "MERGED" ]]; then
            all_merged=false
            queue_status=$(gh pr view "$pr" --repo "$REPO" --json mergeStateStatus -q .mergeStateStatus 2>/dev/null || echo "UNKNOWN")
            printf "⏳ %s - PR #%-3s: %-6s (queue: %s)\n" "$(date '+%H:%M:%S')" "$pr" "$state" "$queue_status"
        else
            printf "✅ %s - PR #%-3s: MERGED\n" "$(date '+%H:%M:%S')" "$pr"
        fi
    done
    
    if [[ "$all_merged" == "true" ]]; then
        echo ""
        echo "🎉 Both PRs are now MERGED!"
        echo "✅ Stability Freeze infrastructure is complete."
        echo "📅 Ready to start freeze-week communications!"
        exit 0
    fi
    
    echo ""
    sleep $POLL
done