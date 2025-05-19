/**
 * Seed Features Table Script
 *
 * This script reads from seed/initial_features.csv and inserts data into the features table.
 * It skips existing entries to avoid duplicates on re-runs.
 */

import { Client } from 'pg';
import fs from 'fs';
import path from 'path';
import { parse } from 'csv-parse';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Type for CSV rows
interface FeatureData {
  phrase: string;
  demand_score: number;
  monetise_score: number;
  supply_score: number;
}

/**
 * Main seeding function
 */
async function seedFeatures() {
  console.log('🌱 Starting features table seeding process...');
  const startTime = Date.now();

  // Create database client
  const client = new Client({
    connectionString: process.env.DATABASE_URL,
  });

  try {
    // Connect to the database
    await client.connect();
    console.log('✅ Connected to database');

    // Read CSV file
    const csvFilePath = path.resolve(__dirname, '../seed/initial_features.csv');
    const fileContent = fs.readFileSync(csvFilePath, { encoding: 'utf-8' });

    // Parse CSV data
    const records: FeatureData[] = await new Promise((resolve, reject) => {
      parse(fileContent, {
        delimiter: ',',
        columns: true,
        skip_empty_lines: true,
        cast: (value, context) => {
          // Convert numeric columns to numbers
          if (context.column === 'demand_score' ||
              context.column === 'monetise_score' ||
              context.column === 'supply_score') {
            return parseFloat(value);
          }
          // Clean the phrase - remove quotes if present
          if (context.column === 'phrase') {
            return value.replace(/^"(.*)"$/, '$1');
          }
          return value;
        }
      }, (err, result: FeatureData[]) => {
        if (err) reject(err);
        else resolve(result);
      });
    });

    console.log(`📋 Found ${records.length} records in CSV file`);

    // Start a transaction
    await client.query('BEGIN');

    // Insert records that don't already exist
    let insertedCount = 0;
    let skippedCount = 0;

    for (const record of records) {
      // Check if record exists
      const checkResult = await client.query(
        'SELECT 1 FROM features WHERE phrase = $1',
        [record.phrase]
      );

      if (checkResult.rows.length > 0) {
        // Skip existing records
        skippedCount++;
        continue;
      }

      // Calculate initial opportunity score
      const opportunity = (record.demand_score * record.monetise_score) /
                          Math.max(record.supply_score, 0.01);

      // Insert the record
      await client.query(
        `INSERT INTO features (phrase, demand_score, monetise_score, supply_score, opportunity)
         VALUES ($1, $2, $3, $4, $5)`,
        [
          record.phrase,
          record.demand_score,
          record.monetise_score,
          record.supply_score,
          opportunity
        ]
      );

      insertedCount++;
    }

    // Commit transaction
    await client.query('COMMIT');

    console.log(`✅ Inserted ${insertedCount} new records`);
    console.log(`ℹ️  Skipped ${skippedCount} existing records`);

    // Refresh materialized view to include new records
    console.log('🔄 Refreshing hot_niches_today materialized view...');
    await client.query('REFRESH MATERIALIZED VIEW hot_niches_today');
    console.log('✅ Materialized view refreshed');

  } catch (error) {
    // Rollback transaction in case of error
    await client.query('ROLLBACK');
    console.error('❌ Error seeding features:', error);
    process.exit(1);
  } finally {
    // Close database connection
    await client.end();
    console.log('🔌 Closed database connection');

    // Log total duration
    const duration = Date.now() - startTime;
    console.log(`✅ Completed seeding in ${duration}ms`);
  }
}

// Run the seeding function
seedFeatures().catch(err => {
  console.error('❌ Unhandled error:', err);
  process.exit(1);
});
