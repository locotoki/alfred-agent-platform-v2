
import { useState, useCallback, useMemo } from "react";
import { Category, DataSourceConfig, FinalPayload } from "@/types/niche-scout";
import { DATA_SOURCE_DEFAULTS } from "@/config/dataSources";
import { COST_PER_SOURCE, ETA_BASE_SEC, ETA_PER_1K_SEC, BUDGET_MIN } from "@/config/costRules";

export function useNicheScoutWizard() {
  const [step, setStep] = useState(1);
  const [selectedCategory, setSelectedCategory] = useState<Category | null>(null);
  const [selectedSubcategory, setSelectedSubcategory] = useState<Category | null>(null);
  const [budget, setBudget] = useState<number>(BUDGET_MIN);
  const [dataSources, setDataSources] = useState<DataSourceConfig>(DATA_SOURCE_DEFAULTS);
  const [lastAccuracy, setLastAccuracy] = useState<{ diffCost: number; diffEta: number } | null>(null);

  const resetWizard = () => {
    setStep(1);
    setSelectedCategory(null);
    setSelectedSubcategory(null);
    setBudget(BUDGET_MIN);
    setDataSources(DATA_SOURCE_DEFAULTS);
  };

  const handleCategoryChange = useCallback((category: Category) => {
    setSelectedCategory(category);
    setSelectedSubcategory(null);
  }, []);

  const handleSubcategoryChange = useCallback((subcategory: Category) => {
    setSelectedSubcategory(subcategory);
  }, []);

  const calculateEstimates = useMemo(() => {
    // Count active data sources
    const activeSourcesCount = Object.entries(dataSources).filter(([_, active]) => active).length;
    
    // Calculate cost based on active sources
    let cost = 0;
    Object.entries(dataSources).forEach(([source, active]) => {
      if (active) {
        const sourceKey = source as keyof typeof COST_PER_SOURCE;
        cost += COST_PER_SOURCE[sourceKey];
      }
    });
    
    // Scale cost based on budget
    const scaledCost = cost * (budget / 100);
    
    // Calculate estimated time
    const baseTime = ETA_BASE_SEC;
    const scaledTime = (budget / 100) * ETA_PER_1K_SEC;
    const totalTime = baseTime + scaledTime * activeSourcesCount;
    
    return {
      estimatedCost: scaledCost,
      estimatedTime: totalTime
    };
  }, [dataSources, budget]);

  return {
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
  };
}
