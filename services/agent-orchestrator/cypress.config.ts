import { defineConfig } from "cypress";

export default defineConfig({
  e2e: {
    baseUrl: "http://localhost:8080",
    supportFile: false,
    specPattern: "cypress/e2e/**/*.cy.{js,jsx,ts,tsx}",
    downloadsFolder: "cypress/downloads",
    video: false,
    screenshot: false,
    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
  },
  component: {
    devServer: {
      framework: "react",
      bundler: "vite",
    },
  },
});