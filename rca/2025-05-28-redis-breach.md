# 2025-05-28 · Redis replica compromise

| Item | Detail |
| --- | --- |
| **Detected** | 2025-05-28 07:15 UTC (Redis replica to 120.53.222.226) |
| **Root cause** | `ports: "6379:6379"` published + no password + Windows FW open |
| **Impact** | Potential exfil of Slack tokens, JWT keys (stored in Redis) |
| **Fix** | Removed port mapping, added auth + disabled dangerous commands |
| **Timeline** | _T00_: alert, _T+2h_: containment, _T+4h_: creds rotated, _T+5h_: Falco deployed |
| **Follow-ups** | Nightly Trivy, secret-push-protection, Falco rule, backup test |
