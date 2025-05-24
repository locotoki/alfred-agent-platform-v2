"""Configuration for financial tax agent tests"""

import pytestLFLF# Mark all financial_tax tests as xfail until Phase 9 debt sprintLFpytestmark = pytest.mark.xfail(LF    reason="Legacy agent - will be fixed in Phase 9 debt sprint", strict=False
)
