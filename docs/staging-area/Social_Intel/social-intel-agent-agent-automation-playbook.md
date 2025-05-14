# Social Intel Agent : Agent Automation Playbook

# Social‑Intelligence Agent · **Automated YouTube Opportunity Suite**

> Purpose – Run two fully‑automated test paths that:
> 
> 
> 1. **Niche‑Scout** finds the fastest‑growing, biggest, and most Shorts‑friendly YouTube niches each day.
> 
> 2. **Seed‑to‑Blueprint** turns any seed video (or an auto‑selected hot niche) into a ranked‑channel sheet, a gap report, and a ready‑to‑execute channel strategy.
> 
> Designed for Claude (Anthropic) with shell & Python sandbox enabled. Each indented block is a **single prompt** you paste into Claude. Replace **ALL‑CAPS** placeholders before running.
> 

---

## 📊 Flow A – Niche‑Scout (Trending‑Niche Detector)

| Stage | What it does | Claude Prompt |
| --- | --- | --- |
| **A‑0 Install deps & folder** | One‑time set‑up | ```text |

Claude, bootstrap Niche‑Scout env

Shell:
!pip install yt-dlp==2024.3.10 youtube-search-python==1.6.6 pytrends==4.9.0 duckdb umap-learn pandas –quiet
!mkdir -p niche_scout
`| | **A‑1 Daily signal harvest** | • YouTube Search – collect top‑100 videos per query.<br>• Google Trends – 7‑day RSV for same queries. |`text
Claude, run daily signal harvest (store append‑only Parquet)

Python:
```python
import duckdb, datetime, json, pathlib, time
from youtubesearchpython import VideosSearch
from pytrends.request import TrendReq

QUERIES = [
“nursery rhymes”, “diy woodworking”, “urban gardening”, “ai news”, “budget travel”,]

py = TrendReq(hl=“en-US”, tz=0)
rows=[]
today=datetime.date.today().isoformat()
for q in QUERIES:
vs=VideosSearch(q, limit=100).result()[‘result’]
view_sum=sum(int(v.get(‘viewCount’,{‘text’:‘0’})[‘text’].replace(‘,’,’‘)) if isinstance(v.get(’viewCount’),dict) else 0 for v in vs)
py.build_payload([q], timeframe=‘now 7-d’)
rsv=py.interest_over_time()[q].iloc[-1]
rows.append((today,q,view_sum,rsv))
time.sleep(1)

duckdb.sql(“CREATE TABLE IF NOT EXISTS signals(date, query, view_sum, rsv)”)
duckdb.sql(“INSERT INTO signals VALUES (?, ?, ?, ?)”, rows)
`| | **A‑2 Score & cluster niches** | Rank attractiveness and group similar queries into canonical niches |`text
Claude, score and cluster signals → trending_niches

Python:
`python import duckdb, pandas as pd, umap, numpy as np, sklearn.cluster as skc sig=duckdb.sql('SELECT * FROM signals').df() latest=sig[sig.date==sig.date.max()] latest['view_rank']=latest.view_sum.rank(ascending=False) latest['rsv_rank']=latest.rsv.rank(ascending=False) latest['score']=0.6*latest['view_rank']+0.4*latest['rsv_rank'] emb=umap.UMAP(n_components=2,random_state=42).fit_transform(pd.get_dummies(latest['query'])) latest[['x','y']]=emb clust=skc.KMeans(n_clusters=min(10,len(latest))).fit(emb) latest['niche']=clust.labels_ latest.to_csv('niche_scout/trending_niches.csv',index=False)` |
| **A‑3 Digest & surface** | Post the top‑10 hottest niches to Notion / Slack | `text Claude, produce daily Slack digest from trending_niches.csv – summary only.` |

*Caveats*

* YouTube API quotas – ~100 searches/day.

* Google Trends may throttle – include a 1‑second sleep per call.

* Clustering is lightweight; switch to topic‑modelling for higher accuracy.

---

## 🏗️ Flow B – Seed‑to‑Blueprint (Channel Builder)

| Stage | What it does | Claude Prompt |
| --- | --- | --- |
| **B‑1 Install deps & folder** | *(skip if A‑0 ran)* | ```text |

Claude, prepare builder env

Shell:
!pip install google-api-python-client==2.126.0 sentence-transformers matplotlib –quiet
!mkdir -p builder
`| | **B‑2 Seed video ingest** | Fetch metadata / transcript |`text
Claude, ingest seed video (manual or auto):

*Manual:* `SEED_URL=https://youtu.be/_UR-l3QI2nE`*Auto:* read trending_niches.csv → pick niche (score min) → grab 1st video via search.

Shell:
!yt-dlp -j “$SEED_URL” > builder/seed.json
`| | **B‑3 Build query list** | Generate niche keyword set |`text
Claude, build QUERY_LIST from seed title & tags using synonyms (≤30 terms). Return list.
`| | **B‑4 Harvest & rank channels** | Gather channel stats |`text
Claude, harvest channels with YouTube API (subs, views, 30‑day Δ) → builder/top_channels.csv (top 100 by subs).
`| | **B‑5 Gap analysis** | Compare seed vs rivals |`text
Claude, for each channel scrape 200 titles, perform keyword/rhyme coverage → builder/gap_report.csv
`| | **B‑6 Strategy blueprint** | Draft channel concept doc |`text
Claude, using top_channels.csv + gap_report.csv + trending_niches.csv, write builder/channel_blueprint.md (positioning, pillars, format mix, 30‑day roadmap, AI-production tips, COPPA checklist).
`| | **B‑7 Package outputs** | Zip deliverables |`text
Claude, zip builder/*.csv builder/channel_blueprint.md → builder/channel_pack.zip
Return link: sandbox:/mnt/data/builder/channel_pack.zip
``` |

*Caveats*

* Comments disabled on Made‑for‑Kids content → skip comment analytics.

* Whisper transcription optional for music videos.

* Use Prefect/Airflow if you need one‑click orchestration.

---

## ⚠️ General Best‑Practices

1. **Cache** raw API JSON to cut quota.
2. **Rate‑limit** Google Trends calls.
3. **Rotate keys** if scraping.
4. **COPPA & rights**: stick to public‑domain melodies or licensed tracks.
5. **AI content scale**: metrics `shorts_share`, `template_variability` decide automated‑output ratio.

---

## ✅ Run Order

1. A‑0 → A‑3 once (then schedule daily).
2. Trigger Flow B anytime:
    - `Claude, run builder niche=auto` *or*
    - `Claude, run builder video=https://youtu.be/...`
3. Download **channel_pack.zip**, review, and start production.