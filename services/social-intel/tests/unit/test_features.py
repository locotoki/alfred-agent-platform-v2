"""
Unit tests for the features table and opportunity scoring.
"""

import asyncio
import os
from datetime import datetime

import asyncpg
import pytest

# Set test database URL
os.environ["DATABASE_URL"] = os.environ.get(
    "DATABASE_URL", "postgresql://postgres:your-super-secret-password@localhost:5432/postgres"
)

# Import after setting environment variable
from app.database import niche_repository


@pytest.fixture
async def test_db():
    """Set up test database with sample data."""
    # Create a connection
    conn = await asyncpg.connect(os.environ["DATABASE_URL"])

    # Create schema if not exists
    with open("db/schema.sql", "r") as f:
        schema_sql = f.read()

    # Execute schema
    await conn.execute(schema_sql)

    # Clear existing test data
    await conn.execute("DELETE FROM features WHERE phrase LIKE 'TEST_%'")

    # Insert test data
    await conn.execute(
        """
    INSERT INTO features (phrase, demand_score, monetise_score, supply_score)
    VALUES 
      ('TEST_Gaming', 0.8000, 0.7500, 0.5000),
      ('TEST_Cooking', 0.7000, 0.8000, 0.6000)
    """
    )

    yield conn

    # Clean up
    await conn.execute("DELETE FROM features WHERE phrase LIKE 'TEST_%'")
    await conn.close()


@pytest.mark.asyncio
async def test_get_hot_niches(test_db):
    """Test retrieving hot niches from the database."""
    # Refresh materialized view
    await test_db.execute("REFRESH MATERIALIZED VIEW hot_niches_today")

    # Get niches
    niches = await niche_repository.get_hot_niches(10)

    # Check that we got results
    assert len(niches) > 0

    # Check that our test niches are included
    test_niches = [n for n in niches if n["phrase"].startswith("TEST_")]
    assert len(test_niches) == 2

    # Verify structure
    for niche in test_niches:
        assert "niche_id" in niche
        assert "phrase" in niche
        assert "demand_score" in niche
        assert "monetise_score" in niche
        assert "supply_score" in niche
        assert "opportunity" in niche
        assert "updated_at" in niche


@pytest.mark.asyncio
async def test_insert_feature(test_db):
    """Test inserting a new feature."""
    # Insert a new test feature
    test_phrase = f"TEST_NewFeature_{int(datetime.now().timestamp())}"
    feature = await niche_repository.insert_feature(
        phrase=test_phrase, demand_score=0.9000, monetise_score=0.8500, supply_score=0.4000
    )

    # Verify the returned feature
    assert feature is not None
    assert feature["phrase"] == test_phrase
    assert feature["demand_score"] == 0.9000
    assert feature["monetise_score"] == 0.8500
    assert feature["supply_score"] == 0.4000

    # Verify opportunity score calculation
    expected_opportunity = (0.9000 * 0.8500) / 0.4000
    assert abs(float(feature["opportunity"]) - expected_opportunity) < 0.0001

    # Verify it exists in the database
    row = await test_db.fetchrow("SELECT * FROM features WHERE phrase = $1", test_phrase)
    assert row is not None
    assert row["phrase"] == test_phrase


@pytest.mark.asyncio
async def test_update_feature_scores(test_db):
    """Test updating feature scores and opportunity calculation."""
    # First, get the niche ID for TEST_Gaming
    row = await test_db.fetchrow("SELECT niche_id FROM features WHERE phrase = 'TEST_Gaming'")
    niche_id = row["niche_id"]

    # Update scores
    result = await niche_repository.update_feature_scores(
        niche_id=niche_id, demand_score=0.9500, monetise_score=0.8000, supply_score=0.6000
    )

    # Verify update was successful
    assert result is True

    # Verify new values in database
    row = await test_db.fetchrow("SELECT * FROM features WHERE niche_id = $1", niche_id)
    assert row["demand_score"] == 0.9500
    assert row["monetise_score"] == 0.8000
    assert row["supply_score"] == 0.6000

    # Verify opportunity score calculation
    expected_opportunity = (0.9500 * 0.8000) / 0.6000
    assert abs(float(row["opportunity"]) - expected_opportunity) < 0.0001

    # Verify updated_at was changed
    assert row["updated_at"] > datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
