import React from "react";
import { Loader2, ArrowLeft, ArrowRight, Play } from "lucide-react";
import { GradientButton } from "../../ui/buttons/GradientButton";

interface WizardFooterProps {
  step: number;
  isNextDisabled: boolean;
  onBack: () => void;
  onNext: () => void;
  onComplete: () => void;
  isSubmitting?: boolean;
}

export const WizardFooter: React.FC<WizardFooterProps> = ({
  step,
  isNextDisabled,
  onBack,
  onNext,
  onComplete,
  isSubmitting = false,
}) => {
  return (
    <div className="flex justify-between pt-4 border-t mt-6">
      <div>
        {step > 1 && (
          <GradientButton
            variant="secondary"
            onClick={onBack}
            disabled={isSubmitting}
            iconBefore={<ArrowLeft className="h-4 w-4 mr-1" />}
            size="md"
          >
            Back
          </GradientButton>
        )}
      </div>

      <div>
        {step < 3 ? (
          <GradientButton
            variant="primary"
            onClick={onNext}
            disabled={isNextDisabled || isSubmitting}
            iconAfter={<ArrowRight className="h-4 w-4 ml-1" />}
            size="md"
          >
            Next
          </GradientButton>
        ) : (
          <GradientButton
            variant="success"
            onClick={onComplete}
            disabled={isSubmitting}
            iconBefore={isSubmitting ? (
              <Loader2 className="h-4 w-4 mr-2 animate-spin" />
            ) : (
              <Play className="h-4 w-4 mr-1" />
            )}
            size="md"
          >
            {isSubmitting ? "Running Analysis..." : "Run Analysis"}
          </GradientButton>
        )}
      </div>
    </div>
  );
};
