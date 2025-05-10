import { useState, useEffect } from "react";
import { 
  LineChart, 
  Line, 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  AreaChart,
  Area,
  PieChart,
  Pie,
  Cell
} from "recharts";
import { GradientProgressBar } from "../ui/visualizations/GradientProgressBar";

const generateRandomData = (points: number) => {
  return Array(points)
    .fill(0)
    .map((_, i) => ({
      name: `T-${points - i}`,
      value: Math.round(Math.random() * 100),
      cpu: Math.round(Math.random() * 80) + 10,
      memory: Math.round(Math.random() * 60) + 20,
      errors: Math.round(Math.random() * 10),
      lag: Math.round(Math.random() * 2000)
    }));
};

const ChartGrid = () => {
  const [cpuUsage, setCpuUsage] = useState(68);
  const [memoryUsage, setMemoryUsage] = useState(42);
  const [storageUsage, setStorageUsage] = useState(27);
  const [networkUsage, setNetworkUsage] = useState(33);
  
  const COLORS = ["#3b82f6", "#8b5cf6", "#10b981", "#f59e0b", "#ef4444"];
  
  const lineData = generateRandomData(24);
  const barData = generateRandomData(12);
  const pieData = [
    { name: "Workflow A", value: 500 },
    { name: "Workflow B", value: 300 },
    { name: "Workflow C", value: 200 },
    { name: "Workflow D", value: 100 },
    { name: "Workflow E", value: 50 }
  ];
  
  useEffect(() => {
    // Simulate changing metrics every 5 seconds
    const interval = setInterval(() => {
      setCpuUsage(Math.round(Math.random() * 30) + 50);
      setMemoryUsage(Math.round(Math.random() * 40) + 20);
      setStorageUsage(Math.round(Math.random() * 20) + 20);
      setNetworkUsage(Math.round(Math.random() * 50) + 10);
    }, 5000);
    
    return () => clearInterval(interval);
  }, []);
  
  return (
    <div className="space-y-6">
      <h2 className="text-xl font-semibold mb-4">System Metrics</h2>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        <div className="space-y-4 card-shadow p-4">
          <h3 className="text-lg font-medium">Resource Usage</h3>
          <div className="space-y-6 mt-4">
            <GradientProgressBar 
              value={cpuUsage} 
              variant="primary" 
              showValue={true} 
              animated={true}
              label="CPU Usage"
            />
            
            <GradientProgressBar 
              value={memoryUsage} 
              variant="secondary" 
              showValue={true}
              label="Memory Usage"
            />
            
            <GradientProgressBar 
              value={storageUsage} 
              variant="success" 
              showValue={true}
              label="Storage Usage"
            />
            
            <GradientProgressBar 
              value={networkUsage} 
              variant="warning" 
              showValue={true}
              striped={true}
              label="Network Bandwidth"
            />
          </div>
        </div>
        
        <div className="card-shadow p-4">
          <h3 className="text-lg font-medium mb-4">Workflow Distribution</h3>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={pieData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={80}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {pieData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip 
                  formatter={(value) => [`${value} Tasks`, 'Count']}
                  labelFormatter={(name) => `${name}`}
                />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="chart-container">
          <h3 className="text-lg font-medium mb-4">System Performance</h3>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={lineData}>
                <CartesianGrid strokeDasharray="3 3" opacity={0.2} />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip 
                  formatter={(value) => [`${value}%`, 'Usage']}
                  labelFormatter={(name) => `Time ${name}`}
                />
                <defs>
                  <linearGradient id="cpuColor" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.8} />
                    <stop offset="95%" stopColor="#3b82f6" stopOpacity={0.1} />
                  </linearGradient>
                  <linearGradient id="memoryColor" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#8b5cf6" stopOpacity={0.8} />
                    <stop offset="95%" stopColor="#8b5cf6" stopOpacity={0.1} />
                  </linearGradient>
                </defs>
                <Line 
                  type="monotone" 
                  dataKey="cpu" 
                  name="CPU" 
                  stroke="#3b82f6" 
                  strokeWidth={2}
                  dot={false}
                  activeDot={{ r: 8 }}
                />
                <Line 
                  type="monotone" 
                  dataKey="memory" 
                  name="Memory" 
                  stroke="#8b5cf6"
                  strokeWidth={2}
                  dot={false}
                  activeDot={{ r: 8 }}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>
        
        <div className="chart-container">
          <h3 className="text-lg font-medium mb-4">Error Rate</h3>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={barData}>
                <CartesianGrid strokeDasharray="3 3" opacity={0.2} />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip 
                  formatter={(value) => [`${value}`, 'Count']}
                  labelFormatter={(name) => `Time ${name}`}
                />
                <defs>
                  <linearGradient id="errorGradient" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#ef4444" stopOpacity={0.8} />
                    <stop offset="95%" stopColor="#ef4444" stopOpacity={0.1} />
                  </linearGradient>
                </defs>
                <Area 
                  type="monotone" 
                  dataKey="errors" 
                  name="Errors" 
                  stroke="#ef4444"
                  strokeWidth={2}
                  fillOpacity={1}
                  fill="url(#errorGradient)"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ChartGrid;