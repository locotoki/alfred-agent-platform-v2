# Niche‑Scout Change Rationale & Success Metrics

*Version: 2025‑05‑08*

This concise artifact maps each major change to the problem it solves and the KPI that proves success. Keep it updated with every significant PR.

| Epic / PR ID      | Pain Point (before)                       | Change Description                                                                 | Success Metric & Target                         | Owner              |
| ----------------- | ----------------------------------------- | ---------------------------------------------------------------------------------- | ----------------------------------------------- | ------------------ |
| **QUEUE‑SSE‑01**  | Wizard UI froze for ≥20 s during analysis | Introduce BullMQ job queue + Server‑Sent Events; progress bar in UI                | 95 % of runs emit first progress event ≤ 800 ms | @backend‑dev       |
| **SCORE‑FUNC‑02** | "Hot niches" felt random & irrelevant     | Implement `opportunityScore = demand × RPM ÷ supply`; expose sub‑scores in tooltip | User survey relevance ≥ 4 / 5                   | @data‑scientist    |
| **EST‑ACC‑03**    | Cost/duration estimates off by 30–70 %    | Log `actualCost` & `actualDuration`; display Δ % badge                             | Δ % ≤ 10 % for 90 % of jobs                     | @full‑stack        |
| **VIS‑BUBBLE‑04** | Results lacked visual insight             | Add Recharts bubble map (x=competition, y=growth, r=views) with filter chips       | 80 % of beta users interact ≥ 1 bubble per run  | @frontend‑dev      |
| **ROI‑LOOP‑05**   | No learning from published content        | Connect YouTube OAuth; pull stats; weekly model retrain                            | Avg 14‑day view growth +25 % over baseline      | @data‑science‑lead |

---

### How to use this document

* **Link each PR** to a row. If a change spans multiple epics, duplicate the row with granular metrics.
* **Update the metric column** as soon as the first measurement window closes.
* During retros, archive rows that met their targets into `/docs/history/`.
