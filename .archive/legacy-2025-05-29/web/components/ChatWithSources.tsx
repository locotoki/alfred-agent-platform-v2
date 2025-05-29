import { useState } from "react";

export function ChatWithSources() {
  const [showSources, setShowSources] = useState(false);
  const sources = [
    { title: "Platform ADR", url: "https://example.com/adr" },
    { title: "Agent Schema", url: "https://example.com/schema" }
  ];

  return (
    <div className="rounded-xl border p-4 space-y-2 bg-white">
      <div className="text-sm">Here's your answer: the platform uses modular agents...</div>
      <button
        className="text-xs text-blue-500 underline"
        onClick={() => setShowSources(!showSources)}
      >
        {showSources ? "Hide sources" : "Show sources"}
      </button>
      {showSources && (
        <ul className="text-xs list-disc list-inside text-gray-700">
          {sources.map((src, i) => (
            <li key={i}>
              <a href={src.url} className="hover:underline" target="_blank">{src.title}</a>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
