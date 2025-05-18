
import React, { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Trash2, Plus } from "lucide-react";

interface CategoryConfigurationProps {
  categories: string[];
  subcategories: Record<string, string[]>;
  onAddCategory: (category: string) => void;
  onAddSubcategory: (category: string, subcategory: string) => void;
  onDeleteCategory: (category: string) => void;
  onDeleteSubcategory: (category: string, subcategory: string) => void;
}

export function CategoryConfiguration({
  categories,
  subcategories,
  onAddCategory,
  onAddSubcategory,
  onDeleteCategory,
  onDeleteSubcategory
}: CategoryConfigurationProps) {
  const [newCategory, setNewCategory] = useState("");
  const [newSubcategory, setNewSubcategory] = useState("");
  const [selectedConfigCategory, setSelectedConfigCategory] = useState<string | null>(null);

  const handleAddCategory = () => {
    if (newCategory && !categories.includes(newCategory)) {
      onAddCategory(newCategory);
      setSelectedConfigCategory(newCategory);
      setNewCategory("");
    }
  };

  const handleAddSubcategory = () => {
    if (selectedConfigCategory && newSubcategory && !subcategories[selectedConfigCategory]?.includes(newSubcategory)) {
      onAddSubcategory(selectedConfigCategory, newSubcategory);
      setNewSubcategory("");
    }
  };

  return (
    <div className="space-y-4">
      <h3 className="font-medium">Customize Categories</h3>
      <div className="space-y-2">
        <div className="flex items-center space-x-2">
          <Input
            placeholder="New category"
            value={newCategory}
            onChange={(e) => setNewCategory(e.target.value)}
            className="h-8"
          />
          <Button
            size="sm"
            className="h-8"
            onClick={handleAddCategory}
            disabled={!newCategory || categories.includes(newCategory)}
          >
            <Plus className="h-3 w-3 mr-1" />
            Add
          </Button>
        </div>
      </div>

      <div className="space-y-2 max-h-48 overflow-y-auto border rounded-md p-2">
        {categories.map((category) => (
          <div
            key={category}
            className={`flex items-center justify-between p-2 text-sm rounded-md cursor-pointer ${
              selectedConfigCategory === category
                ? "bg-accent"
                : "hover:bg-accent/50"
            }`}
            onClick={() => setSelectedConfigCategory(category)}
          >
            <span>{category}</span>
            <Button
              variant="ghost"
              size="sm"
              className="h-6 w-6 p-0"
              onClick={(e) => {
                e.stopPropagation();
                onDeleteCategory(category);
              }}
            >
              <Trash2 className="h-3 w-3 text-destructive" />
            </Button>
          </div>
        ))}
      </div>

      {selectedConfigCategory && (
        <>
          <h3 className="font-medium">Subcategories for {selectedConfigCategory}</h3>
          <div className="flex items-center space-x-2">
            <Input
              placeholder="New subcategory"
              value={newSubcategory}
              onChange={(e) => setNewSubcategory(e.target.value)}
              className="h-8"
            />
            <Button
              size="sm"
              className="h-8"
              onClick={handleAddSubcategory}
              disabled={!newSubcategory || subcategories[selectedConfigCategory]?.includes(newSubcategory)}
            >
              <Plus className="h-3 w-3 mr-1" />
              Add
            </Button>
          </div>
          <div className="space-y-1 max-h-48 overflow-y-auto border rounded-md p-2">
            {subcategories[selectedConfigCategory]?.map((sub) => (
              <div
                key={sub}
                className="flex items-center justify-between p-1.5 text-sm rounded-md hover:bg-accent/50"
              >
                <span>{sub}</span>
                <Button
                  variant="ghost"
                  size="sm"
                  className="h-6 w-6 p-0"
                  onClick={() => onDeleteSubcategory(selectedConfigCategory, sub)}
                >
                  <Trash2 className="h-3 w-3 text-destructive" />
                </Button>
              </div>
            ))}
            {subcategories[selectedConfigCategory]?.length === 0 && (
              <div className="p-2 text-sm text-muted-foreground">
                No subcategories yet. Add some above.
              </div>
            )}
          </div>
        </>
      )}
    </div>
  );
}
