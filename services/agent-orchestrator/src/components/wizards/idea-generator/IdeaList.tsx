
import React from "react";
import { Lightbulb, Search } from "lucide-react";
import { Input } from "@/components/ui/input";
import { IdeaProps } from "./constants";

interface IdeaListProps {
  ideas: IdeaProps[];
  searchQuery: string;
  selectedIdea: IdeaProps | null;
  onSearchChange: (query: string) => void;
  onSelectIdea: (idea: IdeaProps) => void;
}

export function IdeaList({
  ideas,
  searchQuery,
  selectedIdea,
  onSearchChange,
  onSelectIdea
}: IdeaListProps) {
  const filteredIdeas = ideas.filter(idea => 
    !searchQuery || 
    idea.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
    idea.description.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <>
      <div className="relative">
        <Search className="absolute left-2.5 top-3 h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="Search ideas..."
          className="pl-8"
          value={searchQuery}
          onChange={(e) => onSearchChange(e.target.value)}
        />
      </div>
      <div className="flex items-center mb-1 text-sm text-muted-foreground">
        <span>No ideas yet — run a search</span>
        <Search className="h-4 w-4 ml-1 text-primary" />
      </div>
      <div className="space-y-2 my-4 max-h-[200px] overflow-y-auto">
        {filteredIdeas.map((idea) => (
          <div
            key={idea.title}
            className={`p-3 border rounded-lg cursor-pointer transition-colors flex gap-3 items-center ${
              selectedIdea?.title === idea.title
                ? "border-primary bg-primary/5"
                : "hover:bg-accent"
            }`}
            onClick={() => onSelectIdea(idea)}
          >
            <Lightbulb className={`h-5 w-5 ${
              selectedIdea?.title === idea.title ? "text-primary" : "text-muted-foreground"
            }`} />
            <div>
              <h4 className="font-medium">{idea.title}</h4>
              <p className="text-sm text-muted-foreground">{idea.description}</p>
            </div>
          </div>
        ))}
      </div>
    </>
  );
}
