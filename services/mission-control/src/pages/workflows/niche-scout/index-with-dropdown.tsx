import React, { useState } from "react";
import MainLayout from "../../../components/layout/MainLayout";
import CategoryDropdown from "../../../components/workflows/CategoryDropdown";

// Types ----------------------------------------------------------------------
interface NicheForm {
  category: string;
  subcategory: string;
  description: string;
  timeRange: string;
  demographics: string;
  minViews: string;
  minGrowth: string;
  sources: string[];
}

// Main component --------------------------------------------------------------
export default function NicheScout() {
  const [step, setStep] = useState<1 | 2 | 3>(1);
  const [form, setForm] = useState<NicheForm>({
    category: "",
    subcategory: "",
    description: "",
    timeRange: "Last 30 days",
    demographics: "All",
    minViews: "",
    minGrowth: "",
    sources: ["youtube"],
  });
  const [showSubcategories, setShowSubcategories] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  // Form change utility -------------------------------------------------------
  const updateForm = (field: keyof NicheForm, value: any) =>
    setForm((prev) => ({ ...prev, [field]: value }));

  // Navigation handlers -------------------------------------------------------
  const goToStep = (newStep: 1 | 2 | 3) => setStep(newStep);
  
  const handleNext = () => {
    if (step < 3) {
      setStep((prev) => (prev + 1) as 1 | 2 | 3);
    }
  };
  
  const handleBack = () => {
    if (step > 1) {
      setStep((prev) => (prev - 1) as 1 | 2 | 3);
    }
  };

  // Run workflow handler ------------------------------------------------------
  const handleRunWorkflow = async () => {
    setIsLoading(true);
    try {
      // API call would go here
      await new Promise(resolve => setTimeout(resolve, 2000));
      alert('Workflow completed! Redirecting to results page...');
    } catch (error) {
      console.error('Error running workflow:', error);
      alert('An error occurred while running the workflow');
    } finally {
      setIsLoading(false);
    }
  };

  // Render --------------------------------------------------------------------
  return (
    <MainLayout title="MISSION CONTROL">
      <div className="p-6">
        <h1 className="text-2xl font-bold mb-6">Niche-Scout Workflow</h1>
        
        {/* Progress Steps */}
        <div className="relative flex justify-between items-center mb-12">
          <div className="absolute h-0.5 bg-gray-200 left-0 right-0 top-1/2 -translate-y-1/2"></div>
          
          <div 
            className="relative flex flex-col items-center cursor-pointer"
            onClick={() => goToStep(1)}
          >
            <div className={`w-8 h-8 rounded-full flex items-center justify-center z-10 ${
              step === 1 ? 'bg-blue-500 text-white' : 'bg-white text-gray-500 border border-gray-300'
            }`}>
              1
            </div>
            <span className={`mt-2 text-sm ${step === 1 ? 'text-blue-500' : 'text-gray-500'}`}>
              Define Niche
            </span>
          </div>
          
          <div 
            className="relative flex flex-col items-center cursor-pointer"
            onClick={() => goToStep(2)}
          >
            <div className={`w-8 h-8 rounded-full flex items-center justify-center z-10 ${
              step === 2 ? 'bg-blue-500 text-white' : 'bg-white text-gray-500 border border-gray-300'
            }`}>
              2
            </div>
            <span className={`mt-2 text-sm ${step === 2 ? 'text-blue-500' : 'text-gray-500'}`}>
              Research Parameters
            </span>
          </div>
          
          <div 
            className="relative flex flex-col items-center cursor-pointer"
            onClick={() => goToStep(3)}
          >
            <div className={`w-8 h-8 rounded-full flex items-center justify-center z-10 ${
              step === 3 ? 'bg-blue-500 text-white' : 'bg-white text-gray-500 border border-gray-300'
            }`}>
              3
            </div>
            <span className={`mt-2 text-sm ${step === 3 ? 'text-blue-500' : 'text-gray-500'}`}>
              Review & Run
            </span>
          </div>
        </div>
        
        {/* Step 1: Define Niche */}
        {step === 1 && (
          <div className="bg-white rounded-lg shadow-sm p-6">
            <h2 className="text-xl font-bold mb-6">Define Your Niche</h2>
            
            <div className="mb-6">
              <label className="block font-medium text-gray-700 mb-2">
                What niche are you interested in exploring?
              </label>
              <input
                type="text"
                value={form.description}
                onChange={(e) => updateForm("description", e.target.value)}
                placeholder="e.g. gaming, cooking, fitness, photography"
                className="w-full p-2 border border-gray-300 rounded"
              />
              <p className="mt-1 text-sm text-gray-500">
                Enter keywords that describe your content area of interest
              </p>
            </div>
            
            <div className="mb-6">
              <label className="block font-medium text-gray-700 mb-2">
                Select a Primary Category
              </label>
              <CategoryDropdown 
                value={form.category}
                onChange={(value) => {
                  updateForm("category", value);
                  updateForm("subcategory", "");
                }}
              />
            </div>
            
            <div className="flex justify-end mt-6">
              <button
                onClick={handleNext}
                className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
              >
                Next
              </button>
            </div>
          </div>
        )}
        
        {/* Step 2 content would go here */}
        {/* Step 3 content would go here */}
      </div>
    </MainLayout>
  );
}