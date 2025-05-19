
import React from "react";
import { Category } from "@/types/niche-scout";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

interface StepTwoProps {
  subcategories: Category[];
  selectedSubcategory: Category | null;
  onSubcategoryChange: (subcategory: Category) => void;
}

export const StepTwo: React.FC<StepTwoProps> = ({
  subcategories,
  selectedSubcategory,
  onSubcategoryChange,
}) => {
  return (
    <div className="space-y-4">
      <div className="space-y-2">
        <h2 className="text-xl font-semibold">Select a Subcategory</h2>
        <p className="text-sm text-muted-foreground">
          Narrow down your research focus with a specific subcategory
        </p>
      </div>

      <Select
        value={selectedSubcategory?.value ?? ""}
        onValueChange={(value) => {
          const subcategory = subcategories.find((sub) => sub.value === value);
          if (subcategory) {
            onSubcategoryChange(subcategory);
          }
        }}
      >
        <SelectTrigger className="w-full">
          <SelectValue placeholder="Select a subcategory" />
        </SelectTrigger>
        <SelectContent>
          {subcategories.map((subcategory) => (
            <SelectItem key={subcategory.value} value={subcategory.value}>
              {subcategory.label}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  );
};
