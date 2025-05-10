/**
 * Nightly Opportunity Scorer for Social Intelligence Features Table
 * 
 * This script:
 * 1. Connects to the PostgreSQL database
 * 2. Updates the opportunity score for all features
 * 3. Refreshes the hot_niches_today materialized view
 * 4. Logs success metrics
 */

import { Client } from 'pg';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Define scoring formula constants
const MIN_SUPPLY_SCORE = 0.01; // Prevent division by zero

/**
 * Main scoring function
 */
async function scoreFeatures() {
  const startTime = Date.now();
  console.log('🚀 Starting nightly opportunity scoring...');
  console.log(`⏱️  Started at: ${new Date().toISOString()}`);
  
  // Create database client
  const client = new Client({
    connectionString: process.env.DATABASE_URL,
  });
  
  try {
    // Connect to the database
    await client.connect();
    console.log('✅ Connected to database');
    
    // Start a transaction
    await client.query('BEGIN');
    
    // Update opportunity scores
    // Formula: opportunity = (demand_score * monetise_score) / MAX(supply_score, 0.01)
    const updateResult = await client.query(`
      UPDATE features
      SET opportunity = (demand_score * monetise_score) / GREATEST(supply_score, $1),
          updated_at = now()
      RETURNING niche_id;
    `, [MIN_SUPPLY_SCORE]);
    
    const rowCount = updateResult.rowCount;
    console.log(`✅ Updated opportunity scores for ${rowCount} niches`);
    
    // Refresh materialized view
    console.log('🔄 Refreshing hot_niches_today materialized view...');
    const refreshStart = Date.now();
    await client.query('REFRESH MATERIALIZED VIEW hot_niches_today');
    const refreshDuration = Date.now() - refreshStart;
    console.log(`✅ Refreshed materialized view in ${refreshDuration}ms`);
    
    // Commit transaction
    await client.query('COMMIT');
    
    // Log stats about the top niches
    const topNichesResult = await client.query(`
      SELECT phrase, opportunity
      FROM hot_niches_today
      ORDER BY opportunity DESC
      LIMIT 5;
    `);
    
    console.log('🔝 Top 5 niches by opportunity:');
    topNichesResult.rows.forEach((row, index) => {
      console.log(`   ${index + 1}. ${row.phrase} (score: ${row.opportunity.toFixed(4)})`);
    });
    
  } catch (error) {
    // Rollback transaction in case of error
    await client.query('ROLLBACK');
    console.error('❌ Error scoring features:', error);
    process.exit(1);
  } finally {
    // Close database connection
    await client.end();
    console.log('🔌 Closed database connection');
    
    // Log total duration
    const duration = Date.now() - startTime;
    console.log(`✅ Completed nightly scoring in ${duration}ms`);
  }
}

// Run the scoring function
scoreFeatures().catch(err => {
  console.error('❌ Unhandled error:', err);
  process.exit(1);
});