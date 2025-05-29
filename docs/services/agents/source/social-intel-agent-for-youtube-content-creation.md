# Social Intel Agent :  for YouTube Content Creation – Consolidated Framework - Final (o3, 050525)

# Social Intelligence Agent for YouTube Content Creation – Consolidated Framework

*Last updated: 6 May 2025*

---

## 1. Executive Summary

A modular, data‑driven agent that automates competitive research, content ideation, production optimisation, and publishing on YouTube. The goal is to shorten the feedback loop between audience insights and creative output while preserving an authentic creator voice.

> Core architectural decisions locked‑in (May 2025)
>
>
> • **Single orchestrator:** Prefect (runs inside agent containers)
>
> • **Vector store:** Qdrant primary, pgvector in Supabase Postgres for light/ephemeral embeddings
>
> • **Unified UI:** Next.js “Mission Control” dashboard, with Streamlit panels embedded where data‑scientist velocity matters
>

---

## 2. Vision & Objectives

- **Intelligence**: Continuously harvest platform signals (YouTube, Reddit, X, TikTok) to surface emerging topics, underserved queries, and competitor moves.
- **Efficiency**: Combine AI automation with human creative supervision to halve the time from concept to upload without quality loss.
- **Growth**: Systematically raise CTR, AVD, and subscriber conversion through experimentation guided by analytics.

---

## 3. System Architecture Overview

```
┌──────────────┐     ┌────────────────┐     ┌──────────────────┐
│ External APIs │──▶ │ Data Lake / DB │──▶ │ Analytics Engine │
└──────────────┘     └────────────────┘     └──────────────────┘
       ▲                      │                       │
       │                      ▼                       ▼
┌─────────────────┐   ┌────────────────┐      ┌────────────────────┐
│   SaaS Tools    │   │   Local GenAI  │      │   Mission Control  │
└─────────────────┘   └────────────────┘      └────────────────────┘
                                       ▼
                           ┌──────────────────────┐
                           │ Prefect Orchestrator │
                           └──────────────────────┘

```

### Key Layers

1. **Data Ingestion Layer** – YouTube API, TubeBuddy export, SocialBlade scraping, Brand24 feeds.
2. **Processing & Storage** – Supabase Postgres (pgvector) + DuckDB; object storage for media & transcripts; **Qdrant** for large‑scale vector similarity search.
3. **Analytics Engine** – Python pipelines (Pandas, DuckDB, LangChain) powering metrics, feature extraction, and trend detection.
4. **LLM Services** – Local (Ollama, LM Studio) + cloud (OpenAI) orchestrated via LangChain Router.
5. **Orchestration & Automation** – **Prefect** DAGs triggered by Pub/Sub events; n8n / Make.com used only for cross‑platform integrations (e.g., pushing reports to Slack/Notion).
6. **UI Layer** – **Next.js Mission Control** dashboard (React) with embedded Streamlit panels; Notion remains as async documentation surface.

---

## 4. Data Pipelines & Tool Integrations

| Source / Tool | Purpose | Ingestion Method |
| --- | --- | --- |
| YouTube Data API | Video metadata, analytics, comments | Hourly Prefect flow → Pub/Sub trigger |
| TubeBuddy | Keyword scores, tag suggestions | Daily CSV export to Supabase bucket |
| SocialBlade | Historical channel stats | Web scraping lambda (weekly) |
| Brand24 | Off‑platform mentions | Webhook to n8n (real‑time) |
| Whisper API | Transcriptions & subtitles | Batch job on upload |
| Stable Diffusion | Thumbnail concepts | Local inference docker image |
| Bannerbear | Production‑ready thumbnails | REST API |

Additional integrations can be added via the Orchestrator’s plugin registry.

---

## 5. Functional Specifications

### 5.1 Research & Analysis Suite

- **Content Gap Scanner**: Cross‑reference competitor topics with channel library; output opportunity score.
- **Trend Pulse**: Detect rising queries (< 7‑day velocity) and issue Slack alerts.
- **Engagement Pattern Miner**: Align comment timestamps with retention data to surface high‑impact moments.
- **Formula Identifier**: N‑gram & NLP analysis of scripts to classify hook styles, story arcs.

### 5.2 Content Development Toolkit

- **AI‑Assisted Scripting**: Prompt templates (hook, value delivery, CTA) auto‑filled with researched insights.
- **Voice Consistency Checker**: Embedding similarity against brand style corpus; flags off‑tone sentences.
- **Multimedia Generation**
    - Thumbnail generator: Iterates SD prompts, selects top‑3 by predicted CTR model.
    - B‑roll recommender: Matches script entities to tagged stock library.

### 5.3 Production Automation System

- **Editing Workflow Manager**: Generates DaVinci Resolve project with pre‑cut assets.
- **Pacing Optimiser**: Calculates optimal cut density from analytics benchmarks; suggests trims.
- **Metadata Suite**: Title, description, tags drafted and A/B variants queued for TubeBuddy.

---

## 6. Technical Stack

| Layer | Tech |
| --- | --- |
| Orchestration | Python 3.12, **Prefect** (DAGs), LangChain (LLM chains) |
| Data | Supabase Postgres + pgvector, DuckDB (ad‑hoc OLAP), **Qdrant** (vectors) |
| ML / LLMs | Ollama (Llama‑3‑70B‑Instruct), GPT‑4o, Sentence‑Transformers |
| Dashboards | **Next.js Mission Control** (React), Streamlit (embedded panels) |
| Infrastructure | Docker Compose (local), Kubernetes (staging/prod), Supabase Storage |

---

## 7. Workflow & Processes

1. **Daily Ingestion (06:00 UTC)** – Prefect flow pulls latest metrics and comments, publishes `youtube.ingest.completed`.
2. **Trend Report Generation (07:00 UTC)** – Prefect task summarises and posts to Mission Control + Slack.
3. **Content Ideation Meeting (Mon, 09:00 UTC)** – Human review of top opportunities, assign scripts.
4. **Script Drafting (Mon–Tue)** – Writer collaborates with AI template; Voice Checker passes before lock.
5. **Production (Wed)** – Footage + B‑roll compiled; Pacing Optimiser suggestions accepted/rejected.
6. **Thumbnail & Metadata A/B (Thu)** – Top‑2 variants scheduled via TubeBuddy experiment.
7. **Publish (Fri 17:00 UTC)** – Upload scheduling manager publishes; cross‑platform clips auto‑generated.
8. **Post‑Publish Review (Sun)** – Automated report on CTR, AVD, Velocity; tag tasks for following sprint.

---

## 8. Roadmap (12‑Week Plan)

| Phase | Weeks | Milestones |
| --- | --- | --- |
| **MVP (Core Research)** | 1‑4 | YouTube API sync • Trend Pulse v1 • Content Gap Scanner |
| **Toolkit Build‑out** | 5‑8 | AI‑Assisted Scripting • Voice Checker • Thumbnail generator |
| **Automation & Optimise** | 9‑12 | Editing Workflow Manager • Pacing Optimiser • Metadata Suite • Mission Control GA |

---

## 9. Task Backlog (Excerpt)

1. **Set up Supabase project & service account** – 4 h – *Priority P0*
2. **Write Prefect flow: video ingest** – 8 h – *P0*
3. **Integrate Qdrant vector store** – 6 h – *P0*
4. **Design prompt templates v0.1** – 5 h – *P1*
5. **Expose Streamlit iframe in Mission Control** – 4 h – *P1*

Full backlog lives in Jira board.

---

## 10. KPI & Metrics

- **Content Funnel**: CTR, AVD, Watch‑hours / sub, Session starts.
- **Growth**: Subs gained per 1k views, returning vs new viewers.
- **Operational**: Cycle time (idea ➜ publish), percentage automated steps.

---

## 11. Governance & Roles

| Role | Responsibilities |
| --- | --- |
| Research Analyst | Manages data ingestion, surfaces insights |
| Script Writer | Drafts scripts with AI toolkit |
| Video Editor | Executes edit workflow, applies pacing feedback |
| Thumbnail Designer | Runs generator, selects variants |
| Product Owner | Prioritises backlog, roadmap guardianship |

---

## 12. Next Steps & Action Items

1. **Lock stack decisions in DevOps README** – Prefect + Qdrant + Mission Control/Streamlit.
2. **Provision Dev environment** – Docker Compose baseline (Postgres + Qdrant + Supabase CLI).
3. **Kick‑off MVP sprint** – Target start 12 May 2025.
4. **Define success criteria** – MVP considered done when daily trend report matches manual research ≥ 90%.

---

*End of document*
