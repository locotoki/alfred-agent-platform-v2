# Possible research sources & methods

Below is a survey of **possible research sources & methods** you can plug into your “Define Niche → Niche Title” step in order to surface high-potential niches by different key metrics (trending, growth, volume, competition, etc.).

| **Option** | **Data Source** | **Metric** | **What It Reveals** | **How to Surface** |
| --- | --- | --- | --- | --- |
| **YouTube Trending API** | YouTube Data API v3 | Trending Videos / Channels | Topics and creators currently getting algorithmic boosts | Pull the daily trending endpoint, cluster video titles by keyword frequency, sort by view growth. |
| **Google Trends (Web + YouTube)** | Google Trends API / UI | “Rising” Search Queries, Interest Over Time | Terms with sharp upticks in search volume | Query “Last 30 days” → filter to category (e.g. “Science & Tech”) → collect top 20 rising terms. |
| **Exploding Topics** | ExplodingTopics.com | Topic Growth Score | Early-stage subjects showing explosive interest | Subscribe to daily digest or use their API to pull top “emerging” topics by category. |
| **Reddit “Hot” & “Rising”** | Reddit API / Pushshift | Hot Posts, Subscriber Growth | Communities where engagement & membership are surging | Monitor related subreddits → scrape post titles + upvote trends → track subscriber count delta. |
| **Twitter Trends & Hashtags** | Twitter API v2 | Tweet Volume, Trend Velocity | Real-time conversation trends | Fetch trending topics for chosen geo → rank by tweet count growth over sliding window. |
| **Keyword Research Tools** | Ahrefs / SEMrush / Moz | Search Volume (SV), KD (Keyword Difficulty) | High-demand, low-competition keyword phrases | Run “Keyword Explorer” → filter SV > X and KD < Y → export list of candidate niche titles. |
| **Amazon Movers & Shakers** | Amazon Best Sellers & Movers API | Rank Change, Category Growth | Products/categories seeing the biggest sales spikes | Pull top 100 Movers & Shakers → group by category → identify under-served segments. |
| **Etsy & Niche Marketplaces** | Etsy API | Listing Growth, Favorite Count Growth | Craft / hobby niches gaining traction | Monitor “Top Trends” endpoint → track month-over-month increase in listings and favorites. |
| **Podcast Charts** | Apple / Spotify Charts | New Podcast Rank Entrants, Listenership Growth | Rising themes in audio format | Scrape weekly top-100 charts → text-mine show titles and descriptions → cluster by topic. |
| **Pinterest Trends** | Pinterest Trends | Pin Volume, Repin Growth | Visual interest spikes in lifestyle, DIY, fashion niches | Use “Explore” → record top trending keywords and boards → surface recurring themes. |
| **Stack Overflow Tags** | Stack Exchange API | Question Volume, Tag Growth Rate | Technical topics or APIs rapidly attracting questions | Fetch tag popularity over time → sort by highest % growth → flag emerging dev niches. |
| **AnswerThePublic** | AnswerThePublic.com | Question Search Patterns | What “how-to” queries people are asking about | Enter a seed topic → export question permutations → identify frequently asked sub-angles. |
| **TikTok Trending Sounds & Hashtags** | TikTok API (or third-party) | Video Count, Like-to-View Ratio | Short-form content themes with high shareability | Pull daily trending hashtags → analyze volume and engagement → map back to broader niche ideas. |
| **Industry Reports & Newsletters** | CB Insights, Gartner, Newsletter digests | VC Funding, Reported Growth Figures | Macro trends and high-growth verticals | Subscribe to category-specific newsletters → tag/track mentions frequency → spot patterns. |

---

### How to Integrate

1. **Multi-Source Aggregation**
    - Build a unified “Niche Candidates” index in your backend that pulls each of the above on a scheduled basis.
2. **Scoring & Ranking**
    - Normalize each source’s metric (e.g. z-scores) and compute a composite “Niche Potential” score.
3. **Suggestion UI**
    - In **Step 1 · Define Niche**, show a live list of **Top 10 Suggested Niches** sorted by your composite score, with small badges indicating the dominant signal (e.g. “↑300 % search” or “+12 k Reddit subs”).
4. **User Feedback Loop**
    - Allow users to “thumbs up/down” suggestions; use that as implicit feedback to re-weight your scoring model over time.

By plugging in one or more of these research options, you’ll be able to dynamically surface high-interest, high-growth niche titles—giving creators a solid, data-backed starting point every time.