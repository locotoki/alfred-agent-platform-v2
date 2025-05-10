import { PlaywrightTestConfig } from '@playwright/test';

const config: PlaywrightTestConfig = {
  testDir: './tests',
  timeout: 120000, // Longer timeout for YouTube workflows 
  fullyParallel: false, 
  retries: 1,
  workers: 1, // Sequential execution to avoid conflicts
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3005', // Mission Control UI port
    viewport: { width: 1280, height: 720 },
    screenshot: 'only-on-failure',
    video: 'on-first-retry',
    trace: 'on-first-retry',
    headless: false, // Useful for debugging
  },
  projects: [
    {
      name: 'chromium',
      use: { browserName: 'chromium' },
    },
  ],
};

export default config;
