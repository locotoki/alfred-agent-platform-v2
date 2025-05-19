# YouTube Workflow : 1. Niche-Scout

| 1 | **Niche-Scout** | Emerging sub-niches, trending topics, and strategic gaps on YouTube by analyzing categories, views, engagement metrics, and creator payoffs. | Focuses your channel on high-growth or underserved areas—maximizing discovery and early-mover advantage. | Embed-based clustering + competitive gap scoring: automatically surface micro-niches that similar channels haven’t yet explored. |
| --- | --- | --- | --- | --- |

Overall the 3-step wizard matches the typical flow we’ve been using for Niche-Scout:

| Workflow intent | Proposed step | Fit? | Notes |
| --- | --- | --- | --- |
| **Capture the niche idea** (theme, problem, audience) | **Step 1 · Define Niche** | ✔ | Make sure you surface example niches + real-time “niche score” hint so users know what “good” looks like. |
| **Tune the research crawl / scrape** (geo, language, data sources, budgets) | **Step 2 · Research Parameters** | ✔ | Add conditional fields (e.g., show “Amazon keywords” only if the Amazon source is toggled on). A collapsible “Advanced” section keeps the screen light. |
| **Confirm settings, cost & ETA** | **Step 3 · Review & Run** | ✔ | Show a diff-style summary (“You’ll pull 3 000 Reddit posts · est. 0.28 credits”). Allow **Save draft** and **Run later** buttons. |

### Thoughts on the enhanced features

- **Subcategory dropdown** – Good; pre-populate from the ontology so we don’t end up with typos.
- **Help text** – Keep it inline (micro-copy) rather than a long sidebar; users skim.
- **Animated transitions** – Use subtle slide/fade (≤ 300 ms) so it feels polished but not sluggish. Disable when `prefers-reduced-motion`.
- **Visual hierarchy** – Primary action at bottom-right (`Next`, `Run`) with ghost `Back` button on the left. Highlight the progress bar with step labels.

### Extra tweaks worth adding

1. **Autosave per step** → if the user closes the tab we keep their draft.
2. **Keyboard shortcuts** → Enter = Next, ⌘/Ctrl + ←/→ to navigate.
3. **Pre-filled templates** (“SaaS productivity niche”) for new users.
4. **Error-state preview** → if required fields are missing, shake the card and scroll to first invalid input.
5. **Post-run page** → redirect straight to results dashboard with a toast “Your scout is running; ETA 4 min.”

[YouTube Workflow #1 : Research Scenario Samples](YouTube%20Workflow%20#1%20Research%20Scenario%20Samples%201ebb4fd21ff08024b5cccb3543a3029e.md)

[YouTube Workflow #1 :  Integration - Technical Specifications](YouTube%20Workflow%20#1%20Integration%20-%20Technical%20Specif%201ebb4fd21ff08077b57afc214319e793.md)

[**Possible research sources & methods** ](Possible%20research%20sources%20&%20methods%201ebb4fd21ff08095b585e8ffd3821158.md)
