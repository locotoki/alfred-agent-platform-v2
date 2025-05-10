# YouTube Workflows E2E Tests

This directory contains end-to-end tests for the YouTube workflows in Alfred Agent Platform v2.

## Test Structure

- `playwright.config.ts` - Configuration for Playwright tests
- `tests/` - Test files
  - `niche-scout.spec.ts` - Tests for the Niche-Scout workflow
  - `seed-to-blueprint.spec.ts` - Tests for the Seed-to-Blueprint workflow
  - `mock-data-mode.spec.ts` - Tests specifically for mock data mode
  - `utils.ts` - Utility functions for the tests

## Prerequisites

- Node.js 16+ installed
- Mission Control running on port 3005
- Social Intelligence Agent running on port 9000

## Setup

1. Install dependencies:

```bash
npm install
npx playwright install chromium
```

Or use the helper script:

```bash
npm run install-deps
```

## Running Tests

### Running all tests

```bash
npm test
```

### Running tests with browser visible

```bash
npm run test:headed
```

### Running specific test groups

```bash
# Run only Niche-Scout tests
npm run test:niche

# Run only Seed-to-Blueprint tests
npm run test:blueprint

# Run only mock data tests
npm run test:mock
```

### Using the run-tests.sh script

The `run-tests.sh` script provides a convenient way to run the tests. It:
- Checks if Mission Control is running and starts it if needed
- Checks if Social Intelligence Agent is running and starts it if needed
- Installs Playwright if needed
- Runs the tests

```bash
chmod +x run-tests.sh
./run-tests.sh
```

## Test Reports

After running the tests, you can view the HTML report:

```bash
npm run show-report
```

Or open `playwright-report/index.html` in your browser.

## Mock Data Mode

The tests can run in two modes:

1. **Real API mode**: Tests try to connect to the actual Social Intelligence Agent
2. **Mock data mode**: Tests intercept API calls and return mock data

By default, tests try to use the real API but have fallbacks for error cases. The `mock-data-mode.spec.ts` file specifically tests the mock data functionality.

## Troubleshooting

### Tests fail with timeout errors

- Ensure Mission Control is running on port 3005
- Ensure Social Intelligence Agent is running on port 9000
- Increase the timeout values in `playwright.config.ts`

### Browser doesn't open in headed mode

- Make sure you have a display server running
- Try running with `xvfb-run` if using a headless server

### Tests pass despite API errors

This is expected behavior. The tests are designed to handle API errors gracefully by:
1. Detecting error responses
2. Testing the fallback to mock data
3. Verifying the UI displays proper error messages

## CI/CD Integration

These tests can be integrated into a CI/CD pipeline. For CI environments, use:

```bash
npx playwright test --reporter=dot,html
```
