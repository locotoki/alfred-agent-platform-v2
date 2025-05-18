import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Plus } from "lucide-react";
import { NicheScoutWizard } from "./NicheScoutWizard";
import { GradientButton } from "../ui/buttons/GradientButton";
import { FinalPayload } from "@/types/niche-scout";

const GlobalNicheScoutWizard = () => {
  const [showWizard, setShowWizard] = useState(false);
  const navigate = useNavigate();

  const handleComplete = (payload: FinalPayload & { actualCost?: number; actualEta?: number }) => {
    console.log("Niche Scout completed with:", payload);

    // Navigate to results page when available, for now log to console
    navigate("/youtube-results");
  };

  return (
    <NicheScoutWizard
      open={showWizard}
      onOpenChange={setShowWizard}
      onComplete={handleComplete}
      trigger={
        <div className="fixed bottom-6 right-6 z-50">
          <GradientButton
            variant="primary"
            size="lg"
            onClick={() => setShowWizard(true)}
            className="rounded-full shadow-lg"
            iconBefore={<Plus className="h-5 w-5 mr-1" />}
          >
            Niche Scout
          </GradientButton>
        </div>
      }
    />
  );
};

export default GlobalNicheScoutWizard;
