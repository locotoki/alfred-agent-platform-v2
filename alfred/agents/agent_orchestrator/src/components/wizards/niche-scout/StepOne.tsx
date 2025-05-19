
import React from "react";
import { Category } from "@/types/niche-scout";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

interface StepOneProps {
  categories: Category[];
  selectedCategory: Category | null;
  onCategoryChange: (category: Category) => void;
}

export const StepOne: React.FC<StepOneProps> = ({
  categories,
  selectedCategory,
  onCategoryChange,
}) => {
  return (
    <div className="space-y-4">
      <div className="space-y-2">
        <h2 className="text-xl font-semibold">Select a Category</h2>
        <p className="text-sm text-muted-foreground">
          Choose the main category for your niche research
        </p>
      </div>

      <Select
        value={selectedCategory?.value ?? ""}
        onValueChange={(value) => {
          const category = categories.find((cat) => cat.value === value);
          if (category) {
            onCategoryChange(category);
          }
        }}
      >
        <SelectTrigger className="w-full">
          <SelectValue placeholder="Select a category" />
        </SelectTrigger>
        <SelectContent>
          {categories.map((category) => (
            <SelectItem key={category.value} value={category.value}>
              {category.label}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  );
};
