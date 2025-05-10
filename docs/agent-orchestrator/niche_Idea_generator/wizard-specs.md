# Wizard Specifications

## Idea Generator

| Step | Fields | Notes |
|------|--------|-------|
| 1 | Category, Sub‑category, Budget | Category pulled from `/api/taxonomy/hot` |
| 2 | Generate Ideas | Serverless fn returns ≤ 10 titles |
| — | Adopt button | Sends title to Niche‑Scout Wizard |

## Niche‑Scout Wizard

1. **Define Niche** – title, Category ▸ Sub‑category, live score  
2. **Research Params** – data‑source toggles, budget slider, advanced accordions  
3. **Review & Run** – diff summary, cost, ETA, run/draft/later