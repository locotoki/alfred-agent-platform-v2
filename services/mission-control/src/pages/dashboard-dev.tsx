import { useState } from 'react';
import Head from 'next/head';
import Link from 'next/link';
import { FiHome, FiUsers, FiList, FiActivity, FiFileText, FiSettings, FiMoon, FiSun } from 'react-icons/fi';
import { format } from 'date-fns';

export default function DashboardDev() {
  const [darkMode, setDarkMode] = useState(true);

  const toggleDarkMode = () => {
    const newMode = !darkMode;
    setDarkMode(newMode);
    if (newMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  };

  const navigation = [
    { name: 'Dashboard', href: '/dashboard-dev', icon: FiHome },
    { name: 'Agents', href: '/agents', icon: FiUsers },
    { name: 'Tasks', href: '/tasks', icon: FiList },
    { name: 'Workflows', href: '/workflows', icon: FiActivity },
    { name: 'Reports', href: '/reports', icon: FiFileText },
    { name: 'Settings', href: '/settings', icon: FiSettings },
  ];

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <Head>
        <title>Dashboard | Alfred Agent Platform</title>
        <meta name="description" content="Mission Control for Alfred Agent Platform" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <header className="bg-white dark:bg-gray-800 shadow">
        <div className="flex justify-between items-center px-4 py-4 sm:px-6 lg:px-8">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">MISSION CONTROL</h1>
          <div className="flex items-center">
            <button
              onClick={toggleDarkMode}
              className="p-2 mr-4 rounded-full text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700"
            >
              {darkMode ? <FiSun className="h-5 w-5" /> : <FiMoon className="h-5 w-5" />}
            </button>
            <div className="flex items-center">
              <span className="mr-2 text-sm font-medium text-gray-700 dark:text-gray-300">
                👤 Admin
              </span>
            </div>
          </div>
        </div>
      </header>

      <nav className="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700">
        <div className="px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-12">
            <div className="flex">
              {navigation.map((item) => (
                <Link
                  key={item.name}
                  href={item.href}
                  className={
                    item.name === 'Dashboard'
                      ? 'inline-flex items-center px-4 text-sm font-medium border-b-2 border-primary-500 text-primary-600 dark:text-primary-400'
                      : 'inline-flex items-center px-4 text-sm font-medium border-b-2 border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 hover:border-gray-300 dark:hover:border-gray-600'
                  }
                >
                  <item.icon className="h-5 w-5 mr-2" />
                  {item.name}
                </Link>
              ))}
            </div>
          </div>
        </div>
      </nav>

      <main className="py-6">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {/* Service Status */}
              <div className="rounded-lg bg-white dark:bg-gray-800 shadow-md overflow-hidden p-4">
                <h2 className="text-lg font-semibold mb-4">Service Status</h2>
                <div className="flex items-center">
                  <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-4">
                    <div className="bg-green-500 h-4 rounded-full" style={{ width: '100%' }}></div>
                  </div>
                  <span className="ml-2 text-sm font-medium">100%</span>
                </div>
              </div>

              {/* Active Tasks */}
              <div className="rounded-lg bg-white dark:bg-gray-800 shadow-md overflow-hidden p-4">
                <h2 className="text-lg font-semibold mb-4">Active Tasks</h2>
                <p className="text-3xl font-bold">12 tasks running</p>
              </div>

              {/* Error Rate */}
              <div className="rounded-lg bg-white dark:bg-gray-800 shadow-md overflow-hidden p-4">
                <h2 className="text-lg font-semibold mb-4">Error Rate</h2>
                <div className="flex items-end space-x-1 h-12">
                  <div className="bg-blue-500 w-4 h-2 rounded-t"></div>
                  <div className="bg-blue-500 w-4 h-4 rounded-t"></div>
                  <div className="bg-blue-500 w-4 h-2 rounded-t"></div>
                  <div className="bg-blue-500 w-4 h-1 rounded-t"></div>
                  <div className="bg-blue-500 w-4 h-1 rounded-t"></div>
                  <div className="bg-blue-500 w-4 h-6 rounded-t"></div>
                  <div className="bg-blue-500 w-4 h-2 rounded-t"></div>
                  <div className="bg-blue-500 w-4 h-1 rounded-t"></div>
                  <div className="bg-blue-500 w-4 h-1 rounded-t"></div>
                </div>
              </div>
            </div>

            {/* Agent Status */}
            <div className="rounded-lg bg-white dark:bg-gray-800 shadow-md overflow-hidden p-4">
              <h2 className="text-lg font-semibold mb-4">Agent Status</h2>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                <div className="border dark:border-gray-700 rounded p-4">
                  <div className="flex justify-between items-center mb-2">
                    <h3 className="font-medium">Alfred Bot</h3>
                    <span className="flex items-center text-sm text-green-600 dark:text-green-400">
                      <span className="h-2.5 w-2.5 rounded-full bg-green-600 dark:bg-green-400 mr-1.5"></span>
                      ONLINE
                    </span>
                  </div>
                  <div className="text-sm text-gray-600 dark:text-gray-400">
                    <p>Tasks: 3</p>
                    <p>CPU: 12%</p>
                  </div>
                </div>

                <div className="border dark:border-gray-700 rounded p-4">
                  <div className="flex justify-between items-center mb-2">
                    <h3 className="font-medium">Social Intel</h3>
                    <span className="flex items-center text-sm text-green-600 dark:text-green-400">
                      <span className="h-2.5 w-2.5 rounded-full bg-green-600 dark:bg-green-400 mr-1.5"></span>
                      ONLINE
                    </span>
                  </div>
                  <div className="text-sm text-gray-600 dark:text-gray-400">
                    <p>Tasks: 5</p>
                    <p>CPU: 38%</p>
                  </div>
                </div>

                <div className="border dark:border-gray-700 rounded p-4">
                  <div className="flex justify-between items-center mb-2">
                    <h3 className="font-medium">Financial-Tax</h3>
                    <span className="flex items-center text-sm text-green-600 dark:text-green-400">
                      <span className="h-2.5 w-2.5 rounded-full bg-green-600 dark:bg-green-400 mr-1.5"></span>
                      ONLINE
                    </span>
                  </div>
                  <div className="text-sm text-gray-600 dark:text-gray-400">
                    <p>Tasks: 2</p>
                    <p>CPU: 8%</p>
                  </div>
                </div>

                <div className="border dark:border-gray-700 rounded p-4">
                  <div className="flex justify-between items-center mb-2">
                    <h3 className="font-medium">Legal</h3>
                    <span className="flex items-center text-sm text-green-600 dark:text-green-400">
                      <span className="h-2.5 w-2.5 rounded-full bg-green-600 dark:bg-green-400 mr-1.5"></span>
                      ONLINE
                    </span>
                  </div>
                  <div className="text-sm text-gray-600 dark:text-gray-400">
                    <p>Tasks: 2</p>
                    <p>CPU: 5%</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Recent Activity */}
            <div className="rounded-lg bg-white dark:bg-gray-800 shadow-md overflow-hidden p-4">
              <h2 className="text-lg font-semibold mb-4">Recent Activity</h2>
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                  <thead>
                    <tr>
                      <th className="px-6 py-3 bg-gray-50 dark:bg-gray-800 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Time
                      </th>
                      <th className="px-6 py-3 bg-gray-50 dark:bg-gray-800 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Agent
                      </th>
                      <th className="px-6 py-3 bg-gray-50 dark:bg-gray-800 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Task
                      </th>
                      <th className="px-6 py-3 bg-gray-50 dark:bg-gray-800 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        Status
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                    <tr>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                        12:05
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                        Social Intel
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                        Niche-Scout
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                          ✓ Completed
                        </span>
                      </td>
                    </tr>
                    <tr>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                        11:52
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                        Financial-Tax
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                        Tax Report
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                          ✓ Completed
                        </span>
                      </td>
                    </tr>
                    <tr>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                        11:30
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                        Social Intel
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                        Blueprint
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                          ✓ Completed
                        </span>
                      </td>
                    </tr>
                    <tr>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                        11:15
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                        Legal Compliance
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                        Compliance
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-100">
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                          ✓ Completed
                        </span>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </main>

      <footer className="bg-white dark:bg-gray-800 border-t border-gray-200 dark:border-gray-700">
        <div className="max-w-7xl mx-auto py-4 px-4 sm:px-6 lg:px-8">
          <p className="text-center text-sm text-gray-500 dark:text-gray-400">
            &copy; {new Date().getFullYear()} Alfred Agent Platform. All rights reserved.
          </p>
        </div>
      </footer>

      <div className="fixed bottom-0 left-0 right-0 bg-yellow-100 p-2 text-center text-yellow-800">
        <p>Development mode - Simplified interface without authentication</p>
        <p className="text-sm">
          Go to{' '}
          <Link href="/workflows" className="underline">
            Workflows
          </Link>
          {' '}to see YouTube research tools
        </p>
      </div>
    </div>
  );
}
