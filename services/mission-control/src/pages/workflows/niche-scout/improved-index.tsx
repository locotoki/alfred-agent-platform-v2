import React, { useState } from "react";
import MainLayout from "../../../components/layout/MainLayout";
import { categories, getSubcategories } from "../../../utils/shared-taxonomy";

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
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [showDropdown, setShowDropdown] = useState(false);

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
      // Here you would make the API call to trigger the workflow
      // For now, we'll simulate the API call with a timeout
      await new Promise(resolve => setTimeout(resolve, 2000));

      // Navigate to results page (would normally use router.push)
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
    <MainLayout title="Mission Control">
      <div className="p-6">
        <h1 className="text-2xl font-bold mb-6">Niche-Scout Workflow</h1>

        {/* Progress Steps */}
        <div className="flex justify-between items-center mb-10 relative">
          <div className="absolute top-1/2 left-0 right-0 h-0.5 bg-gray-200 -translate-y-1/2 z-0"></div>

          <div className="flex flex-col items-center relative z-10" onClick={() => goToStep(1)}>
            <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
              step === 1 ? 'bg-blue-500 text-white' : 'bg-white text-gray-500 border border-gray-300'
            }`}>
              1
            </div>
            <span className={`mt-2 text-sm ${step === 1 ? 'text-blue-500' : 'text-gray-500'}`}>Define Niche</span>
          </div>

          <div className="flex flex-col items-center relative z-10" onClick={() => goToStep(2)}>
            <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
              step === 2 ? 'bg-blue-500 text-white' : 'bg-white text-gray-500 border border-gray-300'
            }`}>
              2
            </div>
            <span className={`mt-2 text-sm ${step === 2 ? 'text-blue-500' : 'text-gray-500'}`}>Research Parameters</span>
          </div>

          <div className="flex flex-col items-center relative z-10" onClick={() => goToStep(3)}>
            <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
              step === 3 ? 'bg-blue-500 text-white' : 'bg-white text-gray-500 border border-gray-300'
            }`}>
              3
            </div>
            <span className={`mt-2 text-sm ${step === 3 ? 'text-blue-500' : 'text-gray-500'}`}>Review & Run</span>
          </div>
        </div>

        {/* Step 1: Define Niche */}
        {step === 1 && (
          <div className="bg-white p-6 rounded-lg shadow-sm">
            <h2 className="text-xl font-bold mb-6">Define Your Niche</h2>

            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                What niche are you interested in exploring?
              </label>
              <input
                type="text"
                value={form.description}
                onChange={(e) => updateForm("description", e.target.value)}
                placeholder="e.g. gaming, cooking, fitness, photography"
                className="w-full p-3 border border-gray-300 rounded-md"
              />
              <p className="mt-1 text-sm text-gray-500">
                Enter keywords that describe your content area of interest
              </p>
            </div>

            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Select a Primary Category
              </label>
              <div className="relative">
                <button
                  type="button"
                  className="w-full p-3 border border-gray-300 rounded-md bg-white text-left flex justify-between items-center"
                  onClick={() => setShowDropdown(!showDropdown)}
                >
                  <span>{form.category ? categories.find(c => c.value === form.category)?.label : 'All'}</span>
                  <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path>
                  </svg>
                </button>

                {showDropdown && (
                  <div className="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-md shadow-lg max-h-60 overflow-auto">
                    <ul>
                      <li
                        className="px-4 py-2 hover:bg-blue-50 cursor-pointer"
                        onClick={() => {
                          updateForm("category", "");
                          updateForm("subcategory", "");
                          setShowDropdown(false);
                        }}
                      >
                        All
                      </li>
                      {categories.map(category => (
                        <li
                          key={category.value}
                          className="px-4 py-2 hover:bg-blue-50 cursor-pointer"
                          onClick={() => {
                            updateForm("category", category.value);
                            updateForm("subcategory", "");
                            setShowDropdown(false);
                          }}
                        >
                          {category.label}
                        </li>
                      ))}
                    </ul>
                  </div>
                )}
              </div>
            </div>

            {form.category && (
              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Refine with Subcategories (Optional)
                </label>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
                  {getSubcategories(form.category).map(subcategory => (
                    <div
                      key={subcategory.value}
                      onClick={() => updateForm("subcategory", subcategory.value)}
                      className={`p-3 rounded border cursor-pointer ${
                        form.subcategory === subcategory.value
                          ? 'bg-blue-50 border-blue-300 text-blue-700'
                          : 'bg-gray-50 border-gray-200 text-gray-700'
                      }`}
                    >
                      {subcategory.label}
                    </div>
                  ))}
                </div>
              </div>
            )}

            <div className="flex justify-end">
              <button
                onClick={handleNext}
                className="px-6 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600"
              >
                Next
              </button>
            </div>
          </div>
        )}

        {/* Step 2: Research Parameters */}
        {step === 2 && (
          <div className="bg-white p-6 rounded-lg shadow-sm">
            <h2 className="text-xl font-bold mb-6">Research Parameters</h2>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Time Range
                </label>
                <select
                  value={form.timeRange}
                  onChange={(e) => updateForm("timeRange", e.target.value)}
                  className="w-full p-3 border border-gray-300 rounded-md bg-white"
                >
                  <option>Last 7 days</option>
                  <option>Last 30 days</option>
                  <option>Last 90 days</option>
                  <option>Last 12 months</option>
                </select>
                <p className="mt-1 text-sm text-gray-500">
                  Select how far back to analyze trends
                </p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Target Demographics
                </label>
                <select
                  value={form.demographics}
                  onChange={(e) => updateForm("demographics", e.target.value)}
                  className="w-full p-3 border border-gray-300 rounded-md bg-white"
                >
                  <option>All</option>
                  <option>13-17</option>
                  <option>18-24</option>
                  <option>25-34</option>
                  <option>35-44</option>
                  <option>45+</option>
                </select>
                <p className="mt-1 text-sm text-gray-500">
                  Filter results by audience age group
                </p>
              </div>
            </div>

            <div className="mb-6">
              <button
                onClick={() => setShowAdvanced(!showAdvanced)}
                className="px-4 py-2 border border-gray-300 rounded-md bg-white"
              >
                {showAdvanced ? '- Hide Advanced Options' : '+ Advanced Options'}
              </button>
            </div>

            {showAdvanced && (
              <div className="border border-gray-200 rounded-md p-4 mb-6">
                <h3 className="text-lg font-medium mb-4">Advanced Filters</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Minimum Views
                    </label>
                    <input
                      type="number"
                      value={form.minViews}
                      onChange={(e) => updateForm("minViews", e.target.value)}
                      placeholder="e.g. 10000"
                      className="w-full p-3 border border-gray-300 rounded-md"
                    />
                    <p className="mt-1 text-sm text-gray-500">
                      Exclude videos with fewer views
                    </p>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Minimum Growth (%)
                    </label>
                    <input
                      type="number"
                      value={form.minGrowth}
                      onChange={(e) => updateForm("minGrowth", e.target.value)}
                      placeholder="e.g. 20"
                      className="w-full p-3 border border-gray-300 rounded-md"
                    />
                    <p className="mt-1 text-sm text-gray-500">
                      Focus on rapidly growing niches
                    </p>
                  </div>
                </div>
              </div>
            )}

            <div className="flex justify-between">
              <button
                onClick={handleBack}
                className="px-6 py-2 border border-gray-300 bg-white rounded-md"
              >
                Back
              </button>
              <button
                onClick={handleNext}
                className="px-6 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600"
              >
                Next
              </button>
            </div>
          </div>
        )}

        {/* Step 3: Review & Run */}
        {step === 3 && (
          <div className="bg-white p-6 rounded-lg shadow-sm">
            <h2 className="text-xl font-bold mb-6">Review & Run</h2>

            <div className="bg-gray-50 p-4 rounded-lg mb-6">
              <h3 className="text-lg font-medium mb-4">Niche Scout Summary</h3>

              <div className="space-y-3">
                <div className="grid grid-cols-3 gap-2">
                  <span className="font-medium">Niche Query:</span>
                  <span className="col-span-2 text-blue-600">{form.description || '(not specified)'}</span>
                </div>
                <div className="grid grid-cols-3 gap-2">
                  <span className="font-medium">Category:</span>
                  <span className="col-span-2 text-blue-600">
                    {form.category ? categories.find(c => c.value === form.category)?.label : 'All'}
                  </span>
                </div>
                {form.subcategory && (
                  <div className="grid grid-cols-3 gap-2">
                    <span className="font-medium">Subcategory:</span>
                    <span className="col-span-2 text-blue-600">
                      {getSubcategories(form.category).find(s => s.value === form.subcategory)?.label}
                    </span>
                  </div>
                )}
                <div className="grid grid-cols-3 gap-2">
                  <span className="font-medium">Time Range:</span>
                  <span className="col-span-2 text-blue-600">{form.timeRange}</span>
                </div>
                <div className="grid grid-cols-3 gap-2">
                  <span className="font-medium">Demographics:</span>
                  <span className="col-span-2 text-blue-600">{form.demographics}</span>
                </div>
                {(form.minViews || form.minGrowth) && (
                  <div className="grid grid-cols-3 gap-2">
                    <span className="font-medium">Filters:</span>
                    <span className="col-span-2 text-blue-600">
                      {form.minViews && `Min Views: ${form.minViews}`}
                      {form.minViews && form.minGrowth && ', '}
                      {form.minGrowth && `Min Growth: ${form.minGrowth}%`}
                    </span>
                  </div>
                )}
              </div>
            </div>

            <div className="bg-blue-50 p-4 rounded-lg mb-6">
              <h3 className="text-lg font-medium text-blue-800 mb-4">What You'll Get</h3>

              <ul className="space-y-2 text-blue-700 ml-5 list-disc">
                <li>Top performing niches based on views and engagement</li>
                <li>Growth rate analysis for trending content areas</li>
                <li>Visual mapping of niche positioning</li>
                <li>Opportunity score for niche competitiveness</li>
                <li>Recommended content strategies</li>
              </ul>

              <div className="mt-4 p-3 border border-blue-200 rounded bg-blue-100">
                <div className="flex items-center">
                  <svg className="w-5 h-5 text-blue-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                  </svg>
                  <p className="text-sm text-blue-700">
                    Estimated time: <strong>3-5 minutes</strong>
                  </p>
                </div>
              </div>
            </div>

            <div className="flex justify-between">
              <button
                onClick={handleBack}
                className="px-6 py-2 border border-gray-300 bg-white rounded-md"
              >
                Back
              </button>
              <button
                onClick={handleRunWorkflow}
                disabled={isLoading}
                className="px-6 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 disabled:bg-blue-300"
              >
                {isLoading ? 'Running...' : 'Run Analysis Now'}
              </button>
            </div>
          </div>
        )}
      </div>
    </MainLayout>
  );
}
