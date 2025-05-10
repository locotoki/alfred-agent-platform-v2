import React, { useState, useEffect } from 'react';
import { 
  Dialog, 
  DialogContent, 
  DialogDescription, 
  DialogHeader, 
  DialogTitle, 
  DialogTrigger 
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Loader2, Youtube } from "lucide-react";

interface YouTubeResultsDialogProps {
  trigger?: React.ReactNode;
}

const YouTubeResultsDialog: React.FC<YouTubeResultsDialogProps> = ({ 
  trigger = <Button variant="outline" size="sm"><Youtube className="mr-2 h-4 w-4" />View Niche Scout Results</Button> 
}) => {
  const [open, setOpen] = useState(false);
  const [results, setResults] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Load results when dialog opens
  useEffect(() => {
    if (open) {
      setLoading(true);
      
      // Try to get results from localStorage if available
      const storedResults = localStorage.getItem('youtube-results');
      if (storedResults) {
        try {
          const parsedResults = JSON.parse(storedResults);
          if (Array.isArray(parsedResults) && parsedResults.length > 0) {
            setResults(parsedResults);
            setLoading(false);
            return;
          }
        } catch (e) {
          console.error('Failed to parse stored results:', e);
        }
      }
      
      // If no stored results, check for console logs
      const checkLogs = () => {
        const originalConsoleLog = console.log;
        let foundResults = [];
        
        // Temporarily replace console.log to check for results
        console.log = function(...args) {
          if ((args[0] === 'Niche scout completed:' || args[0] === 'YouTube API test result:') && args[1]) {
            foundResults.push(args[1]);
          }
          originalConsoleLog.apply(console, args);
        };
        
        // Restore original console.log
        console.log = originalConsoleLog;
        
        return foundResults;
      };
      
      const logResults = checkLogs();
      if (logResults.length > 0) {
        setResults(logResults);
      }
      
      setLoading(false);
    }
  }, [open]);
  
  const renderResultContent = (resultData: any) => {
    if (!resultData) return null;
    
    return (
      <div className="space-y-4">
        <div className="grid grid-cols-2 gap-4 p-4 bg-muted/50 rounded-lg">
          <div>
            <div className="text-sm font-medium text-muted-foreground">Run Date</div>
            <div className="font-medium">{new Date(resultData.run_date).toLocaleString()}</div>
          </div>
          <div>
            <div className="text-sm font-medium text-muted-foreground">Category</div>
            <div className="font-medium">Kids &gt; Nursery Rhymes</div>
          </div>
        </div>
        
        <div>
          <h3 className="text-sm font-medium mb-2">Top Niches</h3>
          <ul className="space-y-1">
            {resultData.top_niches?.slice(0, 5).map((niche: any, index: number) => (
              <li key={index} className="text-sm">
                {niche.query} - Score: {Math.round(niche.score)}
              </li>
            ))}
          </ul>
        </div>
        
        <div>
          <h3 className="text-sm font-medium mb-2">Trending Niches</h3>
          <ul className="space-y-1">
            {resultData.trending_niches?.slice(0, 5).map((niche: any, index: number) => (
              <li key={index} className="text-sm">
                {niche.query} - Views: {niche.view_sum.toLocaleString()}
              </li>
            ))}
          </ul>
        </div>
        
        {resultData.actual_processing_time && (
          <div className="text-sm text-muted-foreground">
            Processing time: {resultData.actual_processing_time.toFixed(2)}s
          </div>
        )}
      </div>
    );
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        {trigger}
      </DialogTrigger>
      <DialogContent className="sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>Niche Scout Results</DialogTitle>
          <DialogDescription>
            View results from your Niche Scout analysis
          </DialogDescription>
        </DialogHeader>
        
        <div className="py-4">
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <Loader2 className="h-8 w-8 animate-spin text-primary" />
              <span className="ml-2">Loading results...</span>
            </div>
          ) : results.length === 0 ? (
            <div className="text-center py-12 text-muted-foreground">
              <p>No Niche Scout results found</p>
              <p className="text-sm mt-2">Run a Niche Scout analysis to see results here</p>
            </div>
          ) : (
            <Tabs defaultValue="latest">
              <TabsList className="mb-4">
                <TabsTrigger value="latest">Latest Result</TabsTrigger>
                <TabsTrigger value="history">Previous Results</TabsTrigger>
              </TabsList>
              
              <TabsContent value="latest">
                {renderResultContent(results[0])}
              </TabsContent>
              
              <TabsContent value="history">
                <div className="space-y-6">
                  {results.slice(1).map((historyResult, idx) => (
                    <div key={idx} className="border p-4 rounded-lg">
                      <h3 className="font-medium mb-2">Result #{idx + 2}</h3>
                      {renderResultContent(historyResult)}
                    </div>
                  ))}
                  
                  {results.length <= 1 && (
                    <div className="text-center py-6 text-muted-foreground">
                      <p>No previous results available</p>
                    </div>
                  )}
                </div>
              </TabsContent>
            </Tabs>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default YouTubeResultsDialog;