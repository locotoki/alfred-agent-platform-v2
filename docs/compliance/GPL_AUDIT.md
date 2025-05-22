# GPL Package Audit Status

## Packages Already Removed ✅
- `pyahocorasick` - Confirmed not present in codebase, requirements, or environment
- `colour` - Confirmed not present in codebase, requirements, or environment

## Current GPL/LGPL Packages in Environment
Based on pip-licenses scan on 2025-05-22:

| Package | License | Location | Status |
|---------|---------|----------|---------|
| PyGObject | LGPL v2+ | System | Waived (system dependency) |
| chardet | LGPL | System | Waived (system dependency) |
| cloud-init | GPLv3/Apache-2.0 | System | Waived (dual-licensed) |
| launchpadlib | LGPL | System | Waived (system dependency) |
| lazr.restfulclient | LGPL | System | Waived (system dependency) |
| lazr.uri | LGPL | System | Waived (system dependency) |
| psycopg2-binary | LGPL | Application | Waived (PostgreSQL driver) |
| pycurl | LGPL/MIT | System | Waived (dual-licensed) |
| python-apt | GPL | System | Waived (system dependency) |
| ssh-import-id | GPLv3 | System | Waived (system utility) |
| systemd-python | LGPL v2+ | System | Waived (system dependency) |
| ubuntu-pro-client | GPLv3 | System | Waived (system dependency) |
| ufw | GPL-3 | System | Waived (system firewall) |
| wadllib | LGPL | System | Waived (system dependency) |

## Analysis
- Most GPL/LGPL packages are system dependencies not directly used by application
- No application-level GPL dependencies found requiring immediate replacement
- Licence gate passes with current waivers
- Focus should be on replacing LGPL packages where viable MIT alternatives exist

## Next Actions
1. Review PostgreSQL driver alternatives (psycopg2-binary → psycopg3 or pure-python driver)
2. Audit for any missed application dependencies
3. Consider improving licence gate to handle dual-licensed packages better
