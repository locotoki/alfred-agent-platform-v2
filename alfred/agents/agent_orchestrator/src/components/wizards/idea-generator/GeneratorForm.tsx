
import React from "react";
import { Button } from "@/components/ui/button";
import { FormField, FormItem, FormLabel, FormControl } from "@/components/ui/form";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Slider } from "@/components/ui/slider";
import { Control } from "react-hook-form";
import { CategorySelector } from "./CategorySelector";
import { LANGUAGES } from "./constants";

interface GeneratorFormProps {
  control: Control<any>;
  categories: string[];
  currentSubcategories: string[];
  dropdownOpen: string | null;
  isGenerating: boolean;
  toggleDropdown: (name: string) => void;
  onOpenConfig: () => void;
  onGenerate: () => void;
}

export function GeneratorForm({
  control,
  categories,
  currentSubcategories,
  dropdownOpen,
  isGenerating,
  toggleDropdown,
  onOpenConfig,
  onGenerate
}: GeneratorFormProps) {
  return (
    <div className="space-y-4">
      <CategorySelector
        control={control}
        categories={categories}
        currentSubcategories={currentSubcategories}
        dropdownOpen={dropdownOpen}
        toggleDropdown={toggleDropdown}
        onOpenConfig={onOpenConfig}
      />

      <div className="grid grid-cols-2 gap-2">
        <FormField
          control={control}
          name="language"
          render={({ field }) => (
            <FormItem>
              <Select
                onValueChange={field.onChange}
                defaultValue={field.value}
              >
                <FormControl>
                  <SelectTrigger>
                    <SelectValue placeholder="Select language" />
                  </SelectTrigger>
                </FormControl>
                <SelectContent>
                  {LANGUAGES.map((language) => (
                    <SelectItem key={language} value={language}>
                      {language}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </FormItem>
          )}
        />
      </div>

      <FormField
        control={control}
        name="credits"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Discovery Budget (credits) — {field.value}</FormLabel>
            <FormControl>
              <Slider
                defaultValue={[field.value]}
                min={10}
                max={100}
                step={10}
                onValueChange={(values) => field.onChange(values[0])}
                className="py-4"
              />
            </FormControl>
          </FormItem>
        )}
      />

      <Button
        type="button"
        onClick={onGenerate}
        className="w-full"
        disabled={isGenerating}
      >
        {isGenerating ? "Generating Ideas..." : "Generate Ideas"}
      </Button>
    </div>
  );
}
