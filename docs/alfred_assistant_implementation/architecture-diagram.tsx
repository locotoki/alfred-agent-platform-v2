import React from 'react';

const AlfredAssistantArchitecture = () => {
  return (
    <div className="w-full bg-white p-8">
      <h1 className="text-3xl font-bold text-center mb-8">Batman's Alfred AI Assistant - Complete Architecture</h1>

      <svg viewBox="0 0 1800 1400" className="w-full max-w-7xl mx-auto">
        {/* Background layers */}
        <rect x="20" y="20" width="1760" height="200" fill="#e3f2fd" rx="10" />
        <rect x="20" y="240" width="1760" height="200" fill="#f3e5f5" rx="10" />
        <rect x="20" y="460" width="1760" height="300" fill="#e8f5e9" rx="10" />
        <rect x="20" y="780" width="1760" height="200" fill="#fff3e0" rx="10" />
        <rect x="20" y="1000" width="1760" height="300" fill="#fce4ec" rx="10" />

        {/* Layer labels */}
        <text x="30" y="50" fontSize="20" fontWeight="bold" fill="#1565c0">User Interface Layer</text>
        <text x="30" y="270" fontSize="20" fontWeight="bold" fill="#7b1fa2">Master Controller</text>
        <text x="30" y="490" fontSize="20" fontWeight="bold" fill="#2e7d32">Specialized Agents</text>
        <text x="30" y="810" fontSize="20" fontWeight="bold" fill="#ef6c00">Core Services</text>
        <text x="30" y="1030" fontSize="20" fontWeight="bold" fill="#c2185b">Data & Infrastructure</text>

        {/* User Interface Components */}
        <rect x="200" y="80" width="200" height="80" fill="#1976d2" rx="10" />
        <text x="300" y="110" fontSize="16" fill="white" textAnchor="middle">Slack Interface</text>
        <text x="300" y="130" fontSize="14" fill="white" textAnchor="middle">/alfred commands</text>
        <text x="300" y="150" fontSize="12" fill="white" textAnchor="middle">Port: 8011</text>

        <rect x="450" y="80" width="200" height="80" fill="#1976d2" rx="10" />
        <text x="550" y="110" fontSize="16" fill="white" textAnchor="middle">Voice Interface</text>
        <text x="550" y="130" fontSize="14" fill="white" textAnchor="middle">Speech Recognition</text>
        <text x="550" y="150" fontSize="12" fill="white" textAnchor="middle">Port: 8013</text>

        <rect x="700" y="80" width="200" height="80" fill="#1976d2" rx="10" />
        <text x="800" y="110" fontSize="16" fill="white" textAnchor="middle">Mobile App</text>
        <text x="800" y="130" fontSize="14" fill="white" textAnchor="middle">iOS/Android</text>
        <text x="800" y="150" fontSize="12" fill="white" textAnchor="middle">Port: 8014</text>

        <rect x="950" y="80" width="200" height="80" fill="#1976d2" rx="10" />
        <text x="1050" y="110" fontSize="16" fill="white" textAnchor="middle">WhatsApp</text>
        <text x="1050" y="130" fontSize="14" fill="white" textAnchor="middle">Twilio Integration</text>
        <text x="1050" y="150" fontSize="12" fill="white" textAnchor="middle">Webhook</text>

        <rect x="1200" y="80" width="200" height="80" fill="#1976d2" rx="10" />
        <text x="1300" y="110" fontSize="16" fill="white" textAnchor="middle">Web Dashboard</text>
        <text x="1300" y="130" fontSize="14" fill="white" textAnchor="middle">Family Control</text>
        <text x="1300" y="150" fontSize="12" fill="white" textAnchor="middle">Port: 3004</text>

        <rect x="1450" y="80" width="200" height="80" fill="#1976d2" rx="10" />
        <text x="1550" y="110" fontSize="16" fill="white" textAnchor="middle">Smart Home</text>
        <text x="1550" y="130" fontSize="14" fill="white" textAnchor="middle">IoT Integration</text>
        <text x="1550" y="150" fontSize="12" fill="white" textAnchor="middle">MQTT</text>

        {/* Master Alfred Controller */}
        <rect x="400" y="280" width="1000" height="120" fill="#8e24aa" rx="10" stroke="#4a148c" strokeWidth="3" />
        <text x="900" y="310" fontSize="24" fill="white" textAnchor="middle" fontWeight="bold">Master Alfred Orchestrator</text>
        <text x="900" y="340" fontSize="18" fill="white" textAnchor="middle">Central Intelligence & Personality Engine</text>
        <text x="900" y="365" fontSize="16" fill="white" textAnchor="middle">Port: 8012</text>

        {/* Master Alfred Components */}
        <rect x="440" y="320" width="120" height="60" fill="#ab47bc" rx="5" />
        <text x="500" y="355" fontSize="12" fill="white" textAnchor="middle">Personality</text>

        <rect x="580" y="320" width="120" height="60" fill="#ab47bc" rx="5" />
        <text x="640" y="355" fontSize="12" fill="white" textAnchor="middle">Context</text>

        <rect x="720" y="320" width="120" height="60" fill="#ab47bc" rx="5" />
        <text x="780" y="355" fontSize="12" fill="white" textAnchor="middle">Family</text>

        <rect x="860" y="320" width="120" height="60" fill="#ab47bc" rx="5" />
        <text x="920" y="355" fontSize="12" fill="white" textAnchor="middle">Proactive</text>

        <rect x="1000" y="320" width="120" height="60" fill="#ab47bc" rx="5" />
        <text x="1060" y="355" fontSize="12" fill="white" textAnchor="middle">Security</text>

        <rect x="1140" y="320" width="120" height="60" fill="#ab47bc" rx="5" />
        <text x="1200" y="355" fontSize="12" fill="white" textAnchor="middle">Router</text>

        {/* Specialized Agents */}
        <rect x="100" y="520" width="200" height="100" fill="#388e3c" rx="10" />
        <text x="200" y="550" fontSize="16" fill="white" textAnchor="middle">social-intel</text>
        <text x="200" y="570" fontSize="14" fill="white" textAnchor="middle">Social Intelligence</text>
        <text x="200" y="590" fontSize="12" fill="white" textAnchor="middle">Port: 9000</text>
        <text x="200" y="610" fontSize="10" fill="white" textAnchor="middle">[Existing]</text>

        <rect x="350" y="520" width="200" height="100" fill="#388e3c" rx="10" />
        <text x="450" y="550" fontSize="16" fill="white" textAnchor="middle">legal-compliance</text>
        <text x="450" y="570" fontSize="14" fill="white" textAnchor="middle">Legal Agent</text>
        <text x="450" y="590" fontSize="12" fill="white" textAnchor="middle">Port: 9002</text>
        <text x="450" y="610" fontSize="10" fill="white" textAnchor="middle">[Existing]</text>

        <rect x="600" y="520" width="200" height="100" fill="#388e3c" rx="10" />
        <text x="700" y="550" fontSize="16" fill="white" textAnchor="middle">financial-tax</text>
        <text x="700" y="570" fontSize="14" fill="white" textAnchor="middle">Financial Agent</text>
        <text x="700" y="590" fontSize="12" fill="white" textAnchor="middle">Port: 9003</text>
        <text x="700" y="610" fontSize="10" fill="white" textAnchor="middle">[Existing]</text>

        <rect x="850" y="520" width="200" height="100" fill="#4caf50" rx="10" stroke="#2e7d32" strokeWidth="2" />
        <text x="950" y="550" fontSize="16" fill="white" textAnchor="middle">household-manager</text>
        <text x="950" y="570" fontSize="14" fill="white" textAnchor="middle">Home Management</text>
        <text x="950" y="590" fontSize="12" fill="white" textAnchor="middle">Port: 9004</text>
        <text x="950" y="610" fontSize="10" fill="white" textAnchor="middle">[NEW]</text>

        <rect x="1100" y="520" width="200" height="100" fill="#4caf50" rx="10" stroke="#2e7d32" strokeWidth="2" />
        <text x="1200" y="550" fontSize="16" fill="white" textAnchor="middle">family-coordinator</text>
        <text x="1200" y="570" fontSize="14" fill="white" textAnchor="middle">Family Scheduling</text>
        <text x="1200" y="590" fontSize="12" fill="white" textAnchor="middle">Port: 9005</text>
        <text x="1200" y="610" fontSize="10" fill="white" textAnchor="middle">[NEW]</text>

        <rect x="1350" y="520" width="200" height="100" fill="#4caf50" rx="10" stroke="#2e7d32" strokeWidth="2" />
        <text x="1450" y="550" fontSize="16" fill="white" textAnchor="middle">security-agent</text>
        <text x="1450" y="570" fontSize="14" fill="white" textAnchor="middle">Security Monitor</text>
        <text x="1450" y="590" fontSize="12" fill="white" textAnchor="middle">Port: 9006</text>
        <text x="1450" y="610" fontSize="10" fill="white" textAnchor="middle">[NEW]</text>

        <rect x="1600" y="520" width="200" height="100" fill="#4caf50" rx="10" stroke="#2e7d32" strokeWidth="2" />
        <text x="1700" y="550" fontSize="16" fill="white" textAnchor="middle">business-ops</text>
        <text x="1700" y="570" fontSize="14" fill="white" textAnchor="middle">Business Assistant</text>
        <text x="1700" y="590" fontSize="12" fill="white" textAnchor="middle">Port: 9007</text>
        <text x="1700" y="610" fontSize="10" fill="white" textAnchor="middle">[NEW]</text>

        {/* Enhanced Capabilities */}
        <rect x="100" y="640" width="300" height="100" fill="#81c784" rx="10" />
        <text x="250" y="670" fontSize="16" fill="#1b5e20" textAnchor="middle" fontWeight="bold">Enhanced Capabilities</text>
        <text x="250" y="690" fontSize="14" fill="#1b5e20" textAnchor="middle">• Proactive Suggestions</text>
        <text x="250" y="710" fontSize="14" fill="#1b5e20" textAnchor="middle">• Pattern Recognition</text>
        <text x="250" y="730" fontSize="14" fill="#1b5e20" textAnchor="middle">• Crisis Management</text>

        <rect x="450" y="640" width="300" height="100" fill="#81c784" rx="10" />
        <text x="600" y="670" fontSize="16" fill="#1b5e20" textAnchor="middle" fontWeight="bold">Family Features</text>
        <text x="600" y="690" fontSize="14" fill="#1b5e20" textAnchor="middle">• Member Profiles</text>
        <text x="600" y="710" fontSize="14" fill="#1b5e20" textAnchor="middle">• Role-Based Access</text>
        <text x="600" y="730" fontSize="14" fill="#1b5e20" textAnchor="middle">• Daily Briefings</text>

        <rect x="800" y="640" width="300" height="100" fill="#81c784" rx="10" />
        <text x="950" y="670" fontSize="16" fill="#1b5e20" textAnchor="middle" fontWeight="bold">Security Features</text>
        <text x="950" y="690" fontSize="14" fill="#1b5e20" textAnchor="middle">• End-to-End Encryption</text>
        <text x="950" y="710" fontSize="14" fill="#1b5e20" textAnchor="middle">• Biometric Auth</text>
        <text x="950" y="730" fontSize="14" fill="#1b5e20" textAnchor="middle">• Privacy Controls</text>

        {/* Core Services */}
        <rect x="100" y="840" width="250" height="80" fill="#f57c00" rx="10" />
        <text x="225" y="870" fontSize="16" fill="white" textAnchor="middle">pubsub-emulator</text>
        <text x="225" y="890" fontSize="14" fill="white" textAnchor="middle">Message Bus</text>
        <text x="225" y="910" fontSize="12" fill="white" textAnchor="middle">Port: 8085</text>

        <rect x="400" y="840" width="200" height="80" fill="#f57c00" rx="10" />
        <text x="500" y="870" fontSize="16" fill="white" textAnchor="middle">redis</text>
        <text x="500" y="890" fontSize="14" fill="white" textAnchor="middle">Cache & Context</text>
        <text x="500" y="910" fontSize="12" fill="white" textAnchor="middle">Port: 6379</text>

        <rect x="650" y="840" width="200" height="80" fill="#f57c00" rx="10" />
        <text x="750" y="870" fontSize="16" fill="white" textAnchor="middle">qdrant</text>
        <text x="750" y="890" fontSize="14" fill="white" textAnchor="middle">Vector DB</text>
        <text x="750" y="910" fontSize="12" fill="white" textAnchor="middle">Port: 6333</text>

        <rect x="900" y="840" width="200" height="80" fill="#f57c00" rx="10" />
        <text x="1000" y="870" fontSize="16" fill="white" textAnchor="middle">ollama</text>
        <text x="1000" y="890" fontSize="14" fill="white" textAnchor="middle">Local LLM</text>
        <text x="1000" y="910" fontSize="12" fill="white" textAnchor="middle">Port: 11434</text>

        <rect x="1150" y="820" width="500" height="120" fill="none" stroke="#f57c00" strokeWidth="3" rx="10" />
        <text x="1400" y="850" fontSize="18" fill="#f57c00" textAnchor="middle" fontWeight="bold">Supabase Services</text>

        <rect x="1170" y="880" width="140" height="40" fill="#f57c00" rx="5" />
        <text x="1240" y="905" fontSize="12" fill="white" textAnchor="middle">PostgreSQL (5432)</text>

        <rect x="1320" y="880" width="140" height="40" fill="#f57c00" rx="5" />
        <text x="1390" y="905" fontSize="12" fill="white" textAnchor="middle">REST API (3000)</text>

        <rect x="1470" y="880" width="140" height="40" fill="#f57c00" rx="5" />
        <text x="1540" y="905" fontSize="12" fill="white" textAnchor="middle">Realtime (4000)</text>

        {/* Data Layer */}
        <rect x="100" y="1060" width="800" height="200" fill="none" stroke="#d81b60" strokeWidth="3" rx="10" />
        <text x="500" y="1090" fontSize="18" fill="#d81b60" textAnchor="middle" fontWeight="bold">Enhanced Database Schema</text>

        <rect x="120" y="1120" width="120" height="40" fill="#d81b60" rx="5" />
        <text x="180" y="1145" fontSize="12" fill="white" textAnchor="middle">family_members</text>

        <rect x="250" y="1120" width="120" height="40" fill="#d81b60" rx="5" />
        <text x="310" y="1145" fontSize="12" fill="white" textAnchor="middle">family_relations</text>

        <rect x="380" y="1120" width="120" height="40" fill="#d81b60" rx="5" />
        <text x="440" y="1145" fontSize="12" fill="white" textAnchor="middle">member_activities</text>

        <rect x="510" y="1120" width="160" height="40" fill="#d81b60" rx="5" />
        <text x="590" y="1145" fontSize="12" fill="white" textAnchor="middle">proactive_suggestions</text>

        <rect x="680" y="1120" width="140" height="40" fill="#d81b60" rx="5" />
        <text x="750" y="1145" fontSize="12" fill="white" textAnchor="middle">voice_interactions</text>

        <rect x="120" y="1170" width="150" height="40" fill="#d81b60" rx="5" />
        <text x="195" y="1195" fontSize="12" fill="white" textAnchor="middle">emergency_incidents</text>

        <rect x="280" y="1170" width="120" height="40" fill="#d81b60" rx="5" />
        <text x="340" y="1195" fontSize="12" fill="white" textAnchor="middle">task_results</text>

        <rect x="410" y="1170" width="160" height="40" fill="#d81b60" rx="5" />
        <text x="490" y="1195" fontSize="12" fill="white" textAnchor="middle">processed_messages</text>

        <rect x="580" y="1170" width="120" height="40" fill="#d81b60" rx="5" />
        <text x="640" y="1195" fontSize="12" fill="white" textAnchor="middle">embeddings</text>

        {/* Monitoring */}
        <rect x="950" y="1060" width="400" height="200" fill="none" stroke="#d81b60" strokeWidth="3" rx="10" />
        <text x="1150" y="1090" fontSize="18" fill="#d81b60" textAnchor="middle" fontWeight="bold">Monitoring & Observability</text>

        <rect x="970" y="1120" width="160" height="40" fill="#d81b60" rx="5" />
        <text x="1050" y="1145" fontSize="12" fill="white" textAnchor="middle">Prometheus (9090)</text>

        <rect x="1140" y="1120" width="160" height="40" fill="#d81b60" rx="5" />
        <text x="1220" y="1145" fontSize="12" fill="white" textAnchor="middle">Grafana (3002)</text>

        <rect x="970" y="1170" width="320" height="70" fill="#f8bbd0" rx="5" />
        <text x="1130" y="1190" fontSize="14" fill="#880e4f" textAnchor="middle" fontWeight="bold">Enhanced Dashboards</text>
        <text x="1130" y="1210" fontSize="12" fill="#880e4f" textAnchor="middle">• Family Activity Monitoring</text>
        <text x="1130" y="1230" fontSize="12" fill="#880e4f" textAnchor="middle">• Proactive Suggestion Analytics</text>

        {/* External Integrations */}
        <rect x="1400" y="1060" width="380" height="200" fill="none" stroke="#d81b60" strokeWidth="3" rx="10" />
        <text x="1590" y="1090" fontSize="18" fill="#d81b60" textAnchor="middle" fontWeight="bold">External Integrations</text>

        <rect x="1420" y="1120" width="140" height="40" fill="#d81b60" rx="5" />
        <text x="1490" y="1145" fontSize="12" fill="white" textAnchor="middle">OpenAI GPT-4</text>

        <rect x="1570" y="1120" width="140" height="40" fill="#d81b60" rx="5" />
        <text x="1640" y="1145" fontSize="12" fill="white" textAnchor="middle">Twilio APIs</text>

        <rect x="1420" y="1170" width="140" height="40" fill="#d81b60" rx="5" />
        <text x="1490" y="1195" fontSize="12" fill="white" textAnchor="middle">Google Speech</text>

        <rect x="1570" y="1170" width="140" height="40" fill="#d81b60" rx="5" />
        <text x="1640" y="1195" fontSize="12" fill="white" textAnchor="middle">Smart Home APIs</text>

        {/* Connection Lines */}
        {/* All interfaces to Master Alfred */}
        <line x1="300" y1="160" x2="900" y2="280" stroke="#2196f3" strokeWidth="3" markerEnd="url(#arrowhead)" />
        <line x1="550" y1="160" x2="900" y2="280" stroke="#2196f3" strokeWidth="3" markerEnd="url(#arrowhead)" />
        <line x1="800" y1="160" x2="900" y2="280" stroke="#2196f3" strokeWidth="3" markerEnd="url(#arrowhead)" />
        <line x1="1050" y1="160" x2="900" y2="280" stroke="#2196f3" strokeWidth="3" markerEnd="url(#arrowhead)" />
        <line x1="1300" y1="160" x2="900" y2="280" stroke="#2196f3" strokeWidth="3" markerEnd="url(#arrowhead)" />
        <line x1="1550" y1="160" x2="900" y2="280" stroke="#2196f3" strokeWidth="3" markerEnd="url(#arrowhead)" />

        {/* Master Alfred to Agents through Pub/Sub */}
        <line x1="900" y1="400" x2="225" y2="840" stroke="#f57c00" strokeWidth="3" strokeDasharray="5,5" markerEnd="url(#arrowhead-orange)" />
        <line x1="225" y1="920" x2="200" y2="520" stroke="#f57c00" strokeWidth="3" strokeDasharray="5,5" markerEnd="url(#arrowhead-orange)" />
        <line x1="225" y1="920" x2="450" y2="520" stroke="#f57c00" strokeWidth="3" strokeDasharray="5,5" markerEnd="url(#arrowhead-orange)" />
        <line x1="225" y1="920" x2="700" y2="520" stroke="#f57c00" strokeWidth="3" strokeDasharray="5,5" markerEnd="url(#arrowhead-orange)" />
        <line x1="225" y1="920" x2="950" y2="520" stroke="#f57c00" strokeWidth="3" strokeDasharray="5,5" markerEnd="url(#arrowhead-orange)" />
        <line x1="225" y1="920" x2="1200" y2="520" stroke="#f57c00" strokeWidth="3" strokeDasharray="5,5" markerEnd="url(#arrowhead-orange)" />
        <line x1="225" y1="920" x2="1450" y2="520" stroke="#f57c00" strokeWidth="3" strokeDasharray="5,5" markerEnd="url(#arrowhead-orange)" />
        <line x1="225" y1="920" x2="1700" y2="520" stroke="#f57c00" strokeWidth="3" strokeDasharray="5,5" markerEnd="url(#arrowhead-orange)" />

        {/* Master Alfred to Redis */}
        <line x1="900" y1="400" x2="500" y2="840" stroke="#f57c00" strokeWidth="3" markerEnd="url(#arrowhead-orange)" />

        {/* All services to Database */}
        <line x1="900" y1="400" x2="1240" y2="880" stroke="#d81b60" strokeWidth="3" markerEnd="url(#arrowhead-pink)" />
        <line x1="200" y1="620" x2="1240" y2="880" stroke="#d81b60" strokeWidth="3" markerEnd="url(#arrowhead-pink)" />
        <line x1="450" y1="620" x2="1240" y2="880" stroke="#d81b60" strokeWidth="3" markerEnd="url(#arrowhead-pink)" />
        <line x1="700" y1="620" x2="1240" y2="880" stroke="#d81b60" strokeWidth="3" markerEnd="url(#arrowhead-pink)" />
        <line x1="950" y1="620" x2="1240" y2="880" stroke="#d81b60" strokeWidth="3" markerEnd="url(#arrowhead-pink)" />

        {/* All services to Monitoring */}
        <line x1="900" y1="400" x2="1050" y2="1120" stroke="#d81b60" strokeWidth="3" strokeDasharray="2,2" markerEnd="url(#arrowhead-pink)" />
        <line x1="200" y1="620" x2="1050" y2="1120" stroke="#d81b60" strokeWidth="3" strokeDasharray="2,2" markerEnd="url(#arrowhead-pink)" />
        <line x1="450" y1="620" x2="1050" y2="1120" stroke="#d81b60" strokeWidth="3" strokeDasharray="2,2" markerEnd="url(#arrowhead-pink)" />
        <line x1="700" y1="620" x2="1050" y2="1120" stroke="#d81b60" strokeWidth="3" strokeDasharray="2,2" markerEnd="url(#arrowhead-pink)" />

        {/* Prometheus to Grafana */}
        <line x1="1130" y1="1140" x2="1140" y2="1140" stroke="#d81b60" strokeWidth="3" markerEnd="url(#arrowhead-pink)" />

        {/* Arrow definitions */}
        <defs>
          <marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
            <polygon points="0 0, 10 3.5, 0 7" fill="#2196f3" />
          </marker>
          <marker id="arrowhead-orange" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
            <polygon points="0 0, 10 3.5, 0 7" fill="#f57c00" />
          </marker>
          <marker id="arrowhead-pink" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
            <polygon points="0 0, 10 3.5, 0 7" fill="#d81b60" />
          </marker>
        </defs>
      </svg>

      {/* Legend */}
      <div className="mt-8 p-4 bg-gray-100 rounded-lg">
        <h3 className="text-xl font-bold mb-4">Architecture Legend</h3>
        <div className="grid grid-cols-3 gap-6">
          <div className="flex items-center">
            <div className="w-12 h-3 bg-blue-600 mr-2"></div>
            <span>Direct API Connection</span>
          </div>
          <div className="flex items-center">
            <div className="w-12 h-3 border-t-2 border-dashed border-orange-600 mr-2"></div>
            <span>Event-Driven (Pub/Sub)</span>
          </div>
          <div className="flex items-center">
            <div className="w-12 h-3 border-t-2 border-dotted border-pink-600 mr-2"></div>
            <span>Monitoring/Metrics</span>
          </div>
          <div className="flex items-center">
            <div className="w-8 h-8 bg-green-500 mr-2 rounded"></div>
            <span>New Components</span>
          </div>
          <div className="flex items-center">
            <div className="w-8 h-8 bg-green-700 mr-2 rounded"></div>
            <span>Existing Components</span>
          </div>
          <div className="flex items-center">
            <div className="w-8 h-8 bg-purple-700 mr-2 rounded"></div>
            <span>Master Controller</span>
          </div>
        </div>
      </div>

      {/* Key Features */}
      <div className="mt-8 grid grid-cols-3 gap-8">
        <div className="bg-blue-50 p-6 rounded-lg">
          <h3 className="text-xl font-bold mb-4">Multi-Interface Support</h3>
          <ul className="list-disc pl-6 space-y-2">
            <li>Voice commands with natural language processing</li>
            <li>Mobile app with real-time notifications</li>
            <li>WhatsApp for family messaging</li>
            <li>Web dashboard for comprehensive control</li>
            <li>Smart home integration via MQTT</li>
            <li>Existing Slack interface enhanced</li>
          </ul>
        </div>

        <div className="bg-purple-50 p-6 rounded-lg">
          <h3 className="text-xl font-bold mb-4">Alfred Personality Engine</h3>
          <ul className="list-disc pl-6 space-y-2">
            <li>Context-aware responses</li>
            <li>Family member recognition</li>
            <li>Proactive assistance</li>
            <li>Crisis management protocols</li>
            <li>Subtle wit and warmth</li>
            <li>Anticipatory suggestions</li>
          </ul>
        </div>

        <div className="bg-green-50 p-6 rounded-lg">
          <h3 className="text-xl font-bold mb-4">Enhanced Capabilities</h3>
          <ul className="list-disc pl-6 space-y-2">
            <li>Pattern recognition for routines</li>
            <li>Proactive monitoring system</li>
            <li>Emergency response handling</li>
            <li>Family-specific customization</li>
            <li>Business operation support</li>
            <li>Security & privacy controls</li>
          </ul>
        </div>
      </div>

      {/* Implementation Timeline */}
      <div className="mt-8 bg-gray-50 p-6 rounded-lg">
        <h3 className="text-xl font-bold mb-4">Implementation Timeline</h3>
        <div className="grid grid-cols-4 gap-4">
          <div className="bg-white p-4 rounded shadow">
            <h4 className="font-bold">Weeks 1-3</h4>
            <p className="text-sm">Master Alfred Core & Personality Engine</p>
          </div>
          <div className="bg-white p-4 rounded shadow">
            <h4 className="font-bold">Weeks 4-6</h4>
            <p className="text-sm">Multi-Interface Integration</p>
          </div>
          <div className="bg-white p-4 rounded shadow">
            <h4 className="font-bold">Weeks 7-9</h4>
            <p className="text-sm">Enhanced Agents & Proactive Features</p>
          </div>
          <div className="bg-white p-4 rounded shadow">
            <h4 className="font-bold">Weeks 10-12</h4>
            <p className="text-sm">Dashboard, Testing & Deployment</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AlfredAssistantArchitecture;
