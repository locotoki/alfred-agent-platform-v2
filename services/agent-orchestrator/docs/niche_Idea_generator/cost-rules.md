# Cost & ETA Rules

```ts
export const COST_PER_SOURCE = {
  youtube : 0.24,
  reddit  : 0.16,
  amazon  : 0.10,
  sentiment: 0.50,
};

export const ETA_BASE_SEC   = 75;
export const ETA_PER_1K_SEC = 60;
export const BUDGET_MIN     = 50;
export const BUDGET_MAX     = 500;
```

### Accuracy target

`|actual - estimate| / estimate < 0.10`
