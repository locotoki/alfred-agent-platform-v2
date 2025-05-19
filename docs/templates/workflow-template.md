# [Workflow Name]

**Last Updated:** YYYY-MM-DD
**Owner:** [Owner Name/Team]
**Status:** [Planned/In Development/Active]

## Overview

[Provide a 1-2 paragraph description of the workflow, its purpose, and its value. Explain what task or process this workflow automates or enhances.]

## Workflow Metadata

| Attribute | Value |
|-----------|-------|
| Primary Agent | [Agent Name](../../agents/[category]/[agent-name].md) |
| Supporting Agents | [List of other agents involved, if any] |
| Projects | [Projects using this workflow] |
| Category | [Functional category: Analysis/Content/Data/etc.] |
| Trigger Type | [Manual/Scheduled/Event-based] |
| Average Runtime | [Expected runtime] |

## Workflow Diagram

[Include a workflow diagram here - can be a link to an image or ASCII diagram]

```
[Workflow Diagram or Flowchart]
```

## Input Parameters

| Parameter | Type | Description | Required | Default |
|-----------|------|-------------|----------|---------|
| [param1] | [type] | Description | Yes/No | [default value if any] |
| [param2] | [type] | Description | Yes/No | [default value if any] |

## Output

[Description of the workflow output format and content]

**Example Output:**
```json
{
  "example": "output structure"
}
```

## Workflow Steps

### 1. [Step Name]

**Description:** [Description of this step]

**Component/Agent:** [Component or agent responsible]

**Actions:**
- [Action 1]
- [Action 2]

**Output:** [What this step produces]

### 2. [Step Name]

**Description:** [Description of this step]

**Component/Agent:** [Component or agent responsible]

**Actions:**
- [Action 1]
- [Action 2]

**Output:** [What this step produces]

## Error Handling

### Common Errors

| Error | Cause | Handling Strategy |
|-------|-------|-------------------|
| [Error 1] | [Cause] | [How it's handled] |
| [Error 2] | [Cause] | [How it's handled] |

### Recovery Mechanisms

[Description of how the workflow recovers from failures]

## Performance Considerations

- **Average Runtime:** [Expected runtime]
- **Resource Requirements:** [CPU, memory, etc.]
- **Scalability Notes:** [How the workflow scales]
- **Optimization Tips:** [Tips for optimizing performance]

## Example Use Cases

### Use Case 1: [Title]

**Scenario:** [Brief description]

**Example Input:**
```json
{
  "param1": "value1",
  "param2": "value2"
}
```

**Expected Output:**
```json
{
  "result": "example output"
}
```

### Use Case 2: [Title]

**Scenario:** [Brief description]

**Example Input:**
```json
{
  "param1": "value1",
  "param2": "value2"
}
```

**Expected Output:**
```json
{
  "result": "example output"
}
```

## Implementation Notes

### Technical Details

[Technical details important for developers]

### Deployment Considerations

[Notes about deploying or updating this workflow]

## Current Limitations

- [Limitation 1]
- [Limitation 2]

## Future Enhancements

- [Planned enhancement 1]
- [Planned enhancement 2]

## Related Workflows

- [Related Workflow 1](../by-agent/[agent-name]/[related-workflow-1].md)
- [Related Workflow 2](../by-agent/[agent-name]/[related-workflow-2].md)

## References

- [Reference 1](link-to-reference)
- [Reference 2](link-to-reference)
