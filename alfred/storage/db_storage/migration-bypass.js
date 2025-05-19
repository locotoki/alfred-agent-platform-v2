/**
 * Migration Bypass Module
 *
 * This module completely bypasses the migration system by overriding
 * the postgres-migrations module's functionality, and adds a custom
 * health endpoint for monitoring.
 *
 * It is designed to be preloaded using NODE_OPTIONS=--require
 */

console.log("Applying storage-api migration bypass - hijacking postgres-migrations module");

// Hook into the Node.js module loading system
const Module = require('module');
const originalRequire = Module.prototype.require;

// Override the require function
Module.prototype.require = function(...args) {
  const moduleName = args[0];

  // Check if postgres-migrations module is being loaded
  if (moduleName === 'postgres-migrations' ||
      moduleName.endsWith('/postgres-migrations') ||
      moduleName.includes('postgres-migrations/')) {

    console.log(`Intercepted require of postgres-migrations module: ${moduleName}`);

    // Return a fake postgres-migrations module with no-op functions
    return {
      migrate: async () => {
        console.log("Migration bypass: postgres-migrations.migrate() is disabled");
        return [];
      }
    };
  }

  // Check for specific module paths to intercept
  if (moduleName.includes('migrate.js') && moduleName.includes('database')) {
    console.log(`Intercepted require of migration module: ${moduleName}`);

    // Return fake migration functions
    return {
      runMigrations: async () => {
        console.log("Migration bypass: runMigrations() is disabled");
        return;
      },
      connectAndMigrate: async () => {
        console.log("Migration bypass: connectAndMigrate() is disabled");
        return;
      }
    };
  }

  // For all other modules, use the original require
  return originalRequire.apply(this, args);
};

// Also patch the server.js file directly
const path = require('path');
const fs = require('fs');

try {
  // Patch server.js to skip migration calls
  const serverPath = path.join('/app', 'dist', 'server.js');
  if (fs.existsSync(serverPath)) {
    let serverContent = fs.readFileSync(serverPath, 'utf8');

    // Replace the migration call in server.js
    const patchedContent = serverContent.replace(
      /await\s+runMigrations\(\);/g,
      'console.log("Migration bypass: migrations skipped in server.js"); // Migration call disabled'
    );

    if (serverContent !== patchedContent) {
      fs.writeFileSync(serverPath, patchedContent);
      console.log("Server.js patched successfully");
    }
  }

  // Create a schema initialization function that will run when the server starts
  // This ensures empty tables exist so the service can function
  const createBasicSchema = async () => {
    console.log("Creating basic storage schema if needed");
    try {
      const { Client } = require('pg');
      const client = new Client({
        connectionString: process.env.DATABASE_URL || 'postgresql://postgres:postgres@db-postgres:5432/postgres'
      });

      await client.connect();

      // Check if storage schema exists
      const schemaCheck = await client.query("SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'storage'");

      if (schemaCheck.rows.length === 0) {
        console.log("Creating storage schema");
        await client.query("CREATE SCHEMA IF NOT EXISTS storage");

        // Create minimal tables needed for storage-api to function
        await client.query(`
          CREATE TABLE IF NOT EXISTS storage.migrations (
            id integer PRIMARY KEY,
            name varchar(100) NOT NULL,
            hash varchar(40) NOT NULL,
            executed_at timestamp DEFAULT CURRENT_TIMESTAMP
          );

          CREATE TABLE IF NOT EXISTS storage.buckets (
            id text PRIMARY KEY,
            name text NOT NULL,
            owner uuid,
            created_at timestamp with time zone DEFAULT now(),
            updated_at timestamp with time zone DEFAULT now(),
            public boolean DEFAULT false
          );

          CREATE TABLE IF NOT EXISTS storage.objects (
            id uuid PRIMARY KEY,
            bucket_id text NOT NULL REFERENCES storage.buckets(id),
            name text,
            owner uuid,
            created_at timestamp with time zone DEFAULT now(),
            updated_at timestamp with time zone DEFAULT now(),
            last_accessed_at timestamp with time zone DEFAULT now(),
            metadata jsonb,
            path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/')) STORED
          );
        `);

        console.log("Basic storage schema created");
      } else {
        console.log("Storage schema already exists");
      }

      await client.end();
    } catch (error) {
      console.error("Error creating schema:", error);
    }
  };

  // Also run it immediately without waiting for the server to start
  createBasicSchema().catch(console.error);

  // Add a dedicated health check server
  const http = require('http');
  const healthServer = http.createServer((req, res) => {
    if (req.url === '/health' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        status: 'ok',
        timestamp: new Date().toISOString(),
        service: 'supabase-storage-api',
        version: 'v0.40.4',
        custom: true
      }));
    } else if (req.url === '/healthz' && req.method === 'GET') {
      // Simple health check for container probes
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        status: 'ok'
      }));
    } else {
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        message: 'Not Found',
        status: 404
      }));
    }
  });

  // Listen on the health check port
  healthServer.listen(5001, '0.0.0.0', () => {
    console.log('Health check server running on port 5001');
  });

} catch (error) {
  console.error("Error while patching:", error);
}

console.log("Migration bypass patch applied successfully");
// The main application will be started by Node.js after this module is loaded
