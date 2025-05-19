
import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useForm } from "react-hook-form";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { CategoryConfiguration } from "./idea-generator/CategoryConfiguration";
import { GeneratorForm } from "./idea-generator/GeneratorForm";
import { IdeaList } from "./idea-generator/IdeaList";
import {
  DEFAULT_CATEGORIES,
  DEFAULT_SUBCATEGORIES,
  IDEAS,
  IdeaProps
} from "./idea-generator/constants";

interface IdeaGeneratorWizardProps {
  trigger: React.ReactNode;
  onAdopt: (idea: IdeaProps) => void;
}

interface FormValues {
  category: string;
  subcategory: string;
  language: string;
  credits: number;
  searchQuery: string;
}

export function IdeaGeneratorWizard({ trigger, onAdopt }: IdeaGeneratorWizardProps) {
  const [open, setOpen] = useState(false);
  const [selectedIdea, setSelectedIdea] = useState<IdeaProps | null>(null);
  const [generatedIdeas, setGeneratedIdeas] = useState<IdeaProps[]>([]);
  const [isGenerating, setIsGenerating] = useState(false);
  const [dropdownOpen, setDropdownOpen] = useState<string | null>(null);
  const [configOpen, setConfigOpen] = useState(false);
  const [categories, setCategories] = useState<string[]>(DEFAULT_CATEGORIES);
  const [subcategories, setSubcategories] = useState<Record<string, string[]>>(DEFAULT_SUBCATEGORIES);

  const form = useForm<FormValues>({
    defaultValues: {
      category: "Social Media",
      subcategory: "Instagram",
      language: "English",
      credits: 50,
      searchQuery: ""
    }
  });

  const selectedCategory = form.watch("category");
  const currentSubcategories = selectedCategory ? subcategories[selectedCategory] || [] : [];
  const searchQuery = form.watch("searchQuery");

  useEffect(() => {
    // Reset subcategory when category changes
    if (currentSubcategories.length > 0) {
      form.setValue("subcategory", currentSubcategories[0]);
    }
  }, [selectedCategory, form, currentSubcategories]);

  const handleGenerateIdeas = () => {
    setIsGenerating(true);
    // Simulate API call delay
    setTimeout(() => {
      setGeneratedIdeas(IDEAS);
      setIsGenerating(false);
    }, 1000);
  };

  const handleAdopt = () => {
    if (selectedIdea) {
      onAdopt(selectedIdea);
      setOpen(false);
      setSelectedIdea(null);
      setGeneratedIdeas([]);
      form.reset();
    }
  };

  const toggleDropdown = (name: string) => {
    if (dropdownOpen === name) {
      setDropdownOpen(null);
    } else {
      setDropdownOpen(name);
    }
  };

  const handleAddCategory = (category: string) => {
    if (category && !categories.includes(category)) {
      setCategories([...categories, category]);
      setSubcategories({
        ...subcategories,
        [category]: []
      });
    }
  };

  const handleAddSubcategory = (category: string, subcategory: string) => {
    if (category && subcategory && !subcategories[category]?.includes(subcategory)) {
      setSubcategories({
        ...subcategories,
        [category]: [...(subcategories[category] || []), subcategory]
      });
    }
  };

  const handleDeleteCategory = (category: string) => {
    const updatedCategories = categories.filter(c => c !== category);
    const { [category]: _, ...rest } = subcategories;
    setCategories(updatedCategories);
    setSubcategories(rest);
    if (form.getValues("category") === category) {
      form.setValue("category", updatedCategories[0] || "");
      form.setValue("subcategory", rest[updatedCategories[0]]?.[0] || "");
    }
  };

  const handleDeleteSubcategory = (category: string, subcategory: string) => {
    const updatedSubcategories = {
      ...subcategories,
      [category]: subcategories[category].filter(s => s !== subcategory)
    };
    setSubcategories(updatedSubcategories);
    if (form.getValues("category") === category && form.getValues("subcategory") === subcategory) {
      form.setValue("subcategory", updatedSubcategories[category][0] || "");
    }
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <div onClick={() => setOpen(true)}>
        {trigger}
      </div>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="text-xl">Idea Generator</DialogTitle>
          <DialogDescription>
            Configure options and generate title ideas for your workflow
          </DialogDescription>
        </DialogHeader>

        <div className="py-4">
          <form>
            <GeneratorForm
              control={form.control}
              categories={categories}
              currentSubcategories={currentSubcategories}
              dropdownOpen={dropdownOpen}
              isGenerating={isGenerating}
              toggleDropdown={toggleDropdown}
              onOpenConfig={() => setConfigOpen(true)}
              onGenerate={handleGenerateIdeas}
            />
          </form>
        </div>

        {generatedIdeas.length > 0 && (
          <IdeaList
            ideas={generatedIdeas}
            searchQuery={searchQuery}
            selectedIdea={selectedIdea}
            onSearchChange={(query) => form.setValue("searchQuery", query)}
            onSelectIdea={setSelectedIdea}
          />
        )}

        <DialogFooter>
          <Button
            variant="outline"
            onClick={() => {
              setOpen(false);
              setSelectedIdea(null);
              setGeneratedIdeas([]);
              form.reset();
            }}
          >
            Cancel
          </Button>
          <Button
            onClick={handleAdopt}
            disabled={!selectedIdea || isGenerating}
          >
            Use This Title
          </Button>
        </DialogFooter>

        <Popover open={configOpen} onOpenChange={setConfigOpen}>
          <PopoverTrigger className="hidden">
            {/* Hidden trigger, we control open state programmatically */}
          </PopoverTrigger>
          <PopoverContent className="w-80 p-4" align="end">
            <CategoryConfiguration
              categories={categories}
              subcategories={subcategories}
              onAddCategory={handleAddCategory}
              onAddSubcategory={handleAddSubcategory}
              onDeleteCategory={handleDeleteCategory}
              onDeleteSubcategory={handleDeleteSubcategory}
            />
          </PopoverContent>
        </Popover>
      </DialogContent>
    </Dialog>
  );
}
