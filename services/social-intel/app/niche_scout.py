"""
Niche-Scout Workflow Implementation for Social Intelligence Agent.

This module provides functionality to identify fast-growing, high-potential,
and Shorts-friendly YouTube niches on a daily basis.
"""

import asyncio
import json
import os
import time
from datetime import datetime
from typing import Dict, List, Any, Optional, Tuple

import structlog

# Use simple reports instead of HTML templates
from app.simple_reports import generate_niche_scout_report
from app.youtube_api import get_trends_by_category, YouTubeAPIError
from app.database import niche_repository
from app.metrics import SI_REQUESTS_TOTAL, SI_LATENCY_SECONDS, NICHE_SCOUT_RESULTS_COUNT, NICHE_OPPORTUNITY_SCORE, LatencyTimer

logger = structlog.get_logger(__name__)

class NicheScout:
    """Implements the Niche-Scout workflow for YouTube trend analysis."""
    
    def __init__(self, output_dir: str = "/app/data/niche_scout"):
        """Initialize the NicheScout workflow.
        
        Args:
            output_dir: Directory to store output data and results
        """
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)
        self.logger = logger.bind(component="niche_scout")
        self.logger.info("Initialized NicheScout workflow", output_dir=output_dir)
        
    async def run(self, query: Optional[str] = None, category: Optional[str] = None, 
             subcategory: Optional[str] = None) -> Tuple[Dict[str, Any], str, str]:
        """Run the full Niche-Scout analysis workflow.
        
        Args:
            query: Optional query to focus the niche analysis
            category: Optional main content category to analyze (e.g. "tech", "kids")
            subcategory: Optional subcategory for more specific analysis (e.g. "kids.nursery")
            
        Returns:
            Tuple containing:
                - Dictionary with results of the niche analysis
                - Path to the JSON data file
                - Path to the HTML report
        """
        self.logger.info("Starting NicheScout workflow", 
                        query=query, 
                        category=category, 
                        subcategory=subcategory)
        
        # Track total request count
        SI_REQUESTS_TOTAL.labels(endpoint="/niche-scout", status="started").inc()
        
        results = None
        
        # Use latency timer to track request duration
        with LatencyTimer(SI_LATENCY_SECONDS, {"endpoint": "/niche-scout"}):
            try:
                # First, try to get hot niches from the database
                db_niches = await niche_repository.get_hot_niches(50)
                self.logger.info("Retrieved niches from database", count=len(db_niches))
                
                if db_niches and len(db_niches) > 0:
                    # If we have data in the database, use it
                    self.logger.info("Using niches from database")
                    
                    # Convert database results to expected format
                    trending_niches = []
                    for niche in db_niches:
                        # Record opportunity score in metrics
                        NICHE_OPPORTUNITY_SCORE.observe(float(niche["opportunity"]))
                        
                        # Format to match expected structure
                        niche_data = {
                            "query": niche["phrase"],
                            "view_sum": int(1000000 * niche["demand_score"]),
                            "rsv": float(niche["demand_score"]),
                            "view_rank": db_niches.index(niche) + 1,
                            "rsv_rank": db_niches.index(niche) + 1,
                            "score": float(niche["opportunity"]),
                            "x": float(db_niches.index(niche) * 10),
                            "y": float(100 - (db_niches.index(niche) * 15)),
                            "niche": db_niches.index(niche) % 5 + 1
                        }
                        trending_niches.append(niche_data)
                    
                    results = {
                        "run_date": datetime.now().isoformat(),
                        "trending_niches": trending_niches,
                        "top_niches": trending_niches[:5],
                        "visualization_url": "https://example.com/visualization",
                        "actual_cost": 0.10,  # Low cost since using database
                        "actual_processing_time": 5.5  # Database queries are fast
                    }
                    
                    # Update metrics with result count
                    NICHE_SCOUT_RESULTS_COUNT.set(len(trending_niches))
                    
                    self.logger.info("Successfully processed niches from database",
                                  niches_count=len(trending_niches))
                    
                    # Record success
                    SI_REQUESTS_TOTAL.labels(endpoint="/niche-scout", status="success").inc()
                else:
                    # If database is empty, fall back to API or simulated data
                    self.logger.warning("No niches found in database, falling back to other sources")
                    
                    # Use YouTube API if available, otherwise fall back to simulated data
                    youtube_api_key = os.environ.get("YOUTUBE_API_KEY")
                    if not youtube_api_key:
                        self.logger.warning("No YouTube API key found, using simulated data")
                        results = self._generate_simulated_results(query, category, subcategory)
                    else:
                        try:
                            # Use real YouTube API to get trends
                            self.logger.info("Using YouTube API to get trends", 
                                          api_key_length=len(youtube_api_key))
                            api_results = await get_trends_by_category(
                                category=category,
                                subcategory=subcategory,
                                region_code="US",
                                max_results=20
                            )
                            
                            # Format results to match our expected output structure
                            results = {
                                "run_date": datetime.now().isoformat(),
                                "trending_niches": api_results.get("trending_niches", []),
                                "top_niches": api_results.get("top_niches", []),
                                "visualization_url": "https://example.com/visualization",
                                "actual_cost": 95.50,  # This would be calculated based on actual API usage
                                "actual_processing_time": 120.5  # This would be the actual time taken
                            }
                            
                            # Also add results to database for future use
                            for i, niche in enumerate(api_results.get("trending_niches", [])):
                                try:
                                    # Extract normalized scores from the API results
                                    phrase = niche.get("query", "")
                                    demand_score = niche.get("rsv", 0.5)
                                    # Use position to estimate monetization and supply scores
                                    position_factor = 1.0 - (i / len(api_results.get("trending_niches", [])))
                                    monetise_score = 0.7 + (position_factor * 0.3)
                                    supply_score = 0.3 + (position_factor * 0.3)
                                    
                                    # Insert into database
                                    await niche_repository.insert_feature(
                                        phrase=phrase,
                                        demand_score=demand_score,
                                        monetise_score=monetise_score,
                                        supply_score=supply_score
                                    )
                                except Exception as e:
                                    self.logger.error("Failed to save niche to database", 
                                                  niche=niche.get("query"), error=str(e))
                            
                            # Update metrics with result count
                            NICHE_SCOUT_RESULTS_COUNT.set(len(results.get("trending_niches", [])))
                            
                            self.logger.info("Successfully retrieved trends from YouTube API",
                                          niches_count=len(results.get("trending_niches", [])))
                            
                            # Record success
                            SI_REQUESTS_TOTAL.labels(endpoint="/niche-scout", status="success").inc()
                        except YouTubeAPIError as e:
                            # Log the error and fall back to simulated data
                            self.logger.error("YouTube API error, falling back to simulated data", 
                                           error=str(e))
                            results = self._generate_simulated_results(query, category, subcategory)
                            
                            # Record API error
                            SI_REQUESTS_TOTAL.labels(endpoint="/niche-scout", status="api_error").inc()
            except Exception as e:
                # If there's any error with the database, fall back to simulated data
                self.logger.error("Database error, falling back to simulated data", error=str(e))
                results = self._generate_simulated_results(query, category, subcategory)
                
                # Record database error
                SI_REQUESTS_TOTAL.labels(endpoint="/niche-scout", status="db_error").inc()
        
        # If we still don't have results due to some error, generate simulated data
        if results is None:
            self.logger.error("Failed to get results, using simulated data as last resort")
            results = self._generate_simulated_results(query, category, subcategory)
            
            # Record fallback
            SI_REQUESTS_TOTAL.labels(endpoint="/niche-scout", status="fallback").inc()
        
        # Save JSON results
        timestamp = int(time.time())
        filename = f"niche_analysis_{timestamp}.json"
        filepath = os.path.join(self.output_dir, filename)
        
        with open(filepath, "w") as f:
            json.dump(results, f, indent=2)
        
        # Generate report
        report_path = generate_niche_scout_report(results, self.output_dir)
            
        self.logger.info("NicheScout workflow completed", 
                         json_file=filepath,
                         report_file=report_path,
                         num_niches=len(results.get("trending_niches", [])),
                         category=category,
                         subcategory=subcategory)
        
        return results, filepath, report_path
    
    def _generate_simulated_results(self, query: Optional[str] = None, 
                               category: Optional[str] = None, 
                               subcategory: Optional[str] = None) -> Dict[str, Any]:
        """Generate simulated niche analysis results for demonstration.
        
        Args:
            query: Optional query to customize the simulated results
            category: Optional main content category to analyze
            subcategory: Optional subcategory for more specific analysis
            
        Returns:
            Dictionary with simulated niche analysis results
        """
        now = datetime.now().strftime("%Y-%m-%d")
        
        # Base niches for general results (used when no category specified)
        base_niches = [
            {
                "name": "Financial Literacy Shorts",
                "growth_rate": 87.5,
                "shorts_friendly": True,
                "competition_level": "Medium",
                "viewer_demographics": {
                    "age_groups": ["18-24", "25-34"],
                    "gender_split": {"male": 65, "female": 35}
                },
                "trending_topics": [
                    "Stock market tips",
                    "Passive income ideas", 
                    "Investing for beginners"
                ],
                "top_channels": [
                    {"name": "FinanceQuick", "subs": 2800000},
                    {"name": "MoneyMinute", "subs": 1400000}
                ]
            },
            {
                "name": "DIY Home Improvement",
                "growth_rate": 62.3,
                "shorts_friendly": True,
                "competition_level": "High",
                "viewer_demographics": {
                    "age_groups": ["25-34", "35-44"],
                    "gender_split": {"male": 55, "female": 45}
                },
                "trending_topics": [
                    "Quick home repairs",
                    "Budget renovations",
                    "IKEA hacks"
                ],
                "top_channels": [
                    {"name": "QuickFixDIY", "subs": 3500000},
                    {"name": "HomeTricks", "subs": 2100000}
                ]
            },
            {
                "name": "Tech Review Shorts",
                "growth_rate": 78.9,
                "shorts_friendly": True,
                "competition_level": "Very High",
                "viewer_demographics": {
                    "age_groups": ["18-24", "25-34"],
                    "gender_split": {"male": 75, "female": 25}
                },
                "trending_topics": [
                    "Smartphone comparisons",
                    "Tech gadget unboxings",
                    "Hidden features"
                ],
                "top_channels": [
                    {"name": "TechIn60", "subs": 5200000},
                    {"name": "GadgetSnap", "subs": 3800000}
                ]
            }
        ]
        
        # Category-specific niches
        category_niches = {
            "kids": [
                {
                    "name": "Nursery Rhymes & Songs",
                    "growth_rate": 95.2,
                    "shorts_friendly": True,
                    "competition_level": "High",
                    "viewer_demographics": {
                        "age_groups": ["0-2", "3-5", "25-34"],
                        "gender_split": {"male": 40, "female": 60}
                    },
                    "trending_topics": [
                        "Alphabet songs",
                        "Counting songs",
                        "Bedtime lullabies"
                    ],
                    "top_channels": [
                        {"name": "KidsSongs", "subs": 8500000},
                        {"name": "LittleRhymes", "subs": 6200000}
                    ]
                },
                {
                    "name": "Educational Cartoons",
                    "growth_rate": 88.7,
                    "shorts_friendly": True,
                    "competition_level": "Very High",
                    "viewer_demographics": {
                        "age_groups": ["3-5", "6-8", "25-34"],
                        "gender_split": {"male": 45, "female": 55}
                    },
                    "trending_topics": [
                        "Alphabet learning",
                        "Number learning",
                        "Animal facts"
                    ],
                    "top_channels": [
                        {"name": "KidsLearn", "subs": 7800000},
                        {"name": "TinyToons", "subs": 5500000}
                    ]
                },
                {
                    "name": "Toys & Unboxing",
                    "growth_rate": 82.5,
                    "shorts_friendly": True,
                    "competition_level": "High",
                    "viewer_demographics": {
                        "age_groups": ["3-5", "6-8", "25-34"],
                        "gender_split": {"male": 40, "female": 60}
                    },
                    "trending_topics": [
                        "Surprise toys",
                        "New toy releases",
                        "Educational toys"
                    ],
                    "top_channels": [
                        {"name": "ToyOpenings", "subs": 6200000},
                        {"name": "KidsToyReview", "subs": 4800000}
                    ]
                },
                {
                    "name": "Baby Sensory Videos",
                    "growth_rate": 78.3,
                    "shorts_friendly": False,
                    "competition_level": "Medium",
                    "viewer_demographics": {
                        "age_groups": ["0-2", "25-34"],
                        "gender_split": {"male": 30, "female": 70}
                    },
                    "trending_topics": [
                        "Baby visual stimulation",
                        "Calming baby videos",
                        "Early development"
                    ],
                    "top_channels": [
                        {"name": "BabySenses", "subs": 3200000},
                        {"name": "TinyWonders", "subs": 2100000}
                    ]
                }
            ],
            "tech": [
                {
                    "name": "Gaming PC Builds",
                    "growth_rate": 91.2,
                    "shorts_friendly": True,
                    "competition_level": "High",
                    "viewer_demographics": {
                        "age_groups": ["18-24", "25-34"],
                        "gender_split": {"male": 80, "female": 20}
                    },
                    "trending_topics": [
                        "Budget gaming PCs",
                        "RTX 40 series builds",
                        "RGB setups"
                    ],
                    "top_channels": [
                        {"name": "TechBuilds", "subs": 5800000},
                        {"name": "PCMasterRace", "subs": 4200000}
                    ]
                },
                {
                    "name": "Smartphone Reviews",
                    "growth_rate": 87.5,
                    "shorts_friendly": True,
                    "competition_level": "Very High",
                    "viewer_demographics": {
                        "age_groups": ["18-24", "25-34", "35-44"],
                        "gender_split": {"male": 70, "female": 30}
                    },
                    "trending_topics": [
                        "iPhone vs Android",
                        "Camera comparisons",
                        "Battery life tests"
                    ],
                    "top_channels": [
                        {"name": "TechReviewPro", "subs": 8900000},
                        {"name": "PhoneCompare", "subs": 6700000}
                    ]
                }
            ]
        }
        
        # Subcategory-specific niches
        subcategory_niches = {
            "kids.nursery": [
                {
                    "name": "Classic Nursery Rhymes",
                    "growth_rate": 97.3,
                    "shorts_friendly": True,
                    "competition_level": "High",
                    "viewer_demographics": {
                        "age_groups": ["0-2", "3-5", "25-34"],
                        "gender_split": {"male": 35, "female": 65}
                    },
                    "trending_topics": [
                        "Traditional songs",
                        "Animation versions",
                        "Classic characters"
                    ],
                    "top_channels": [
                        {"name": "ClassicKidsSongs", "subs": 9200000},
                        {"name": "RhymeTime", "subs": 7400000}
                    ]
                },
                {
                    "name": "Lullabies & Sleeping Songs",
                    "growth_rate": 93.8,
                    "shorts_friendly": False,
                    "competition_level": "Medium",
                    "viewer_demographics": {
                        "age_groups": ["0-2", "25-34"],
                        "gender_split": {"male": 30, "female": 70}
                    },
                    "trending_topics": [
                        "Bedtime songs",
                        "Relaxing music for babies",
                        "Sleep aids"
                    ],
                    "top_channels": [
                        {"name": "SleepyTunes", "subs": 5800000},
                        {"name": "BabyLullaby", "subs": 4100000}
                    ]
                },
                {
                    "name": "Educational Nursery Songs",
                    "growth_rate": 94.7,
                    "shorts_friendly": True,
                    "competition_level": "High",
                    "viewer_demographics": {
                        "age_groups": ["2-4", "4-6", "25-34"],
                        "gender_split": {"male": 40, "female": 60}
                    },
                    "trending_topics": [
                        "ABC songs",
                        "Counting songs",
                        "Shape and color songs"
                    ],
                    "top_channels": [
                        {"name": "LearnWithSongs", "subs": 8500000},
                        {"name": "KidsEduTunes", "subs": 6700000}
                    ]
                },
                {
                    "name": "Nursery Rhyme Compilations",
                    "growth_rate": 90.6,
                    "shorts_friendly": False,
                    "competition_level": "Medium",
                    "viewer_demographics": {
                        "age_groups": ["0-2", "3-5", "25-34"],
                        "gender_split": {"male": 35, "female": 65}
                    },
                    "trending_topics": [
                        "30+ minute collections",
                        "Theme-based collections",
                        "Road trip compilations"
                    ],
                    "top_channels": [
                        {"name": "KidsSongMix", "subs": 7200000},
                        {"name": "RhymeCollection", "subs": 5500000}
                    ]
                }
            ]
        }
        
        # Start with base niches
        niches = base_niches.copy()
        
        # Add category-specific niches
        if category and category in category_niches:
            niches.extend(category_niches[category])
        
        # Add subcategory-specific niches (these are more specific)
        if subcategory and subcategory in subcategory_niches:
            niches.extend(subcategory_niches[subcategory])
        
        # Add query-specific niches
        if query:
            query = query.lower()
            # Kids content related queries
            if "nursery" in query or "rhyme" in query or "toddler" in query:
                if not any(n["name"] == "Classic Nursery Rhymes" for n in niches):
                    niches.append({
                        "name": "Classic Nursery Rhymes",
                        "growth_rate": 97.3,
                        "shorts_friendly": True,
                        "competition_level": "High",
                        "viewer_demographics": {
                            "age_groups": ["0-2", "3-5", "25-34"],
                            "gender_split": {"male": 35, "female": 65}
                        },
                        "trending_topics": [
                            "Traditional songs",
                            "Animation versions",
                            "Classic characters"
                        ],
                        "top_channels": [
                            {"name": "ClassicKidsSongs", "subs": 9200000},
                            {"name": "RhymeTime", "subs": 7400000}
                        ]
                    })
            # Gaming related queries
            if "gaming" in query:
                niches.append({
                    "name": "Mobile Gaming Tips",
                    "growth_rate": 92.1,
                    "shorts_friendly": True,
                    "competition_level": "High",
                    "viewer_demographics": {
                        "age_groups": ["13-17", "18-24"],
                        "gender_split": {"male": 80, "female": 20}
                    },
                    "trending_topics": [
                        "PUBG Mobile tactics",
                        "Minecraft builds",
                        "Roblox secrets"
                    ],
                    "top_channels": [
                        {"name": "GameShorts", "subs": 4700000},
                        {"name": "MobileMasters", "subs": 2900000}
                    ]
                })
            # Food related queries
            if "food" in query or "cooking" in query:
                niches.append({
                    "name": "Quick Recipe Shorts",
                    "growth_rate": 84.6,
                    "shorts_friendly": True,
                    "competition_level": "Medium",
                    "viewer_demographics": {
                        "age_groups": ["18-24", "25-34", "35-44"],
                        "gender_split": {"male": 30, "female": 70}
                    },
                    "trending_topics": [
                        "5-minute meals",
                        "Viral food hacks",
                        "Air fryer recipes"
                    ],
                    "top_channels": [
                        {"name": "QuickBites", "subs": 3200000},
                        {"name": "SpeedyChef", "subs": 1800000}
                    ]
                })
            # Fitness related queries    
            if "fitness" in query or "workout" in query:
                niches.append({
                    "name": "Quick Fitness Routines",
                    "growth_rate": 79.8,
                    "shorts_friendly": True,
                    "competition_level": "High",
                    "viewer_demographics": {
                        "age_groups": ["18-24", "25-34"],
                        "gender_split": {"male": 40, "female": 60}
                    },
                    "trending_topics": [
                        "30-second ab workouts",
                        "No-equipment exercises",
                        "Posture correction"
                    ],
                    "top_channels": [
                        {"name": "FitIn30", "subs": 2900000},
                        {"name": "QuickFitness", "subs": 1700000}
                    ]
                })
        
        # Sort niches by growth rate
        niches.sort(key=lambda x: x["growth_rate"], reverse=True)
        
        # Limit to top 10 for cleaner results
        niches = niches[:10]
        
        # Build the final results
        return {
            "date": now,
            "query": query,
            "category": category,
            "subcategory": subcategory,
            "niches": niches,
            "analysis_summary": {
                "fastest_growing": niches[0]["name"],
                "most_shorts_friendly": next((n["name"] for n in niches if n.get("shorts_friendly", False)), niches[0]["name"]),
                "lowest_competition": next((n["name"] for n in niches if n.get("competition_level") == "Medium"), niches[0]["name"])
            },
            "recommendations": [
                f"Focus on {niches[0]['name']} for highest growth potential",
                "Create content under 60 seconds for optimal Shorts performance",
                "Target trending topics with high search volume but moderate competition"
            ]
        }