import React from "react";
import { cn } from "@/lib/utils";

interface WizardStepIndicatorProps {
  currentStep: number;
  steps?: Array<{ number: number; title: string }>;
}

export const WizardStepIndicator: React.FC<WizardStepIndicatorProps> = ({
  currentStep,
  steps = [
    { number: 1, title: "Define Niche" },
    { number: 2, title: "Parameters" },
    { number: 3, title: "Review" }
  ]
}) => {
  return (
    <div className="mb-8">
      <div className="flex items-center justify-center relative mb-2">
        {/* Progress bar background */}
        <div className="absolute h-1 bg-gray-200 dark:bg-gray-700 left-0 right-0 top-1/2 -translate-y-1/2 rounded-full z-0" />

        {/* Active progress bar */}
        <div
          className="absolute h-1 bg-gradient-primary left-0 top-1/2 -translate-y-1/2 rounded-full z-0 transition-all duration-300"
          style={{ width: `${((currentStep - 1) / (steps.length - 1)) * 100}%` }}
        />

        {/* Step circles */}
        <div className="flex items-center justify-between w-full relative z-10">
          {steps.map((step) => (
            <div
              key={step.number}
              className="flex flex-col items-center"
            >
              <div
                className={cn(
                  "h-10 w-10 rounded-full flex items-center justify-center text-sm font-medium transition-all duration-300 transform",
                  currentStep === step.number && "scale-110 shadow-lg",
                  currentStep > step.number
                    ? "bg-gradient-primary text-white"
                    : currentStep === step.number
                      ? "bg-gradient-primary text-white animate-pulse"
                      : "bg-white dark:bg-gray-800 text-gray-500 dark:text-gray-400 border-2 border-gray-200 dark:border-gray-700"
                )}
              >
                {currentStep > step.number ? (
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                ) : (
                  step.number
                )}
              </div>
              <span
                className={cn(
                  "mt-2 text-xs font-medium",
                  currentStep >= step.number
                    ? "text-primary dark:text-primary-foreground"
                    : "text-gray-500 dark:text-gray-400"
                )}
              >
                {step.title}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
