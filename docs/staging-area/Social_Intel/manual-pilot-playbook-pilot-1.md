# Manual-Pilot Playbook : Pilot 1

Assisted deployment with Cluaude Desktop and MCP servers.

## 📊 Pilot 1 – Competitor & Topic Scanner (“Gap Finder”)

```

Claude, run the following end-to-end:

1. Create a temp folder pilot1_gap_finder.
2. For each URL in COMPETITOR_CHANNEL_URLS (comma-separated):
   !yt-dlp --flat-playlist --print "%(title)s" COMP_URL > pilot1_gap_finder/COMPETITOR_<n>_titles.txt
3. !yt-dlp --flat-playlist --print "%(title)s" OUR_CHANNEL_URL > pilot1_gap_finder/our_titles.txt
4. Save the Python below as scan_competitors.py in that folder and run:
   !python scan_competitors.py --ours our_titles.txt --theirs COMPETITOR_*_titles.txt --out gaps.csv
5. Attach gaps.csv to Notion database row “Competitor & Topic Scanner” (Database ID = NOTION_DB_ID).

Python:
```python
import argparse, re, csv, glob, collections, itertools, pathlib
def clean(s): return re.sub(r"[^A-Za-z0-9 ]", "", s.lower())
def words(file): return [w for line in open(file) for w in clean(line).split()]
def main():
    p=argparse.ArgumentParser(); p.add_argument("--ours"); p.add_argument("--theirs", nargs="+"); p.add_argument("--out")
    a=p.parse_args()
    ours=set(words(a.ours))
    theirs=list(itertools.chain.from_iterable(words(f) for f in a.theirs))
    ctr=collections.Counter(theirs)
    rows=[(k, ctr[k]) for k in ctr if k not in ours]
    rows.sort(key=lambda t:-t[1])
    with open(a.out,"w",newline="") as f: csv.writer(f).writerows([("keyword","competitor_count_minus_ours")]+rows)
if __name__=="__main__": main()

```

```python
--

## 📈 Pilot 2 – Trend Pulse (Quick-and-Dirty, automated) :contentReference[oaicite:2]{index=2}:contentReference[oaicite:3]{index=3}

```text
Claude, schedule a weekday 09:00 job called “Trend-Pulse”:

Shell:
!pip install pytrends==4.9.0 duckdb --quiet
Python (~150 lines):

```python
from pytrends.request import TrendReq
import json, datetime, duckdb, pathlib
KEYWORDS = ["3d printing", "resin printer"]          # <-- edit
today = datetime.date.today().isoformat()
py = TrendReq(hl="en-US", tz=0)
rows=[]
for kw in KEYWORDS:
    py.build_payload([kw], timeframe="now 7-d", geo="")
    rising = py.related_queries()[kw]["rising"].head(5)
    for _, r in rising.iterrows():
        rows.append((today, kw, r['query'], int(r['value'])))
duckdb.sql("""
    CREATE TABLE IF NOT EXISTS trend_log(date STRING, seed STRING, query STRING, score INT)
""")
duckdb.sql("INSERT INTO trend_log SELECT * FROM rows", {"rows": rows})

```

Then summarise the five biggest `score` rows into Markdown and append to Notion page “trend_log.md”.

```python

---

## 🎥 Pilot 3 – Retention × Comment Hot-Spot Map :contentReference[oaicite:4]{index=4}:contentReference[oaicite:5]{index=5}

```text
Claude, given two CSVs exported from YouTube Studio:

  RETENTION_CSV  – columns: second, audience_retention
  COMMENTS_CSV   – columns include comment_text

1. Parse timestamps in comment_text matching r"\d{1,2}:\d\d".
2. Bin comment counts per second.
3. Plot retention curve and comment spikes overlay; title = "Hot-Spot Map – <VIDEO_ID>".
4. Save as hotspot_plot.png and attach to Notion row “Retention × Comment Hot-Spot Map”.

Python:
```python
import re, csv, matplotlib.pyplot as plt, pandas as pd, pathlib
ret=pd.read_csv("RETENTION_CSV")
com=[m.group() for row in csv.reader(open("COMMENTS_CSV"))
     for m in re.finditer(r"\b(\d{1,2}):(\d\d)\b", " ".join(row))]
secs=[int(p.split(":")[0])*60+int(p.split(":")[1]) for p in com]
spike=pd.Series(secs).value_counts().sort_index()
fig, ax=plt.subplots()
ax.plot(ret['second'], ret['audience_retention'])
ax2=ax.twinx(); ax2.bar(spike.index, spike.values, alpha=.3)
ax.set_xlabel("Seconds"); ax.set_ylabel("Retention %"); ax2.set_ylabel("#Comments")
plt.savefig("hotspot_plot.png", dpi=150, bbox_inches="tight")

```

```yaml
---

## 🖼️ Pilot 4 – Thumbnail/Title Micro A/B (Insight Run) :contentReference[oaicite:6]{index=6}:contentReference[oaicite:7]{index=7}

```text
Claude, prepare an A/B package:

1. Duplicate VIDEO_ID to VIDEO_ID-A and VIDEO_ID-B in YouTube Studio; change thumbnail (or title) on B only.
2. Send a mail-merge via Zapier to FOCUS_GROUP_EMAILS containing:

Subject: “Quick 10-sec click-test”
Body:
Hi <Name> – which video would you click first?

A: <UNLISTED_LINK_A>

B: <UNLISTED_LINK_B>

Just reply with “A” or “B”. Thanks!
3. After 24 h fetch replies (Zapier → Google Sheet “ab_votes”) and let Claude run:

Python:
```python
import collections, pandas as pd, scipy.stats as st
df=pd.read_csv("ab_votes.csv")            # col vote
c=collections.Counter(df.vote.str.strip().str.upper())
chi2,p=st.chisquare([c['A'],c['B']])
pd.DataFrame([c]).assign(chi2=chi2, p_value=p).to_csv("ab_results.csv", index=False)
```

1. Post ab_results.csv + decision note to Notion “Thumbnail/Title A/B”.

```
python
CopyEdit

---

## 🔍 Pilot 5 – Platform Algorithm Pulse :contentReference[oaicite:8]{index=8}:contentReference[oaicite:9]{index=9}

```text
Claude, every Monday 08:00 run:

Shell:
!pip install youtube-search-python==1.6.6 duckdb --quiet
Python:
```python
from youtubesearchpython import VideosSearch
import duckdb, datetime, json, pathlib
KEYWORDS = ["3d printing", "resin printer", "sla vs fdm", "benchy speed", "filament settings"]
channel_id="UC-OUR-CHANNEL-ID"
today=datetime.date.today().isoformat()
rows=[]
for kw in KEYWORDS:
    res=VideosSearch(kw, limit=50).result()['result']
    rank=next((i+1 for i,v in enumerate(res) if v['channel']['id']==channel_id), None)
    rows.append((today, kw, rank))
duckdb.sql("""CREATE TABLE IF NOT EXISTS rank_history(date, keyword, rank)""")
duckdb.sql("INSERT INTO rank_history SELECT * FROM rows", {"rows":rows})

```

Then compute ∆ rank vs previous week; if drop > 3 add ⚠️ in the Notion weekly report “rank_shift_report.md”.

```
python
CopyEdit

---

## 🗣️ Pilot 6 – Voice Consistency Smoke Test :contentReference[oaicite:10]{index=10}:contentReference[oaicite:11]{index=11}

```text
Claude, run a one-shot similarity scan:

Shell:
!pip install sentence-transformers==2.5.1 pandas duckdb --quiet
Python:
```python
from sentence_transformers import SentenceTransformer, util
import pandas as pd, glob, pathlib, json
model=SentenceTransformer("all-MiniLM-L6-v2")
gold=[l.strip() for l in open("gold_standard.txt")]
iffy=[l.strip() for l in open("draft_script.txt")]
emb_gold=model.encode(gold, convert_to_tensor=True)
rows=[]
for i,s in enumerate(iffy):
    sim=float(util.max_sim(model.encode([s]), emb_gold)[0])
    rows.append({"line_no":i+1,"sentence":s,"sim":sim})
pd.DataFrame(rows).to_csv("voice_scores.csv", index=False)

```

Claude: “Flag any rows with sim < 0.65 in red and attach voice_scores.csv + heat-map to Notion row ‘Voice Consistency Smoke Test’.”

```
python
CopyEdit

---

## ⚙️ Pilot 7 – One-Flow Prefect Dry-Run :contentReference[oaicite:12]{index=12}:contentReference[oaicite:13]{index=13}

```text
Claude, scaffold a Prefect 2 flow that posts yesterday’s channel stats to Slack:

Python (flow_youtube_stats.py):
```python
from prefect import flow, task, get_run_logger
import os, requests, datetime, googleapiclient.discovery

@task
def fetch_stats():
    api_key=os.environ["YT_API_KEY"]; channel_id=os.environ["YT_CHANNEL_ID"]
    yt=googleapiclient.discovery.build("youtube","v3",developerKey=api_key)
    req=yt.channels().list(part="statistics", id=channel_id); res=req.execute()
    stats=res["items"][0]["statistics"]; return stats

@task
def post_to_slack(stats):
    lg=get_run_logger()
    msg=f"📊 Yesterday's stats: Views {stats['viewCount']}, Subs {stats['subscriberCount']}"
    lg.info(msg)
    requests.post(os.environ["SLACK_WEBHOOK"], json={"text":msg})

@flow(log_prints=True)
def youtube_daily_stats():
    stats=fetch_stats()
    post_to_slack(stats)
if __name__=="__main__":
    youtube_daily_stats()

```

Shell (one-time):

!prefect deployment build flow_youtube_stats.py:youtube_daily_stats -n "daily-stats" -q default -s "0 7 * * *"

!prefect agent start -q default

```
yaml
CopyEdit
Watch Slack for three consecutive daily pings; if no silent failures, mark “One-Flow Prefect Dry-Run” ✅ Complete in Notion.

---

### ⏭️ Next Steps
1. Paste each block into Claude in order (or schedule recurring ones).
2. Swap placeholders → real IDs, tokens, paths.
3. Keep all artefacts (CSV, PNG, MD) attached to the **Manual Research & QA Pilots** database rows.

Happy automating!

```
