
import React, { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { X, Plus, Save } from "lucide-react";
import { categories as defaultCategories, subcategoryMap as defaultSubcategoryMap } from "@/config/taxonomy";
import { COST_PER_SOURCE as defaultCostRules, BUDGET_MIN as defaultBudgetMin, BUDGET_MAX as defaultBudgetMax, ETA_BASE_SEC as defaultEtaBase, ETA_PER_1K_SEC as defaultEtaPer1k } from "@/config/costRules";
import { Category } from "@/types/niche-scout";
import { Label } from "@/components/ui/label";

const TaxonomySettings: React.FC = () => {
  const [categories, setCategories] = useState<Category[]>(defaultCategories);
  const [subcategoryMap, setSubcategoryMap] = useState<Record<string, Category[]>>(defaultSubcategoryMap);
  const [costRules, setCostRules] = useState({
    youtube: defaultCostRules.youtube,
    reddit: defaultCostRules.reddit,
    amazon: defaultCostRules.amazon,
    sentiment: defaultCostRules.sentiment,
  });
  const [etaBase, setEtaBase] = useState(defaultEtaBase);
  const [etaPer1k, setEtaPer1k] = useState(defaultEtaPer1k);
  const [budgetMin, setBudgetMin] = useState(defaultBudgetMin);
  const [budgetMax, setBudgetMax] = useState(defaultBudgetMax);
  const [activeCategory, setActiveCategory] = useState<string | null>(categories[0]?.value || null);

  // Handle category operations
  const addCategory = () => {
    const newValue = `category-${Date.now()}`;
    const newCategory = { label: "New Category", value: newValue };
    setCategories([...categories, newCategory]);
    setSubcategoryMap({
      ...subcategoryMap,
      [newValue]: []
    });
    setActiveCategory(newValue);
  };

  const updateCategory = (index: number, field: keyof Category, value: string) => {
    const updatedCategories = [...categories];
    const oldValue = updatedCategories[index].value;
    
    // Update the category
    updatedCategories[index] = { 
      ...updatedCategories[index], 
      [field]: value 
    };
    
    // If value field is updated, we need to update subcategoryMap keys
    if (field === 'value' && oldValue !== value) {
      const subcategories = subcategoryMap[oldValue] || [];
      const newSubcategoryMap = { ...subcategoryMap };
      delete newSubcategoryMap[oldValue];
      newSubcategoryMap[value] = subcategories;
      setSubcategoryMap(newSubcategoryMap);
      
      if (activeCategory === oldValue) {
        setActiveCategory(value);
      }
    }
    
    setCategories(updatedCategories);
  };

  const removeCategory = (index: number) => {
    const categoryToRemove = categories[index];
    const updatedCategories = categories.filter((_, i) => i !== index);
    const updatedSubcategoryMap = { ...subcategoryMap };
    delete updatedSubcategoryMap[categoryToRemove.value];
    
    setCategories(updatedCategories);
    setSubcategoryMap(updatedSubcategoryMap);
    
    if (activeCategory === categoryToRemove.value) {
      setActiveCategory(updatedCategories[0]?.value || null);
    }
  };

  // Handle subcategory operations
  const addSubcategory = (categoryValue: string) => {
    if (!categoryValue) return;
    
    const newValue = `${categoryValue}.sub-${Date.now()}`;
    const newSubcategory = { label: "New Subcategory", value: newValue };
    const updatedSubcategories = [...(subcategoryMap[categoryValue] || []), newSubcategory];
    
    setSubcategoryMap({
      ...subcategoryMap,
      [categoryValue]: updatedSubcategories
    });
  };

  const updateSubcategory = (categoryValue: string, index: number, field: keyof Category, value: string) => {
    if (!categoryValue) return;
    
    const updatedSubcategories = [...(subcategoryMap[categoryValue] || [])];
    updatedSubcategories[index] = { 
      ...updatedSubcategories[index], 
      [field]: value 
    };
    
    setSubcategoryMap({
      ...subcategoryMap,
      [categoryValue]: updatedSubcategories
    });
  };

  const removeSubcategory = (categoryValue: string, index: number) => {
    if (!categoryValue) return;
    
    const updatedSubcategories = (subcategoryMap[categoryValue] || []).filter((_, i) => i !== index);
    
    setSubcategoryMap({
      ...subcategoryMap,
      [categoryValue]: updatedSubcategories
    });
  };

  // Handle cost rule changes
  const updateCostRule = (key: keyof typeof costRules, value: string) => {
    const numValue = parseFloat(value) || 0;
    setCostRules({
      ...costRules,
      [key]: numValue
    });
  };

  const handleSave = () => {
    // In a real app, this would save to database or update the config files
    console.log("Saving taxonomy and cost rules:", {
      categories,
      subcategoryMap,
      costRules,
      etaBase,
      etaPer1k,
      budgetMin,
      budgetMax
    });

    // Show a success toast
    alert("Settings saved successfully!");
  };

  return (
    <div className="container py-8 space-y-8">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">Taxonomy & Cost Settings</h1>
        <Button onClick={handleSave}>
          <Save className="mr-2 h-4 w-4" />
          Save Changes
        </Button>
      </div>
      
      <Tabs defaultValue="categories" className="space-y-6">
        <TabsList>
          <TabsTrigger value="categories">Categories & Subcategories</TabsTrigger>
          <TabsTrigger value="costs">Cost Rules</TabsTrigger>
        </TabsList>
        
        <TabsContent value="categories" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Categories</CardTitle>
              <CardDescription>Manage the main categories for niche analysis</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {categories.map((category, index) => (
                  <div key={index} className="flex items-center gap-2">
                    <Input
                      value={category.label}
                      onChange={(e) => updateCategory(index, 'label', e.target.value)}
                      placeholder="Category Label"
                    />
                    <Input
                      value={category.value}
                      onChange={(e) => updateCategory(index, 'value', e.target.value)}
                      placeholder="Category Value"
                      className="max-w-[200px]"
                    />
                    <Button
                      variant="ghost" 
                      size="icon"
                      onClick={() => removeCategory(index)}
                    >
                      <X className="h-4 w-4" />
                    </Button>
                  </div>
                ))}
                
                <Button variant="outline" onClick={addCategory}>
                  <Plus className="mr-2 h-4 w-4" />
                  Add Category
                </Button>
              </div>
            </CardContent>
          </Card>
          
          {activeCategory && (
            <Card>
              <CardHeader>
                <CardTitle>Subcategories for {categories.find(c => c.value === activeCategory)?.label || activeCategory}</CardTitle>
                <CardDescription>Manage subcategories for the selected category</CardDescription>
                
                <div className="mt-2">
                  <Label>Active Category</Label>
                  <div className="grid grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-2 mt-2">
                    {categories.map((category) => (
                      <Button
                        key={category.value}
                        variant={activeCategory === category.value ? "default" : "outline"}
                        size="sm"
                        onClick={() => setActiveCategory(category.value)}
                        className="text-xs h-8"
                      >
                        {category.label}
                      </Button>
                    ))}
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {(subcategoryMap[activeCategory] || []).map((subcategory, index) => (
                    <div key={index} className="flex items-center gap-2">
                      <Input
                        value={subcategory.label}
                        onChange={(e) => updateSubcategory(activeCategory, index, 'label', e.target.value)}
                        placeholder="Subcategory Label"
                      />
                      <Input
                        value={subcategory.value}
                        onChange={(e) => updateSubcategory(activeCategory, index, 'value', e.target.value)}
                        placeholder="Subcategory Value"
                        className="max-w-[200px]"
                      />
                      <Button
                        variant="ghost" 
                        size="icon"
                        onClick={() => removeSubcategory(activeCategory, index)}
                      >
                        <X className="h-4 w-4" />
                      </Button>
                    </div>
                  ))}
                  
                  <Button variant="outline" onClick={() => addSubcategory(activeCategory)}>
                    <Plus className="mr-2 h-4 w-4" />
                    Add Subcategory
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}
        </TabsContent>
        
        <TabsContent value="costs">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>Cost Per Data Source</CardTitle>
                <CardDescription>Cost per 1000 items for each data source</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {Object.entries(costRules).map(([key, value]) => (
                  <div key={key} className="grid grid-cols-2 items-center gap-4">
                    <Label className="text-right capitalize">{key}</Label>
                    <div className="flex items-center">
                      <span className="mr-2">$</span>
                      <Input
                        type="number"
                        step="0.01"
                        min="0"
                        value={value}
                        onChange={(e) => updateCostRule(key as keyof typeof costRules, e.target.value)}
                      />
                    </div>
                  </div>
                ))}
              </CardContent>
            </Card>
            
            <Card>
              <CardHeader>
                <CardTitle>Time & Budget Settings</CardTitle>
                <CardDescription>Configure ETA calculations and budget limits</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 items-center gap-4">
                  <Label className="text-right">Base ETA (seconds)</Label>
                  <Input
                    type="number"
                    min="0"
                    value={etaBase}
                    onChange={(e) => setEtaBase(parseInt(e.target.value) || 0)}
                  />
                </div>
                
                <div className="grid grid-cols-2 items-center gap-4">
                  <Label className="text-right">ETA per 1k items (seconds)</Label>
                  <Input
                    type="number"
                    min="0"
                    value={etaPer1k}
                    onChange={(e) => setEtaPer1k(parseInt(e.target.value) || 0)}
                  />
                </div>
                
                <div className="grid grid-cols-2 items-center gap-4">
                  <Label className="text-right">Minimum Budget ($)</Label>
                  <Input
                    type="number"
                    min="0"
                    value={budgetMin}
                    onChange={(e) => setBudgetMin(parseInt(e.target.value) || 0)}
                  />
                </div>
                
                <div className="grid grid-cols-2 items-center gap-4">
                  <Label className="text-right">Maximum Budget ($)</Label>
                  <Input
                    type="number"
                    min="0"
                    value={budgetMax}
                    onChange={(e) => setBudgetMax(parseInt(e.target.value) || 0)}
                  />
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
};

export default TaxonomySettings;
