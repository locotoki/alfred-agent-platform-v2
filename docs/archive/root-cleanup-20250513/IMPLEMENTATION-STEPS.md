# UI Migration Implementation Steps

This document provides step-by-step instructions for implementing the UI migration from mission-control to agent-orchestrator.

## Setup (Completed)

1. ✅ Create migration plan
2. ✅ Create feature parity checklist
3. ✅ Set up shared component structure
4. ✅ Create design tokens system
5. ✅ Create initial shared components:
   - ✅ StatsCard
   - ✅ GradientButton
   - ✅ FadeIn animation
   - ✅ GradientProgressBar
6. ✅ Set up symlinks in both projects
7. ✅ Create development script

## Next Steps

### Immediate Tasks (Week 1)

1. **Start using shared components in agent-orchestrator**:
   ```tsx
   // Example implementation in agent-orchestrator
   import { GradientButton } from '../shared-components/components/ui/buttons/GradientButton';
   import { StatsCard } from '../shared-components/components/ui/cards/StatsCard';

   // Then use these components in your UI
   <GradientButton variant="primary">Action</GradientButton>
   ```

2. **Implement gradient styles in agent-orchestrator**:
   - Add the following to your CSS imports in agent-orchestrator:
   ```tsx
   // In your main CSS file or component
   import '../shared-components/styles/mixins/gradients.css';
   ```

3. **Migrate dashboard enhancements**:
   - Update the `DashboardView.tsx` in agent-orchestrator to use gradient styles
   - Add animations to dashboard elements with the `FadeIn` component
   - Replace standard progress bars with `GradientProgressBar`

4. **Test with both UIs running**:
   ```bash
   # Start both UIs for comparison
   /home/locotoki/projects/alfred-agent-platform-v2/scripts/start-all-dev.sh
   ```

### Next Phase Tasks (Week 2-3)

1. **Migrate workflow visualization components**:
   - Extract UI components from mission-control's workflow pages
   - Create shared versions in the shared components library
   - Implement these components in agent-orchestrator

2. **Implement animated activity feed**:
   - Create shared activity feed component based on mission-control implementation
   - Add animation effects for item transitions
   - Implement in agent-orchestrator dashboard

3. **Add colorful visualizations**:
   - Migrate chart and data visualization components
   - Add gradient styling to charts
   - Implement in agent-orchestrator's reporting views

4. **Enhance form components**:
   - Apply gradient styling to form elements
   - Add animation effects for validation and state changes
   - Implement in agent-orchestrator's workflow wizards

## Usage Examples

### Using GradientButton

```tsx
import { GradientButton } from '../shared-components/components/ui/buttons/GradientButton';

const MyComponent = () => {
  return (
    <div>
      <h2>Actions</h2>
      <div className="flex space-x-4">
        <GradientButton variant="primary">Primary Action</GradientButton>
        <GradientButton variant="secondary">Secondary Action</GradientButton>
        <GradientButton variant="success">Success Action</GradientButton>
        <GradientButton variant="warning">Warning Action</GradientButton>
        <GradientButton variant="error">Error Action</GradientButton>
      </div>
    </div>
  );
};
```

### Using StatsCard

```tsx
import { StatsCard } from '../shared-components/components/ui/cards/StatsCard';
import { FileText, Users, Server } from 'lucide-react';

const DashboardStats = () => {
  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
      <StatsCard
        title="Total Users"
        value="1,234"
        icon={<Users className="h-6 w-6" />}
        trend={{ value: "12%", isPositive: true }}
      />

      <StatsCard
        title="Active Tasks"
        value="42"
        icon={<FileText className="h-6 w-6" />}
        trend={{ value: "5", isPositive: true }}
      />

      <StatsCard
        title="Server Load"
        value="28%"
        icon={<Server className="h-6 w-6" />}
        trend={{ value: "3%", isPositive: false }}
      />
    </div>
  );
};
```

### Using FadeIn Animation

```tsx
import { FadeIn } from '../shared-components/components/ui/animations/FadeIn';

const AnimatedList = ({ items }) => {
  return (
    <div className="space-y-4">
      {items.map((item, index) => (
        <FadeIn
          key={item.id}
          delay={index * 100}
          direction="up"
          distance={10}
        >
          <div className="p-4 bg-white rounded shadow">
            {item.content}
          </div>
        </FadeIn>
      ))}
    </div>
  );
};
```

### Using GradientProgressBar

```tsx
import { GradientProgressBar } from '../shared-components/components/ui/visualizations/GradientProgressBar';

const SystemMetrics = () => {
  return (
    <div className="space-y-6">
      <GradientProgressBar
        value={75}
        variant="primary"
        showValue={true}
        animated={true}
        label="CPU Usage"
      />

      <GradientProgressBar
        value={45}
        variant="secondary"
        showValue={true}
        label="Memory Usage"
      />

      <GradientProgressBar
        value={92}
        variant="success"
        showValue={true}
        label="Disk Space"
      />

      <GradientProgressBar
        value={30}
        variant="warning"
        showValue={true}
        striped={true}
        label="Network Bandwidth"
      />
    </div>
  );
};
```

## Troubleshooting

If you encounter issues with the shared components:

1. **Path resolution problems**:
   - Ensure symlinks are correctly set up in both projects
   - Check import paths in your components

2. **CSS conflicts**:
   - Use more specific selectors if necessary
   - Consider using CSS modules or styles scoping

3. **Type errors**:
   - Ensure TypeScript can resolve the shared types
   - Add proper type declarations where needed

## Updating Shared Components

When you need to update a shared component:

1. Edit the component in the shared directory
2. The changes will automatically be available to both projects
3. Test in both environments to ensure compatibility

## Reporting Progress

Update the FEATURE-PARITY-CHECKLIST.md file as you complete items:

```markdown
| Feature | Mission Control | Agent Orchestrator | Priority | Notes |
|---------|----------------|-------------------|----------|-------|
| StatsCard components | ✅ | ✅ | High | Completed |
| Gradient styling | ✅ | ✅ | High | Completed |
```
