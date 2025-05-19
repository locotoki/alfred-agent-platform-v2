import React, { useState } from "react";
import dynamic from "next/dynamic";

// Dynamically load the better loading component with no SSR
import MainLayout from "../../../components/layout/MainLayout";
import { motion, AnimatePresence } from "framer-motion";

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

// Step titles and helper ------------------------------------------------------
const STEPS = ["Define Niche", "Research Parameters", "Review & Run"] as const;
type StepType = typeof STEPS[number];

// Main component --------------------------------------------------------------
export default function NicheScout() {
  const [step, setStep] = useState<0 | 1 | 2>(0);
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
  const [showScheduleModal, setShowScheduleModal] = useState(false);
  const [frequency, setFrequency] = useState("daily");
  const [runDate, setRunDate] = useState("");

  // helpers -------------------------------------------------------------------
  const next = () => setStep((s) => (s < 2 ? ((s + 1) as any) : s));
  const back = () => setStep((s) => (s > 0 ? ((s - 1) as any) : s));
  const pct = ((step + 1) / 3) * 100;

  // form change utility -------------------------------------------------------
  const update = (field: keyof NicheForm, value: any) =>
    setForm((f) => ({ ...f, [field]: value }));

  const handleRunWorkflow = async () => {\r\n    console.log('CLIENT: Starting API call to niche-scout');
    setIsLoading(true);
    // Simulate API call with a timeout
    setTimeout(() => {
      alert('Analysis complete! Navigating to results...');
      setIsLoading(false);
    }, 2000);
  };

  const handleScheduleWorkflow = () => {
    setShowScheduleModal(false);
    alert('Workflow scheduled successfully!');
  };

  // Render --------------------------------------------------------------------
  return (
    <MainLayout title="Niche-Scout Workflow">
      <div className="space-y-6">
        <div className="pb-5 border-b border-gray-200 dark:border-gray-700 mb-6">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Niche-Scout Workflow
          </h1>
        </div>

        {/* Progress Bar */}
        <div className="w-full bg-gray-200 rounded-full h-2.5 mb-6">
          <div
            className="bg-blue-600 h-2.5 rounded-full transition-all duration-300"
            style={{ width: `${pct}%` }}
          ></div>
        </div>

        {/* Wizard Steps */}
        <div className="mb-6">
          <div className="flex items-center justify-between">
            <div className={`flex items-center ${step >= 0 ? 'text-blue-600' : 'text-gray-400'}`}>
              <div className={`w-8 h-8 flex items-center justify-center rounded-full ${step >= 0 ? 'bg-blue-100 text-blue-600' : 'bg-gray-100 text-gray-400'}`}>
                1
              </div>
              <span className="ml-2 text-sm font-medium">Define Niche</span>
            </div>
            <div className="flex-1 h-0.5 mx-4 bg-gray-200"></div>
            <div className={`flex items-center ${step >= 1 ? 'text-blue-600' : 'text-gray-400'}`}>
              <div className={`w-8 h-8 flex items-center justify-center rounded-full ${step >= 1 ? 'bg-blue-100 text-blue-600' : 'bg-gray-100 text-gray-400'}`}>
                2
              </div>
              <span className="ml-2 text-sm font-medium">Research Parameters</span>
            </div>
            <div className="flex-1 h-0.5 mx-4 bg-gray-200"></div>
            <div className={`flex items-center ${step >= 2 ? 'text-blue-600' : 'text-gray-400'}`}>
              <div className={`w-8 h-8 flex items-center justify-center rounded-full ${step >= 2 ? 'bg-blue-100 text-blue-600' : 'bg-gray-100 text-gray-400'}`}>
                3
              </div>
              <span className="ml-2 text-sm font-medium">Review & Run</span>
            </div>
          </div>
        </div>

        <div className="card p-6">
          <AnimatePresence mode="wait">
            {/* Step 1: Define Niche */}
            {step === 0 && (
              <motion.div
                key="step1"
                initial={{ opacity: 0, x: 50 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -50 }}
                transition={{ duration: 0.3 }}
                className="space-y-4"
              >
                <h2 className="text-xl font-bold mb-4">Define Your Niche</h2>

                <div className="mb-6">
                  <label htmlFor="niche-query" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    What niche are you interested in exploring?
                  </label>
                  <input
                    id="niche-query"
                    type="text"
                    value={form.description}
                    onChange={(e) => update("description", e.target.value)}
                    placeholder="e.g. gaming, cooking, fitness, photography"
                    className="input w-full text-lg p-4"
                  />
                  <p className="text-sm text-gray-500 mt-1">
                    Enter keywords that describe your content area of interest
                  </p>
                </div>

                <div className="mb-6">
                  <label htmlFor="category" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Select a Primary Category
                  </label>
                  <select
                    id="category"
                    value={form.category}
                    onChange={(e) => {
                      update("category", e.target.value);
                      update("subcategory", "");
                    }}
                    className="input w-full"
                  >
                    <option value="">Select a category</option>
                    <option value="Gaming">Gaming</option>
                    <option value="Health & Fitness">Health & Fitness</option>
                    <option value="Education">Education</option>
                    <option value="Finance">Finance</option>
                    <option value="Entertainment">Entertainment</option>
                    <option value="Howto & Style">Howto & Style</option>
                    <option value="Science & Technology">Science & Technology</option>
                  </select>
                </div>

                {form.category && (
                  <div className="mb-6">
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                      Refine with Subcategories (Optional)
                    </label>
                    <div className="grid grid-cols-2 md:grid-cols-3 gap-2">
                      {SUBCATEGORIES[form.category as keyof typeof SUBCATEGORIES]?.map((subcategory) => (
                        <div
                          key={subcategory}
                          onClick={() => update("subcategory", subcategory)}
                          className={`p-2 rounded border cursor-pointer ${
                            form.subcategory === subcategory
                              ? 'bg-blue-50 border-blue-300 text-blue-700'
                              : 'bg-gray-50 border-gray-200 text-gray-700'
                          }`}
                        >
                          {subcategory}
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                <div className="flex justify-end mt-6">
                  <button
                    onClick={next}
                    className="btn-primary"
                  >
                    Next: Research Parameters
                  </button>
                </div>
              </motion.div>
            )}

            {/* Step 2: Research Parameters */}
            {step === 1 && (
              <motion.div
                key="step2"
                initial={{ opacity: 0, x: 50 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -50 }}
                transition={{ duration: 0.3 }}
                className="space-y-4"
              >
                <h2 className="text-xl font-bold mb-4">Set Research Parameters</h2>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                  <div>
                    <label htmlFor="time-range" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Time Range
                    </label>
                    <select
                      id="time-range"
                      value={form.timeRange}
                      onChange={(e) => update("timeRange", e.target.value)}
                      className="input w-full"
                    >
                      <option>Last 7 days</option>
                      <option>Last 30 days</option>
                      <option>Last 90 days</option>
                      <option>Last 12 months</option>
                    </select>
                    <p className="text-sm text-gray-500 mt-1">
                      Select how far back to analyze trends
                    </p>
                  </div>

                  <div>
                    <label htmlFor="demographics" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Target Demographics
                    </label>
                    <select
                      id="demographics"
                      value={form.demographics}
                      onChange={(e) => update("demographics", e.target.value)}
                      className="input w-full"
                    >
                      <option>All</option>
                      <option>13-17</option>
                      <option>18-24</option>
                      <option>25-34</option>
                      <option>35-44</option>
                      <option>45+</option>
                    </select>
                    <p className="text-sm text-gray-500 mt-1">
                      Filter results by audience age group
                    </p>
                  </div>
                </div>

                <div className="mb-6">
                  <button
                    onClick={() => setShowAdvanced(!showAdvanced)}
                    className="btn-secondary"
                  >
                    {showAdvanced ? '- Hide Advanced Options' : '+ Advanced Options'}
                  </button>
                </div>

                {showAdvanced && (
                  <div className="border border-gray-200 dark:border-gray-700 rounded-md p-4 mb-6">
                    <h3 className="text-lg font-semibold mb-2">Advanced Filters</h3>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <label htmlFor="min-views" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                          Minimum Views
                        </label>
                        <input
                          id="min-views"
                          type="number"
                          value={form.minViews}
                          onChange={(e) => update("minViews", e.target.value)}
                          placeholder="e.g. 10000"
                          className="input w-full"
                        />
                        <p className="text-sm text-gray-500 mt-1">
                          Exclude videos with fewer views
                        </p>
                      </div>
                      <div>
                        <label htmlFor="min-growth" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                          Minimum Growth (%)
                        </label>
                        <input
                          id="min-growth"
                          type="number"
                          value={form.minGrowth}
                          onChange={(e) => update("minGrowth", e.target.value)}
                          placeholder="e.g. 20"
                          className="input w-full"
                        />
                        <p className="text-sm text-gray-500 mt-1">
                          Focus on rapidly growing niches
                        </p>
                      </div>
                    </div>
                  </div>
                )}

                <div className="flex justify-between mt-6">
                  <button
                    onClick={back}
                    className="btn-secondary"
                  >
                    Back: Define Niche
                  </button>
                  <button
                    onClick={next}
                    className="btn-primary"
                  >
                    Next: Review & Run
                  </button>
                </div>
              </motion.div>
            )}

            {/* Step 3: Review & Run */}
            {step === 2 && (
              <motion.div
                key="step3"
                initial={{ opacity: 0, x: 50 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -50 }}
                transition={{ duration: 0.3 }}
                className="space-y-4"
              >
                <h2 className="text-xl font-bold mb-4">Review & Run Analysis</h2>

                <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-4 mb-6">
                  <h3 className="text-lg font-semibold mb-2">Niche Scout Summary</h3>

                  <div className="space-y-3">
                    <div className="flex">
                      <span className="font-medium w-32">Niche Query:</span>
                      <span className="text-blue-600">{form.description || '(not specified)'}</span>
                    </div>
                    <div className="flex">
                      <span className="font-medium w-32">Category:</span>
                      <span className="text-blue-600">{form.category || 'All'}</span>
                    </div>
                    {form.subcategory && (
                      <div className="flex">
                        <span className="font-medium w-32">Subcategory:</span>
                        <span className="text-blue-600">{form.subcategory}</span>
                      </div>
                    )}
                    <div className="flex">
                      <span className="font-medium w-32">Time Range:</span>
                      <span className="text-blue-600">{form.timeRange}</span>
                    </div>
                    <div className="flex">
                      <span className="font-medium w-32">Demographics:</span>
                      <span className="text-blue-600">{form.demographics}</span>
                    </div>
                    {(form.minViews || form.minGrowth) && (
                      <div className="flex">
                        <span className="font-medium w-32">Filters:</span>
                        <span className="text-blue-600">
                          {form.minViews && `Min Views: ${form.minViews}`}
                          {form.minViews && form.minGrowth && ', '}
                          {form.minGrowth && `Min Growth: ${form.minGrowth}%`}
                        </span>
                      </div>
                    )}
                  </div>
                </div>

                <div className="bg-blue-50 dark:bg-blue-900 rounded-lg p-4 mb-6">
                  <h3 className="text-lg font-semibold mb-2 text-blue-800 dark:text-blue-200">What You'll Get</h3>

                  <ul className="list-disc list-inside space-y-2 text-blue-700 dark:text-blue-300">
                    <li>Top performing niches based on views and engagement</li>
                    <li>Growth rate analysis for trending content areas</li>
                    <li>Visual mapping of niche positioning</li>
                    <li>Opportunity score for niche competitiveness</li>
                    <li>Recommended content strategies</li>
                  </ul>

                  <div className="mt-4 p-3 border border-blue-200 rounded bg-blue-100 dark:bg-blue-800 dark:border-blue-700">
                    <div className="flex gap-2 items-center">
                      <svg className="w-5 h-5 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                      </svg>
                      <p className="text-sm text-blue-600 dark:text-blue-300">
                        Estimated time: <strong>3-5 minutes</strong>
                      </p>
                    </div>
                  </div>
                </div>

                <div className="flex justify-between mt-6">
                  <button
                    onClick={back}
                    className="btn-secondary"
                  >
                    Back: Research Parameters
                  </button>
                  <div className="flex gap-3">
                    <button
                      onClick={() => setShowScheduleModal(true)}
                      className="btn-secondary"
                    >
                      SCHEDULE
                    </button>
                    <button
                      onClick={handleRunWorkflow}
                      disabled={isLoading}
                      className="btn-primary"
                    >
                      {isLoading ? 'Running...' : 'RUN ANALYSIS NOW'}
                    </button>
                  </div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>

      {/* Schedule Modal */}
      {showScheduleModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-md w-full">
            <h2 className="text-xl font-bold mb-4">Schedule Workflow</h2>

            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Frequency
              </label>
              <select
                value={frequency}
                onChange={(e) => setFrequency(e.target.value)}
                className="input w-full"
              >
                <option value="daily">Daily</option>
                <option value="weekly">Weekly</option>
                <option value="monthly">Monthly</option>
                <option value="once">Once</option>
              </select>
            </div>

            {frequency === 'once' && (
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Run Date
                </label>
                <input
                  type="datetime-local"
                  value={runDate}
                  onChange={(e) => setRunDate(e.target.value)}
                  className="input w-full"
                />
              </div>
            )}

            <div className="flex justify-end space-x-2">
              <button
                onClick={() => setShowScheduleModal(false)}
                className="btn-secondary"
              >
                Cancel
              </button>
              <button
                onClick={handleScheduleWorkflow}
                className="btn-primary"
              >
                Schedule
              </button>
            </div>
          </div>
        </div>
      )}
    </MainLayout>
  );
}

// Mocked subcategories mapping
const SUBCATEGORIES = {
  "Gaming": ["FPS Games", "RPG Games", "Strategy Games", "Mobile Gaming", "Game Reviews"],
  "Health & Fitness": ["Sleep", "Nutrition", "Mental Health", "Workout Plans", "Yoga"],
  "Education": ["Language Learning", "Exam Prep", "STEM Tutorials", "DIY", "Science"],
  "Finance": ["Budgeting", "Investing", "Crypto", "Personal Finance", "Real Estate"],
  "Entertainment": ["Comedy", "Vlogs", "Reactions", "Shorts", "Storytelling"],
  "Howto & Style": ["Beauty", "Fashion", "Home Decor", "Cooking", "Crafts"],
  "Science & Technology": ["Gadget Reviews", "Coding", "AI & ML", "Engineering", "Science News"]
};
