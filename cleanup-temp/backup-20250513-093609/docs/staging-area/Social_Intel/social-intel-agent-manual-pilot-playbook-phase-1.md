# Social Intel Agent : Manual-Pilot Playbook – Phase 1

# **Manual-Pilot Playbook – Phase 1**

*A copy-paste–ready reference you can drop into Notion (or print to PDF) that starts with pure **research pilots**, then adds the optional “quality & infra” checks. Every section is written in plain English so a non-technical teammate can follow it.*

---

## 📜 Table of Contents

1. **Research Pilots (Core)**
    1. Competitor & Topic Scanner
    2. Trend Pulse Quick-and-Dirty
    3. Retention × Comment Hot-Spot Map
    4. Thumbnail/Title Micro A/B (Insight Run)
    5. Platform Algorithm Pulse
2. **Production & Quality Pilots (Optional)**

    6. Voice Consistency Smoke Test

    7. One-Flow Prefect Dry-Run

3. **Master Database Blueprint (Notion)**
4. **Appendices**
    - Cheat-Sheet Formulas
    - Sample Claude Prompts & Commands
    - Integration-Token Checklist

---

## 1 Research Pilots (Core)

> Goal: Surface insights about topics, trends, audience behaviour, and platform shifts before investing in code.
>
>
> **Suggested order:** Run #1 and #2 first—they feed ideas into everything else.
>

### Pilot 1 Competitor & Topic Scanner – “Gap Finder”

| Item | Details |
| --- | --- |
| **Research Question** | *What high-interest keywords do our competitors rank for that we don’t?* |
| **Primary Output** | `gaps.csv` sorted by “competitor count minus our count”; a short list of video ideas |
| **Time Budget** | 60 min gather  +  30 min colour-code |
| **Tools (choose one)** | **Quick-Copy:** Browser + Google Sheets |
| **Done When** | ≥10 orange “gap” keywords and at least 3 ideas you’re excited to script |

<details>
<summary><strong>Step-by-Step (Quick-Copy mode)</strong></summary>

1. **List 5 competitor channels** you admire.
2. **Create a Google Sheet** with three tabs: *Competitors*, *Your Channel*, *Keyword Pivot*.
3. **Copy the 20 most-popular video titles** from each competitor (Videos → Sort by Popular). Paste into *Competitors* !A.
4. **Paste your own 20 most-popular titles** into *Your Channel* !A.
5. In *Competitors* !C2 type

    ```
    php
    CopyEdit
    =ARRAYFORMULA(LOWER(REGEXREPLACE(A2:A,"[^A-Za-z0-9 ]","")))

    ```

    then in *Competitors* !D2 type

    ```
    php
    CopyEdit
    =ARRAYFORMULA(SPLIT(C2:C," "))

    ```

    (Copy both formulas to *Your Channel*.)

6. **Insert a Pivot Table** in *Keyword Pivot* → Rows = Keyword, Values = COUNTA (do this twice: one per tab).
7. **Conditional-format** cells where Competitor ≥5 **and** You = 0 (bright orange).
8. **Interpret** orange cells → brainstorm 3–5 new video topics.
9. **Log findings** in Notion row (Key Findings + Next Action).

</details>
<details>
<summary><strong>Step-by-Step (Semi-Tech mode)</strong></summary>

See Appendix B for a ready-made `scan_competitors.py`. Claude can run:

```bash
bash
CopyEdit
yt-dlp --flat-playlist --print "%(title)s" <CHANNEL_URL> > titles.txt
python scan_competitors.py --ours my_titles.txt --theirs titles.txt --out gaps.csv

```

and upload `gaps.csv` to Notion automatically.

</details>

---

### Pilot 2 Trend Pulse Quick-and-Dirty

| Item | Details |
| --- | --- |
| **Question** | *Which search terms are heating up this week?* |
| **Primary Output** | `trend_log.md` (top 5 rising queries per day) |
| **Time Budget** | 10 min/day manual – or fully automated via Zapier |
| **Tools** | Google Trends + YouTube autosuggest (manual) · **or** `pytrends` CLI |
| **Done When** | One-week log shows at least 3 promising new keywords |

<details>
<summary><strong>Manual Steps</strong></summary>

1. Open **Google Trends** → type seed keyword (e.g. “3D printing”).
2. Note *Rising* queries + % change; paste into your Trend Pulse sheet.
3. Plug the same seed into YouTube search; copy autosuggest list.
4. Repeat daily for 7 days → highlight terms that appear ≥3 times.

</details>
<details>
<summary><strong>Automated Steps (Claude + Zapier)</strong></summary>

Claude prompt:

> “Every weekday at 09:00, use pytrends to fetch related_queries for ['3d printing','resin printer'], append JSON to google_trends.db, then summarise top 5 rising queries into Notion under Trend Log.”
>

Zapier handles the schedule; Claude writes the summary.

</details>

---

### Pilot 3 Retention × Comment Hot-Spot Map

| Item | Details |
| --- | --- |
| **Question** | *Where do viewers talk vs drop off?* |
| **Primary Output** | `hotspot_plot.png` overlaying retention curve + comment spikes |
| **Time Budget** | 45 min (manual CSV export + script) |
| **Tools** | YouTube Studio CSV (manual export), Python (Matplotlib), Claude |
| **Done When** | Plot pinpoints ≥3 moments worth deeper study |
1. In YouTube Studio → **Advanced Mode → Retention → Export CSV**.
2. Export comments (`Comments → Download`).
3. Claude runs a Python script to parse timestamps in comments (`00:00`) and plot.

Interpret spikes: build hypotheses (“viewers ask here → maybe unclear explanation”).

---

### Pilot 4 Thumbnail/Title Micro A/B (Insight Run)

| Item | Details |
| --- | --- |
| **Question** | *Which framing wins instant clicks from our core audience?* |
| **Primary Output** | `ab_results.csv` + p-value |
| **Time Budget** | 90 min set-up, then 24 h data gather |
| **Tools** | Two unlisted YouTube links, focus-group mailing list, Google Forms or simple vote email |
| **Done When** | Statistically significant winner (>95 % χ²) |

Steps:

1. Duplicate video → change **only** thumbnail or title.
2. Send both unlisted links to 30-person focus group (Zapier mail-merge).
3. Collect votes (`A` vs `B`) via Form or email replies.
4. Claude tallies counts and runs χ².
5. Adopt winning framing for public release.

---

### Pilot 5 Platform Algorithm Pulse (New)

| Item | Details |
| --- | --- |
| **Question** | *Are our video rankings shifting for key search terms?* |
| **Primary Output** | Weekly `rank_shift_report.md` (Δ position, suspected trigger) |
| **Time Budget** | 30 min initial, 5 min/week thereafter |
| **Tools** | `youtube-search-cli` or manual search in incognito, Spreadsheet |
| **Done When** | Trendline shows stable or improving rank—or alerts if drop > 3 positions |
1. Choose 5 seed keywords.
2. Each Monday search in Chrome incognito; record our video’s rank position.
3. Colour-code drops ≥3 as red.
4. Write guesses (“new competitor upload”, “title change”) for context.
5. After 4 weeks decide if strategy tweaks needed.

---

## 2 Production & Quality Pilots (Optional)

### Pilot 6 Voice Consistency Smoke Test

| Item | Details |
| --- | --- |
| **Purpose** | Guard brand tone before recording |
| **Output** | `voice_scores.csv` + heat-map |
| **Time Budget** | 1 h first run |
| **Tools** | `sentence-transformers` MiniLM, Python, Claude |
| **Done When** | Off-tone sentences (<0.65 sim) identified & fixed |
1. Pick 3 “gold-standard” scripts + 3 “iffy” scripts.
2. Claude runs embedding similarity; flags red lines.
3. Rewrite or approve; store new “gold” lines for future training.

---

### Pilot 7 One-Flow Prefect Dry-Run

| Item | Details |
| --- | --- |
| **Purpose** | Test whether Prefect orchestration feels right |
| **Output** | Slack ping with yesterday’s channel stats |
| **Time Budget** | 2 h setup |
| **Tools** | Prefect 2, Python, Claude |
| **Done When** | Flow runs 3 days without silent failure |
1. Claude creates `flow_youtube_stats.py`.
2. `prefect deployment build` → `prefect agent start`.
3. Observe reliability & noise; decide to keep or swap orchestrator.

---

## 3 Master Database Blueprint (Notion)

> Create one Table – Full Page called Manual Research & QA Pilots and add these columns:
>

| Column (Type) | Description |
| --- | --- |
| **Task** (Title) | Pilot name |
| **Goal** (Text) | One-sentence research/QA question |
| **Steps** (Text or Sub-page) | Bullet list (copy from playbook) |
| **Owner** (Person) | You • Wife • Freelancer |
| **Status** (Select) | Not Started · In Progress · Blocked · Complete |
| **Start Date** (Date) | Kick-off |
| **Review Date** (Date) | When to read results |
| **Key Findings** (Text) | Top take-aways, links to artefacts |
| **Next Action** (Text) | e.g. “Add to topic backlog” |

**Example Rows**

| Task | Goal | Owner | Status |
| --- | --- | --- | --- |
| Competitor & Topic Scanner | Spot missed topics vs competitors | You | Not Started |
| Trend Pulse | Track rising queries weekly | Wife | Not Started |
| Retention × Comment Map | Correlate drop-offs & questions | Wife | Not Started |
| Thumbnail/Title A/B | Test click-framing instinct | You | Not Started |
| Platform Algo Pulse | Detect ranking shifts early | You | Not Started |
| Voice Smoke Test | Flag off-tone wording | You | On Hold |
| Prefect Dry-Run | Validate orchestrator choice | You | On Hold |

*(Convert **Status** to colour-coded “Select”; add Board view grouped by Status for an instant Kanban.)*

---

## 4 Appendices

### A. Cheat-Sheet Formulas (Google Sheets)

| Use | Formula |
| --- | --- |
| Lowercase & strip punctuation | `=ARRAYFORMULA(LOWER(REGEXREPLACE(A2:A,"[^A-Za-z0-9 ]","")))` |
| Split words | `=ARRAYFORMULA(SPLIT(C2:C," "))` |
| Quick keyword count | `=QUERY(D:D,"select D, count(D) where D is not null group by D order by count(D) desc",1)` |

### B. Sample Claude Prompt (Competitor Scanner, semi-tech)

```
pgsql
CopyEdit
Claude, run yt-dlp on these five channel URLs (list below) to pull the 30 most-viewed video titles.
Save each set to <channel>_titles.txt, then execute scan_competitors.py
       --ours my_titles.txt
       --theirs *.txt
       --out gaps.csv
Finally, attach gaps.csv to the Notion database row “Competitor & Topic Scanner”.

```

### C. Integration-Token Checklist

| Service | Needed for | Where to paste token |
| --- | --- | --- |
| **Notion** | Upload CSVs & logs | Claude → “Connect Notion” prompt |
| **Zapier Webhook** | Trend Pulse automation, A/B mail-merge | Zapier dashboard |
| **Google OAuth** | Drive, Gmail, Calendar searches | Built-in Claude popup |
| **Slack API** | Prefect flow alerts | `.env` in project folder |

---

### How to Use This Document

1. **Paste** it into a Notion page called **“Manual-Pilot Playbook – Phase 1”**.
2. **Build the Master Database** using the blueprint.
3. **Duplicate** the relevant Step-by-Step block into each row’s **Steps** field.
4. **Run pilots** in the order that suits your calendar—research first, QA/infra when ready.
5. **Review weekly** and promote any pilot that proves valuable into a fully automated pipeline.

---

**Need a walk-through or code snippets?**

Ping me with the pilot name, and I’ll draft the exact Claude command chain (plus any Python) for you or your wife—zero terminal fuss required.

[Manual-Pilot Playbook : Pilot 1](Manual-Pilot%20Playbook%20Pilot%201%201eab4fd21ff0802eb6e8f8d6e1f8ba27.md)

[](Untitled%201eab4fd21ff080db8facf25931bd652e.md)
