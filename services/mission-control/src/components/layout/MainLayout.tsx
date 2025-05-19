import { ReactNode, useState, useEffect } from 'react';
import React from "react";
import "../../styles/loading.css";
import { ReactNode, useState, useEffect } from 'react';
import Head from 'next/head';
import Link from 'next/link';
import { useRouter } from 'next/router';
import { FiHome, FiUsers, FiList, FiActivity, FiFileText, FiSettings, FiLogOut, FiMoon, FiSun } from 'react-icons/fi';
import classNames from 'classnames';

// Optional import of Supabase clients
let useSupabaseClient;
let useUser;
try {
  const supabaseAuth = require('@supabase/auth-helpers-react');
  useSupabaseClient = supabaseAuth.useSupabaseClient;
  useUser = supabaseAuth.useUser;
} catch (error) {
  console.warn('Supabase auth helpers not available, using mock');
  useSupabaseClient = () => ({ auth: { signOut: () => Promise.resolve() } });
  useUser = () => null;
}

interface MainLayoutProps {
  children: ReactNode;
  title?: string;
}

export default function MainLayout({ children, title = 'Mission Control' }: MainLayoutProps) {
  const router = useRouter();
  const [darkMode, setDarkMode] = useState(true);
  const supabaseClient = typeof useSupabaseClient === 'function' ? useSupabaseClient() : null;
  const user = typeof useUser === 'function' ? useUser() : null;

  // Apply dark mode on initial load
  useEffect(() => {
    if (darkMode) {
      document.documentElement.classList.add('dark');
    }
  }, []);

  const toggleDarkMode = () => {
    const newMode = !darkMode;
    setDarkMode(newMode);
    if (newMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  };

  const handleSignOut = async () => {
    if (supabaseClient?.auth) {
      await supabaseClient.auth.signOut();
    }
    router.push('/auth/signin');
  };

  const navigation = [
    { name: 'Dashboard', href: '/dashboard', icon: FiHome },
    { name: 'Agents', href: '/agents', icon: FiUsers },
    { name: 'Tasks', href: '/tasks', icon: FiList },
    { name: 'Workflows', href: '/workflows', icon: FiActivity },
    { name: 'Reports', href: '/reports', icon: FiFileText },
    { name: 'Settings', href: '/settings', icon: FiSettings },
  ];

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <Head>
        <title>{`${title} | Alfred Agent Platform`}</title>
        <meta name="description" content="Mission Control for Alfred Agent Platform" />
        <link rel="icon" href="/favicon.ico" />
        <script src="/port-fix.js"></script>
        <script src="/test-script.js"></script>
      </Head>

      <header className="bg-white dark:bg-gray-800 shadow-md border-b border-gray-200 dark:border-gray-700">
        <div className="flex justify-between items-center px-4 py-4 sm:px-6 lg:px-8">
          <h1 className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">MISSION CONTROL</h1>
          <div className="flex items-center">
            <button
              onClick={toggleDarkMode}
              className="p-2 mr-4 rounded-full text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
            >
              {darkMode ? <FiSun className="h-5 w-5" /> : <FiMoon className="h-5 w-5" />}
            </button>
            {/* Always show admin in development */}
            <div className="flex items-center">
              <div className="mr-3 flex items-center">
                <div className="h-8 w-8 rounded-full bg-gradient-to-r from-blue-500 to-indigo-600 flex items-center justify-center text-white">
                  <span className="text-sm font-bold">A</span>
                </div>
                <span className="ml-2 text-sm font-medium text-gray-700 dark:text-gray-300">
                  Admin
                </span>
              </div>
              <button
                onClick={handleSignOut}
                className="p-2 rounded-full text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              >
                <FiLogOut className="h-5 w-5" />
              </button>
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
                  className={classNames(
                    'nav-link inline-flex items-center px-4 text-sm font-medium border-b-2 transition-all',
                    router.pathname.startsWith(item.href)
                      ? 'border-primary-500 text-primary-600 dark:text-primary-400 active'
                      : 'border-transparent text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 hover:border-gray-300 dark:hover:border-gray-600'
                  )}
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
          {children}
        </div>
      </main>

      <footer className="bg-white dark:bg-gray-800 border-t border-gray-200 dark:border-gray-700">
        <div className="max-w-7xl mx-auto py-4 px-4 sm:px-6 lg:px-8">
          <p className="text-center text-sm text-gray-500 dark:text-gray-400">
            &copy; {new Date().getFullYear()} Alfred Agent Platform. All rights reserved.
          </p>
        </div>
      </footer>
    </div>
  );
import React from "react";
