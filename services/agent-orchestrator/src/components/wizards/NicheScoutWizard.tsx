import React, { useState } from "react";
import { Dialog, DialogContent, DialogFooter, DialogTrigger } from "@/components/ui/dialog";
import { TooltipProvider } from "@/components/ui/tooltip";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Loader2 } from "lucide-react";
import { StepOne } from "./niche-scout/StepOne";
import { StepTwo } from "./niche-scout/StepTwo";
import { StepThree } from "./niche-scout/StepThree";
import { WizardStepIndicator } from "./niche-scout/WizardStepIndicator";
import { WizardFooter } from "./niche-scout/WizardFooter";
import { Category, FinalPayload } from "@/types/niche-scout";
import { categories as defaultCategories, subcategoryMap as defaultSubcategoryMap } from "@/config/taxonomy";
import { useNicheScoutWizard } from "@/hooks/use-niche-scout-wizard";
import { runNicheScout } from "@/lib/youtube-service";
import { FadeIn } from "../ui/animations/FadeIn";

interface NicheScoutWizardProps {
  trigger: React.ReactNode;
  onComplete: (payload: FinalPayload & { actualCost?: number; actualEta?: number }) => void;
  categories?: Category[];
  subcategoryMap?: Record<string, Category[]>;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
}

export const NicheScoutWizard: React.FC<NicheScoutWizardProps> = ({
  trigger,
  onComplete,
  categories = defaultCategories,
  subcategoryMap = defaultSubcategoryMap,
  open: controlledOpen,
  onOpenChange,
}) => {
  const [uncontrolledOpen, setUncontrolledOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Use controlled or uncontrolled open state
  const isControlled = controlledOpen !== undefined;
  const open = isControlled ? controlledOpen : uncontrolledOpen;

  const setOpen = (newOpen: boolean) => {
    if (isControlled) {
      onOpenChange?.(newOpen);
    } else {
      setUncontrolledOpen(newOpen);
    }
  };

  const {
    step,
    setStep,
    selectedCategory,
    selectedSubcategory,
    budget,
    setBudget,
    dataSources,
    setDataSources,
    lastAccuracy,
    setLastAccuracy,
    resetWizard,
    handleCategoryChange,
    handleSubcategoryChange,
    calculateEstimates,
  } = useNicheScoutWizard();

  const handleDialogOpenChange = (open: boolean) => {
    setOpen(open);
    if (!open) {
      resetWizard();
    }
  };

  const subcategories = selectedCategory
    ? subcategoryMap[selectedCategory.value] || []
    : [];

  const handleComplete = async () => {
    if (selectedCategory && selectedSubcategory) {
      setIsSubmitting(true);
      setError(null);

      const payload: FinalPayload = {
        category: selectedCategory,
        subcategory: selectedSubcategory,
        budget,
        dataSources,
        estimatedTime: calculateEstimates.estimatedTime,
        estimatedCost: calculateEstimates.estimatedCost
      };

      try {
        // Call the real API endpoint
        const result = await runNicheScout({
          category: selectedCategory.value,
          subcategory: selectedSubcategory.value,
          budget,
          dataSources
        });

        // Get actual values from the response or use estimates if not available
        const actual = {
          ...payload,
          actualCost: result.actual_cost || calculateEstimates.estimatedCost,
          actualEta: result.actual_processing_time || calculateEstimates.estimatedTime,
        };

        // Close the dialog
        setOpen(false);

        // Callback with result
        onComplete(actual);
      } catch (err) {
        console.error("Error running niche scout:", err);
        setError(err instanceof Error ? err.message : "An unknown error occurred");
      } finally {
        setIsSubmitting(false);
      }
    }
  };

  return (
    <Dialog open={open} onOpenChange={handleDialogOpenChange}>
      <DialogTrigger asChild>
        {trigger}
      </DialogTrigger>
      <DialogContent className="sm:max-w-[600px] p-0 gap-0 overflow-hidden">
        <div className="bg-gradient-primary text-white p-6 flex flex-col items-center justify-center text-center">
          <h2 className="text-2xl font-bold mb-1">Niche Scout</h2>
          <p className="text-white/80 text-sm">
            Discover trending YouTube niches with high opportunity scores
          </p>
        </div>

        <div className="p-6">
          <TooltipProvider>
            <WizardStepIndicator currentStep={step} />

            <div className="min-h-[320px]">
              {step === 1 && (
                <FadeIn direction="right">
                  <StepOne
                    categories={categories}
                    selectedCategory={selectedCategory}
                    onCategoryChange={handleCategoryChange}
                    subcategories={subcategories}
                    selectedSubcategory={selectedSubcategory}
                    onSubcategoryChange={handleSubcategoryChange}
                  />
                </FadeIn>
              )}

              {step === 2 && (
                <FadeIn direction="right">
                  <StepTwo
                    budget={budget}
                    onBudgetChange={setBudget}
                    dataSources={dataSources}
                    onDataSourcesChange={setDataSources}
                    lastAccuracy={lastAccuracy}
                    onAccuracyChange={setLastAccuracy}
                  />
                </FadeIn>
              )}

              {step === 3 && (
                <FadeIn direction="right">
                  <StepThree
                    category={selectedCategory}
                    subcategory={selectedSubcategory}
                    estimates={calculateEstimates}
                    dataSources={dataSources}
                  />
                </FadeIn>
              )}
            </div>

            {error && (
              <FadeIn direction="up">
                <Alert variant="destructive" className="mt-4">
                  <AlertDescription>{error}</AlertDescription>
                </Alert>
              </FadeIn>
            )}

            <DialogFooter className="px-0 pt-0">
              <WizardFooter
                step={step}
                isNextDisabled={
                  (step === 1 && (!selectedCategory || !selectedSubcategory)) ||
                  (step === 2 && (!budget || budget <= 0))
                }
                onBack={() => setStep(step > 1 ? step - 1 : 1)}
                onNext={() => setStep(step < 3 ? step + 1 : 3)}
                onComplete={handleComplete}
                isSubmitting={isSubmitting}
              />
            </DialogFooter>
          </TooltipProvider>
        </div>
      </DialogContent>
    </Dialog>
  );
};
