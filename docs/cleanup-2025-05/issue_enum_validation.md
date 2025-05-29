## Enum validation clean-up in `test_models.py`

### Background
During the SC-330 work to remove xfail markers and fix async issues, we identified issues with enum validation in `tests/unit/agents/financial_tax/test_models.py`. The test is failing because the validation errors format has changed.

### Issue
The test `test_enum_validation` is failing with a Pydantic validation error due to enum validation differences:

```python
def test_enum_validation(self):
    """Test enum values are validated."""
    # Test with invalid jurisdiction by using a string
    with pytest.raises(ValidationError):
        TaxCalculationRequest(
            income=100000,
            deductions={},
            credits={},
            jurisdiction="INVALID_JURISDICTION",
            tax_year=2024,
            entity_type=EntityType.INDIVIDUAL,
        )
```

The test expects a validation error but the format of the error or the validation mechanism itself has changed between Pydantic versions.

### Acceptance Criteria
- [ ] Fix the `test_enum_validation` test to properly check for validation errors
- [ ] Update the test to be compatible with the current Pydantic version
- [ ] Ensure the test passes reliably with pytest
- [ ] Add tests to validate other enum fields (entity_type, etc.)

### Root cause analysis
The error appears to be related to Pydantic's validation mechanism. The error message format in Pydantic v2 is different from what the test expected:

```
pydantic_core._pydantic_core.ValidationError: 1 validation error for TaxCalculationRequest
jurisdiction
  Input should be 'US-FED', 'US-CA', 'US-NY', 'US-TX', 'US-FL', 'UK', 'EU', 'CA', 'AU', 'SG', 'JP' or 'IN' [type=enum, input_value='INVALID_JURISDICTION', input_type=str]
    For further information visit https://errors.pydantic.dev/2.11/v/enum
```

### Suggested approach
1. Update the test to check for the specific error message content or type
2. Consider using Pydantic's own testing utilities to validate enum behaviors
3. Match the error handling to the version of Pydantic being used
