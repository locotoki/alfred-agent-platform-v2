# Post-Rollout Action Tracker (Social-Intel v1.0.0)

| #  | Task | Owner | Cadence / Trigger | How to Complete |
|----|------|-------|-------------------|-----------------|
| 1  | Nudge Social-Intel about param-aware scorer (SI-243) | locotoki | Weekly every Monday until ticket closed | Send Slack / email, add note to this doc, or close GitHub issue #si-243-follow-up. |
| 2  | Delete client-side Levenshtein transform + related tests | locotoki | When SI ships param-aware scorer (ticket resolved) | Remove code, push PR, make sure CI passes, tick here. |
| 3  | Rotate ADMIN_TOKEN & SI_API_KEY | locotoki | Quarterly (Jan 1, Apr 1, Jul 1, Oct 1) | Generate new secrets, update .env & GitHub secrets, restart services. |

## Tips
- Add a GitHub Issue linking back to each row here for reminders.
- For secret rotation, run scripts/rotate_secrets.sh (to be created).
- Remember to update Prometheus alert receivers if tokens change.