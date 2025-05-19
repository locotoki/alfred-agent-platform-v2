# YouTube Workflow Implementation Template for Claude Sessions

## Instructions for Future Claude Sessions

When working on the YouTube workflows implementation in the Alfred Agent Platform v2, please follow these steps at the beginning of each session:

1. **Check the environment** using the automated script:
   ```bash
   cd /home/locotoki/projects/alfred-agent-platform-v2/docs/phase6-mission-control/youtube-workflows
   chmod +x environment-check-script.sh
   ./environment-check-script.sh
   ```

2. **Review key documentation** located in:
   - Quick Start Guide: `/docs/phase6-mission-control/youtube-workflows/quick-start-guide.md`
   - Implementation Plan: `/docs/phase6-mission-control/youtube-workflows/implementation-plan.md`
   - Troubleshooting Guide: `/docs/phase6-mission-control/youtube-workflows/troubleshooting-guide.md`

3. **Follow implementation steps** from the Implementation Plan document

4. **Use the Troubleshooting Guide** if any issues are encountered

5. **Update documentation** after completing any significant changes

These documents should be treated as living references and updated as the implementation progresses.

## Claude Prompt Template

Copy and paste the below snippet into Claude's project instructions area to ensure proper execution on every session:

```
When working on the YouTube workflows integration for the Alfred Agent Platform v2:

1. Always begin by running the environment check script:
   /home/locotoki/projects/alfred-agent-platform-v2/docs/phase6-mission-control/youtube-workflows/environment-check-script.sh

2. Consult the documentation in /docs/phase6-mission-control/youtube-workflows/ before making changes:
   - quick-start-guide.md - For rapid overview
   - implementation-plan.md - For specific tasks and code changes
   - troubleshooting-guide.md - For solving common issues

3. Treat these documents as living references that should be updated as the implementation progresses.

4. After completing any significant changes, update the documentation and implementation_status_final.md to reflect the current state.

5. Focus on the key issues:
   - Port configuration (3005 for UI, 9000 for Social Intelligence Agent)
   - Dynamic URL handling in API services
   - Robust error handling and fallbacks
   - User-friendly feedback during API operations

6. Always test changes with both workflows (Niche-Scout and Seed-to-Blueprint) before considering implementation complete.
```

This structured approach ensures consistent work across multiple Claude sessions, reducing ramp-up time and preventing repeated environment assessment.
