
import React from "react";
import { FormControl, FormItem, FormField } from "@/components/ui/form";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Button } from "@/components/ui/button";
import { Settings, X } from "lucide-react";
import { Control } from "react-hook-form";

interface CategorySelectorProps {
  control: Control<any>;
  categories: string[];
  currentSubcategories: string[];
  dropdownOpen: string | null;
  toggleDropdown: (name: string) => void;
  onOpenConfig: () => void;
}

export function CategorySelector({
  control,
  categories,
  currentSubcategories,
  dropdownOpen,
  toggleDropdown,
  onOpenConfig
}: CategorySelectorProps) {
  return (
    <>
      <div className="flex justify-between items-center">
        <div className="text-sm font-medium">Category</div>
        <Button 
          variant="ghost" 
          size="sm" 
          className="h-8 w-8 p-0" 
          onClick={onOpenConfig}
        >
          <Settings className="h-4 w-4" />
          <span className="sr-only">Configure categories</span>
        </Button>
        {dropdownOpen === "category" && (
          <Button 
            variant="ghost" 
            size="sm" 
            className="h-6 w-6 p-0" 
            onClick={() => toggleDropdown("category")}
          >
            <X className="h-4 w-4" />
          </Button>
        )}
      </div>
      
      <FormField
        control={control}
        name="category"
        render={({ field }) => (
          <FormItem className="relative">
            <div className="relative">
              <Select 
                onValueChange={(value) => {
                  field.onChange(value);
                  toggleDropdown(null);
                }}
                defaultValue={field.value}
                onOpenChange={() => toggleDropdown("category")}
                open={dropdownOpen === "category"}
              >
                <FormControl>
                  <SelectTrigger>
                    <SelectValue placeholder="Select a category" />
                  </SelectTrigger>
                </FormControl>
                <SelectContent>
                  {categories.map((category) => (
                    <SelectItem key={category} value={category}>
                      {category}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {dropdownOpen === "category" && (
              <div className="absolute z-50 w-full mt-1 bg-popover border rounded-md shadow-md">
                <div className="p-1">
                  {categories.map((category) => (
                    <div 
                      key={category} 
                      className={`flex items-center px-2 py-1.5 text-sm rounded-sm cursor-pointer ${
                        category === field.value ? "bg-accent text-accent-foreground" : "hover:bg-accent/50"
                      }`}
                      onClick={() => {
                        field.onChange(category);
                        toggleDropdown(null);
                      }}
                    >
                      {category === field.value && (
                        <svg className="mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                        </svg>
                      )}
                      {category}
                    </div>
                  ))}
                </div>
              </div>
            )}
          </FormItem>
        )}
      />

      <div className="text-sm font-medium">Sub-category</div>
      <FormField
        control={control}
        name="subcategory"
        render={({ field }) => (
          <FormItem>
            <Select 
              onValueChange={field.onChange} 
              defaultValue={field.value}
              disabled={currentSubcategories.length === 0}
            >
              <FormControl>
                <SelectTrigger>
                  <SelectValue placeholder="Select a subcategory" />
                </SelectTrigger>
              </FormControl>
              <SelectContent>
                {currentSubcategories.map((subcategory) => (
                  <SelectItem key={subcategory} value={subcategory}>
                    {subcategory}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </FormItem>
        )}
      />
    </>
  );
}
