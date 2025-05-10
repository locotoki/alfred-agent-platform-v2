# Taxonomy Rules

Table: `taxonomy_dynamic`

| Column | Type | Description |
|--------|------|-------------|
| category | text | Macro category |
| subcategory | text | Leaf |
| opportunity_score | numeric | 0‑1 scaled |
| rpm | numeric | Projected revenue per mille |
| growth | numeric | 30‑day demand delta |
| supply_gap | numeric | 0‑1 |

Cron refresh daily 06:00 UTC.

### Scoring weights

* rpm × 0.4
* growth × 0.35
* supply_gap × 0.25