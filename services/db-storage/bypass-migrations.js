/**
 * Bypasses the migration process entirely
 */

// Mock database module
const originalDatabase = require('/app/dist/database');

// Save original database functions
const originalFunctions = {
  runMigrations: originalDatabase.runMigrations,
  connectAndMigrate: originalDatabase.connectAndMigrate
};

// Replace the runMigrations function with a no-op
originalDatabase.runMigrations = async function mockedRunMigrations() {
  console.log('Migration bypassed: runMigrations() has been disabled');
  return true;
};

// Replace the connectAndMigrate function with a no-op
originalDatabase.connectAndMigrate = async function mockedConnectAndMigrate() {
  console.log('Migration bypassed: connectAndMigrate() has been disabled');
  return true;
};

// Start the original server
require('/app/dist/server');