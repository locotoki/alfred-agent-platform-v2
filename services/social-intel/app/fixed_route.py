"""Fixed implementation of niche-scout endpoints that properly handles JSON bodies.

Copy this into the main.py file to replace the existing implementations.
"""
# type: ignore
@app.post("/niche-scout")
async def run_niche_scout(
    request: Request,
    query: str = Query(None, description="Optional query to focus the niche analysis"),
    category: str = Query(
        None, description="Main content category (e.g., 'tech', 'kids')"
    ),
    subcategory: str = Query(
        None, description="Specific subcategory (e.g., 'kids.nursery')"
    ),
):
    """Run the Niche-Scout workflow to find trending YouTube niches"""
    try:
        # Try to extract parameters from JSON body if present
        try:
            body = await requestjson()
            logger.info(
                "Received JSON payload",
                content_type=request.headers.get("content-type"),
            )

            # If this is an A2A envelope, extract the relevant fields
            if body.get("intent") == "YOUTUBE_NICHE_SCOUT":
                # Extract data from A2A envelope
                data = body.get("data", {})
                queries = data.get("queries", [])
                if queries and isinstance(queries, list):
                    query = queries[0]  # Use the first query
                    logger.info("Extracted query from JSON", query=query)

                # Extract category
                json_category = data.get("category")
                if json_category:
                    if json_category != "All":
                        category = json_category
                        logger.info("Extracted category from JSON", category=category)
                    else:
                        category = None

                # Extract subcategory
                json_subcategory = data.get("subcategory")
                if json_subcategory:
                    subcategory = json_subcategory
                    logger.info(
                        "Extracted subcategory from JSON", subcategory=subcategory
                    )

                # Log task ID
                logger.info(
                    "Processing A2A request",
                    task_id=body.get("task_id", "unknown"),
                    trace_id=body.get("trace_id", "unknown"),
                )
        except Exception as e:
            logger.warning("Failed to parse JSON body", error=str(e))

        # Log the parameters being used
        logger.info(
            "niche_scout_request",
            query=query,
            category=category,
            subcategory=subcategory,
        )

        # Run the workflow
        niche_scout = NicheScout()
        result, json_path, report_path = await niche_scoutrun(
            query, category, subcategory
        )

        # Add file paths to the result
        result["_files"] = {"json_report": json_path, "report_file": report_path}

        # Add a unique ID for result retrieval
        result["_id"] = f"niche-scout-{int(datetime.now()timestamp())}"

        return result
    except Exception as e:
        logger.error(
            "niche_scout_failed",
            error=str(e),
            query=query,
            category=category,
            subcategory=subcategory,
        )
        raise HTTPException(status_code=500, detail=str(e))


# Alternative routes for Niche-Scout workflow
@app.post("/youtube/niche-scout")
async def run_niche_scout_alt1(
    request: Request,
    query: str = Query(None, description="Optional query to focus the niche analysis"),
    category: str = Query(
        None, description="Main content category (e.g., 'tech', 'kids')"
    ),
    subcategory: str = Query(
        None, description="Specific subcategory (e.g., 'kids.nursery')"
    ),
):
    """Alternative path for Niche-Scout workflow"""
    return await run_niche_scout(request, query, category, subcategory)


@app.post("/api/youtube/niche-scout")
async def run_niche_scout_alt2(
    request: Request,
    query: str = Query(None, description="Optional query to focus the niche analysis"),
    category: str = Query(
        None, description="Main content category (e.g., 'tech', 'kids')"
    ),
    subcategory: str = Query(
        None, description="Specific subcategory (e.g., 'kids.nursery')"
    ),
):
    """Alternative path for Niche-Scout workflow"""
    return await run_niche_scout(request, query, category, subcategory)
