# Workflow Implementation Guide

This document provides information about the workflow implementation patterns in the Mission Control UI, which is essential for understanding how to design and integrate new UI components.

## Workflow Patterns

The Mission Control UI implements two main workflow patterns:

1. **Wizard-Based Workflows**: Step-by-step configuration with progressive disclosure
2. **Results Visualization**: Structured display of workflow results with filtering and exploration

## Wizard Pattern Implementation

The wizard pattern uses a step-based approach with the following structure:

1. Define workflow steps as an array
2. Use React state to track the current step index
3. Implement navigation between steps (next/back)
4. Maintain a form state object across steps
5. Use animation transitions for step changes

Example implementation:
```tsx
const STEPS = ["Define Niche", "Research Parameters", "Review & Run"];

export default function WorkflowWizard() {
  const [step, setStep] = useState<0 | 1 | 2>(0);
  const [form, setForm] = useState<FormType>({
    // Initial form state
  });

  // Navigation
  const next = () => setStep((s) => (s < 2 ? ((s + 1) as any) : s));
  const back = () => setStep((s) => (s > 0 ? ((s - 1) as any) : s));
  
  // Form update utility
  const updateForm = (field: keyof FormType, value: any) =>
    setForm((f) => ({ ...f, [field]: value }));

  return (
    <div>
      {/* Progress Indicator */}
      <ProgressBar step={step} totalSteps={STEPS.length} />
      
      {/* Step Content */}
      <AnimatePresence mode="wait">
        {step === 0 && (
          <motion.div
            key="step1"
            initial={{ opacity: 0, x: 50 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -50 }}
          >
            {/* Step 1 Content */}
          </motion.div>
        )}
        
        {/* Other steps */}
      </AnimatePresence>
    </div>
  );
}
```

## Results Visualization Pattern

The results visualization pattern consists of:

1. Loading data using React Query
2. Handling loading/error states
3. Multiple visualization modes (tabs, filters)
4. Export options

Example implementation:
```tsx
export default function WorkflowResults() {
  const { id } = useRouter().query;
  const { data, isLoading, error } = useQuery(
    ['workflowResult', id],
    () => fetchWorkflowResult(id as string)
  );
  
  const [activeTab, setActiveTab] = useState('overview');
  
  if (isLoading) return <LoadingState />;
  if (error) return <ErrorState error={error} />;
  
  return (
    <div>
      <ResultHeader result={data} />
      
      <TabNav
        tabs={['overview', 'details', 'visualization']}
        active={activeTab}
        onChange={setActiveTab}
      />
      
      {activeTab === 'overview' && <OverviewTab data={data} />}
      {activeTab === 'details' && <DetailsTab data={data} />}
      {activeTab === 'visualization' && <VisualizationTab data={data} />}
      
      <ExportOptions data={data} />
    </div>
  );
}
```

## Workflow Loading States

Long-running workflows require effective loading states:

1. Initial submission loading state
2. Processing status updates
3. Completion indication

Implementation approaches:
```tsx
// Simple loading state
const [isLoading, setIsLoading] = useState(false);

const handleSubmit = async () => {
  setIsLoading(true);
  try {
    await runWorkflow(formData);
    router.push(`/results/${resultId}`);
  } catch (error) {
    setError(error);
  } finally {
    setIsLoading(false);
  }
};

// Enhanced loading with progress
const [loadingState, setLoadingState] = useState({
  isLoading: false,
  progress: 0,
  status: '',
});

// With polling for updates
const pollStatus = useCallback(async (taskId) => {
  const interval = setInterval(async () => {
    const status = await checkWorkflowStatus(taskId);
    setLoadingState({
      isLoading: status.state !== 'completed',
      progress: status.progress,
      status: status.statusMessage,
    });
    
    if (status.state === 'completed') {
      clearInterval(interval);
      router.push(`/results/${status.resultId}`);
    }
  }, 2000);
  
  return () => clearInterval(interval);
}, [router]);
```

## Workflow Status Indicators

Status indicators are used throughout the UI to show workflow state:

```tsx
const getStatusBadge = (status) => {
  switch (status) {
    case 'completed':
      return <Badge variant="success">Completed</Badge>;
    case 'running':
      return <Badge variant="primary">Running</Badge>;
    case 'scheduled':
      return <Badge variant="warning">Scheduled</Badge>;
    case 'error':
      return <Badge variant="danger">Error</Badge>;
    default:
      return <Badge variant="secondary">{status}</Badge>;
  }
};
```

## Form Validation

Workflows use form validation to ensure proper execution:

```tsx
const validateForm = () => {
  const errors = {};
  
  if (!form.category) {
    errors.category = 'Category is required';
  }
  
  if (form.minViews && isNaN(Number(form.minViews))) {
    errors.minViews = 'Must be a valid number';
  }
  
  return errors;
};

const handleSubmit = () => {
  const errors = validateForm();
  
  if (Object.keys(errors).length > 0) {
    setFormErrors(errors);
    return;
  }
  
  runWorkflow(form);
};
```

## Best Practices for New Workflow UIs

When designing new workflow UIs:

1. **Progressive Disclosure**: Show only what's needed at each step
2. **Clear Feedback**: Provide clear status indicators and loading states
3. **Consistent Navigation**: Use the same navigation patterns across workflows
4. **Form Validation**: Validate input before submission
5. **Error Handling**: Provide clear error messages and recovery options
6. **Results Organization**: Organize results logically with multiple views
7. **Mobile Consideration**: Ensure workflows function on smaller screens
8. **Performance**: Optimize for fast loading and response times