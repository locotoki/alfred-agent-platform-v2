import React, { ReactNode } from 'react';

interface Step {
  id: number | string;
  title: string;
}

interface WorkflowWizardProps {
  steps: Step[];
  currentStep: number;
  children: ReactNode;
  onNext?: () => void;
  onPrevious?: () => void;
  loading?: boolean;
}

export default function WorkflowWizard({
  steps,
  currentStep,
  children,
  onNext,
  onPrevious,
  loading = false
}: WorkflowWizardProps) {
  const progressPercentage = ((currentStep + 1) / steps.length) * 100;

  return (
    <div className="mb-6">
      {/* Progress Bar */}
      <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2 mb-6">
        <div
          className="bg-blue-600 h-2 rounded-full transition-all duration-300"
          style={{ width: `${progressPercentage}%` }}
        ></div>
      </div>

      {/* Step Indicators */}
      <div className="flex justify-between mb-8">
        {steps.map((step, index) => (
          <div key={step.id} className="flex flex-col items-center">
            <div className={`w-8 h-8 flex items-center justify-center rounded-full 
              ${index < currentStep 
                ? 'bg-blue-600 text-white' 
                : index === currentStep 
                  ? 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400 border border-blue-500' 
                  : 'bg-gray-200 text-gray-700 dark:bg-gray-700 dark:text-gray-400'}`}>
              {index + 1}
            </div>
            <span className="text-sm mt-2">{step.title}</span>
          </div>
        ))}
      </div>

      {/* Content */}
      <div className="card">
        <div className="card-body">
          {children}
        </div>
        
        {/* Navigation Buttons */}
        {(onNext || onPrevious) && (
          <div className="card-footer flex justify-between">
            {onPrevious && (
              <button
                onClick={onPrevious}
                disabled={loading || currentStep === 0}
                className="button-secondary"
              >
                Previous
              </button>
            )}
            <div className="flex-1"></div>
            {onNext && (
              <button
                onClick={onNext}
                disabled={loading || currentStep === steps.length - 1}
                className="button-primary"
              >
                {currentStep === steps.length - 1 ? 'Run Workflow' : 'Next'}
              </button>
            )}
          </div>
        )}
      </div>
    </div>
  );
}