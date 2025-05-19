# API Schema: {Schema Name}

*Last Updated: YYYY-MM-DD*
*Owner: {Owner}*
*Status: {Draft|Active|Deprecated|Replaced}*

## Overview

{Provide a concise overview of what this schema represents and its purpose within the Alfred Agent Platform. Include information about which services or components use this schema and why it's important.}

## Schema Definition

```json
{
  "type": "object",
  "required": ["field1", "field2"],
  "properties": {
    "field1": {
      "type": "string",
      "description": "Description of field1"
    },
    "field2": {
      "type": "integer",
      "description": "Description of field2"
    },
    "field3": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "description": "Description of field3"
    }
  }
}
```

## Field Descriptions

| Field | Type | Required | Description | Constraints |
|-------|------|----------|-------------|------------|
| field1 | string | Yes | Detailed description of field1 and its purpose | Max length: 100 chars |
| field2 | integer | Yes | Detailed description of field2 and its purpose | Min: 0, Max: 100 |
| field3 | array of strings | No | Detailed description of field3 and its purpose | Max items: 10 |

## Examples

### Basic Example

```json
{
  "field1": "example value",
  "field2": 42,
  "field3": ["item1", "item2"]
}
```

### Complete Example

```json
{
  "field1": "comprehensive example value",
  "field2": 99,
  "field3": ["item1", "item2", "item3"],
  "field4": {
    "nested1": "nested value",
    "nested2": true
  }
}
```

## Validation Rules

1. **Field1 Validation**:
   - Must be a non-empty string
   - Maximum length: 100 characters
   - Must not contain special characters except hyphens and underscores

2. **Field2 Validation**:
   - Must be a non-negative integer
   - Value range: 0-100
   - {Additional validation rules if applicable}

3. **Field3 Validation**:
   - Each item must be a valid string
   - Maximum 10 items in the array
   - No duplicate items allowed

## Related Schemas

- [Related Schema 1](path/to/related-schema-1.md): Describe relationship
- [Related Schema 2](path/to/related-schema-2.md): Describe relationship

## Implementation Considerations

{Provide specific considerations, best practices, or warnings related to implementing or working with this schema. Include information about backward compatibility, performance implications, or security considerations.}

## Changelog

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0.0 | YYYY-MM-DD | Initial version | {Author Name} |
| 1.1.0 | YYYY-MM-DD | Added field4, updated validation rules | {Author Name} |

## References

- [JSON Schema Specification](https://json-schema.org/specification.html)
- [Internal Reference Document](path/to/internal/reference)
- {Additional references as needed}
