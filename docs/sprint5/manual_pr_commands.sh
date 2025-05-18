#!/bin/bash
# Manual PR and Issue Update Commands

echo "==================="
echo "Manual GitHub Commands"
echo "==================="
echo ""
echo "1. Create Pull Request:"
echo "----------------------"
echo "gh pr create --title \"feat: ML weekly retrain scheduler\" --body-file /tmp/pr_body_simple.md --base feat/phase8.4-sprint5"
echo ""
echo "OR use web interface:"
echo "https://github.com/locotoki/alfred-agent-platform-v2/pull/new/feat/ml-pipeline"
echo ""
echo "2. Update Issue #155:"
echo "--------------------"
echo "gh issue comment 155 --body '🚀 Started implementation

- Created branch feat/ml-pipeline
- Implemented ML retrain scheduler
- Added comprehensive tests
- PR opened for review'"
echo ""
echo "3. Add Kickoff Meeting to Issue #159:"
echo "------------------------------------"
echo "gh issue comment 159 --body '## Sprint-5 Kick-off Meeting Agenda

**Date:** Wed 26 Jun 15:00 CEST
**Zoom Link:** https://zoom.us/j/123456789

### Agenda Items:
1. Sprint-5 goals review
2. Task assignments
3. Dependencies check (HuggingFace, Ray, Grafana)
4. Success metrics alignment
5. Q&A

### Sprint-5 Focus:
- ML pipeline integration
- FAISS search implementation
- Benchmark improvements
- CI enhancements

Please confirm your attendance below.'"
echo ""
echo "All commands require proper GitHub permissions (repo, write:discussion, public_repo)"
