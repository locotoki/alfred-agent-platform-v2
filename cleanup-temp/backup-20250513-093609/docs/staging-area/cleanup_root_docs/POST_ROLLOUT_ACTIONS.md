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

## Deprecation Notice

> 🚨 **IMPORTANT**: The client-side Levenshtein transformation in the Social-Intel proxy will be removed once the upstream service (SI) ships its parameter-aware scorer.

### Transformation Logic to be Removed:

The following components will be deleted after SI-243 is resolved:

1. **File**: `/services/mission-control/src/pages/api/social-intel/proxy-helper.ts`
   - `applyLevenshteinTransformation()` function
   - Associated tests in `/tests/unit/proxy-helper.test.ts`

2. **File**: `/services/mission-control-simplified/integrate-with-social-intel.js`
   - `transformResults()` function at line ~120
   - The related filtering logic in the `/niche-scout` handler

3. **Pull Request**: Create a PR with the following title and branch after upstream fix is deployed:
   ```
   fix: remove client-side Levenshtein transform (SI-243 resolved)
   ```
   Branch: `remove-levenshtein-transform`

### Verification Steps:

Before removing the transformation:
1. Confirm with SI team that parameter-aware scoring is live
2. Verify API returns properly filtered results for the same query/category
3. Run side-by-side comparison to ensure result quality is identical or better
4. Update documentation to reflect the removal of this workaround