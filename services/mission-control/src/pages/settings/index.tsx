import { useState } from 'react';
import MainLayout from '../../components/layout/MainLayout';
import { FiSave, FiUsers, FiServer, FiLock, FiCpu, FiClock, FiMail, FiAlertTriangle } from 'react-icons/fi';

export default function Settings() {
  // General settings state
  const [siteName, setSiteName] = useState('Alfred Agent Platform');
  const [adminEmail, setAdminEmail] = useState('admin@example.com');
  const [loggingLevel, setLoggingLevel] = useState('info');
  const [maxAgents, setMaxAgents] = useState(10);
  
  // System settings state
  const [maxCpuUsage, setMaxCpuUsage] = useState(80);
  const [maxMemoryUsage, setMaxMemoryUsage] = useState(70);
  const [autoRestart, setAutoRestart] = useState(true);
  const [taskTimeout, setTaskTimeout] = useState(60);
  
  // Security settings state
  const [twoFactorAuth, setTwoFactorAuth] = useState(false);
  const [sessionTimeout, setSessionTimeout] = useState(30);
  const [apiRateLimit, setApiRateLimit] = useState(100);
  
  // Notification settings state
  const [emailNotifications, setEmailNotifications] = useState(true);
  const [taskAlerts, setTaskAlerts] = useState(true);
  const [systemAlerts, setSystemAlerts] = useState(true);
  
  // Form submission handler
  const handleSubmit = (e) => {
    e.preventDefault();
    // In a real application, this would save settings to a database or config file
    alert('Settings saved successfully!');
  };

  return (
    <MainLayout title="Settings">
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">System Settings</h1>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="space-y-6">
            {/* General Settings */}
            <div className="card p-6">
              <div className="flex items-center mb-4">
                <FiServer className="h-5 w-5 text-primary-600 dark:text-primary-400 mr-2" />
                <h2 className="text-xl font-medium text-gray-900 dark:text-white">General Settings</h2>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label htmlFor="site-name" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Platform Name
                  </label>
                  <input
                    type="text"
                    id="site-name"
                    className="input w-full"
                    value={siteName}
                    onChange={(e) => setSiteName(e.target.value)}
                  />
                </div>
                
                <div>
                  <label htmlFor="admin-email" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Admin Email
                  </label>
                  <input
                    type="email"
                    id="admin-email"
                    className="input w-full"
                    value={adminEmail}
                    onChange={(e) => setAdminEmail(e.target.value)}
                  />
                </div>
                
                <div>
                  <label htmlFor="logging-level" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Logging Level
                  </label>
                  <select
                    id="logging-level"
                    className="input w-full"
                    value={loggingLevel}
                    onChange={(e) => setLoggingLevel(e.target.value)}
                  >
                    <option value="debug">Debug</option>
                    <option value="info">Info</option>
                    <option value="warning">Warning</option>
                    <option value="error">Error</option>
                  </select>
                </div>
                
                <div>
                  <label htmlFor="max-agents" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Maximum Agents
                  </label>
                  <input
                    type="number"
                    id="max-agents"
                    className="input w-full"
                    min="1"
                    max="100"
                    value={maxAgents}
                    onChange={(e) => setMaxAgents(parseInt(e.target.value, 10))}
                  />
                </div>
              </div>
            </div>
            
            {/* System Resources */}
            <div className="card p-6">
              <div className="flex items-center mb-4">
                <FiCpu className="h-5 w-5 text-primary-600 dark:text-primary-400 mr-2" />
                <h2 className="text-xl font-medium text-gray-900 dark:text-white">System Resources</h2>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label htmlFor="max-cpu" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Max CPU Usage (%)
                  </label>
                  <input
                    type="number"
                    id="max-cpu"
                    className="input w-full"
                    min="10"
                    max="100"
                    value={maxCpuUsage}
                    onChange={(e) => setMaxCpuUsage(parseInt(e.target.value, 10))}
                  />
                </div>
                
                <div>
                  <label htmlFor="max-memory" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Max Memory Usage (%)
                  </label>
                  <input
                    type="number"
                    id="max-memory"
                    className="input w-full"
                    min="10"
                    max="100"
                    value={maxMemoryUsage}
                    onChange={(e) => setMaxMemoryUsage(parseInt(e.target.value, 10))}
                  />
                </div>
                
                <div>
                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      className="rounded border-gray-300 text-primary-600 shadow-sm focus:border-primary-300 focus:ring focus:ring-primary-200 focus:ring-opacity-50 dark:border-gray-600 dark:bg-gray-700"
                      checked={autoRestart}
                      onChange={(e) => setAutoRestart(e.target.checked)}
                    />
                    <span className="ml-2 text-sm text-gray-700 dark:text-gray-300">
                      Auto-restart agents on failure
                    </span>
                  </label>
                </div>
                
                <div>
                  <label htmlFor="task-timeout" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Task Timeout (minutes)
                  </label>
                  <input
                    type="number"
                    id="task-timeout"
                    className="input w-full"
                    min="1"
                    max="1440"
                    value={taskTimeout}
                    onChange={(e) => setTaskTimeout(parseInt(e.target.value, 10))}
                  />
                </div>
              </div>
            </div>
            
            {/* Security */}
            <div className="card p-6">
              <div className="flex items-center mb-4">
                <FiLock className="h-5 w-5 text-primary-600 dark:text-primary-400 mr-2" />
                <h2 className="text-xl font-medium text-gray-900 dark:text-white">Security</h2>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      className="rounded border-gray-300 text-primary-600 shadow-sm focus:border-primary-300 focus:ring focus:ring-primary-200 focus:ring-opacity-50 dark:border-gray-600 dark:bg-gray-700"
                      checked={twoFactorAuth}
                      onChange={(e) => setTwoFactorAuth(e.target.checked)}
                    />
                    <span className="ml-2 text-sm text-gray-700 dark:text-gray-300">
                      Require Two-Factor Authentication
                    </span>
                  </label>
                </div>
                
                <div>
                  <label htmlFor="session-timeout" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Session Timeout (minutes)
                  </label>
                  <input
                    type="number"
                    id="session-timeout"
                    className="input w-full"
                    min="5"
                    max="1440"
                    value={sessionTimeout}
                    onChange={(e) => setSessionTimeout(parseInt(e.target.value, 10))}
                  />
                </div>
                
                <div>
                  <label htmlFor="api-rate-limit" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    API Rate Limit (requests/minute)
                  </label>
                  <input
                    type="number"
                    id="api-rate-limit"
                    className="input w-full"
                    min="10"
                    max="1000"
                    value={apiRateLimit}
                    onChange={(e) => setApiRateLimit(parseInt(e.target.value, 10))}
                  />
                </div>
              </div>
            </div>
            
            {/* Notifications */}
            <div className="card p-6">
              <div className="flex items-center mb-4">
                <FiMail className="h-5 w-5 text-primary-600 dark:text-primary-400 mr-2" />
                <h2 className="text-xl font-medium text-gray-900 dark:text-white">Notifications</h2>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      className="rounded border-gray-300 text-primary-600 shadow-sm focus:border-primary-300 focus:ring focus:ring-primary-200 focus:ring-opacity-50 dark:border-gray-600 dark:bg-gray-700"
                      checked={emailNotifications}
                      onChange={(e) => setEmailNotifications(e.target.checked)}
                    />
                    <span className="ml-2 text-sm text-gray-700 dark:text-gray-300">
                      Email Notifications
                    </span>
                  </label>
                </div>
                
                <div>
                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      className="rounded border-gray-300 text-primary-600 shadow-sm focus:border-primary-300 focus:ring focus:ring-primary-200 focus:ring-opacity-50 dark:border-gray-600 dark:bg-gray-700"
                      checked={taskAlerts}
                      onChange={(e) => setTaskAlerts(e.target.checked)}
                    />
                    <span className="ml-2 text-sm text-gray-700 dark:text-gray-300">
                      Task Completion/Failure Alerts
                    </span>
                  </label>
                </div>
                
                <div>
                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      className="rounded border-gray-300 text-primary-600 shadow-sm focus:border-primary-300 focus:ring focus:ring-primary-200 focus:ring-opacity-50 dark:border-gray-600 dark:bg-gray-700"
                      checked={systemAlerts}
                      onChange={(e) => setSystemAlerts(e.target.checked)}
                    />
                    <span className="ml-2 text-sm text-gray-700 dark:text-gray-300">
                      System Resource Alerts
                    </span>
                  </label>
                </div>
              </div>
            </div>
            
            <div className="flex justify-end">
              <button
                type="submit"
                className="btn-primary flex items-center"
              >
                <FiSave className="mr-2" /> Save Settings
              </button>
            </div>
          </div>
        </form>
      </div>
    </MainLayout>
  );
}