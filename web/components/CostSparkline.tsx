import useSWR from "swr";
import Sparkline from "@uiw/react-sparkline"; // assume installed
const fetcher = (url: string) => fetch(url).then(r => r.json());
export default function CostSparkline() {
  const { data } = useSWR("/costs", fetcher, { refreshInterval: 60_000 });
  if (!data) return null;
  const points = data.map((d: any) => d.llm_usd + d.ci_minutes/60);
  return (
    <div className="border p-2">
      <h4 className="text-sm">30-day cost (LLM$+CIh)</h4>
      <Sparkline data={points} style={{ width: 200, height: 40 }} />
    </div>
  );
}