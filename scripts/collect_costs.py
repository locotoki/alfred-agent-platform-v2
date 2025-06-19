import os, datetime, requests, psycopg2, sys
PG_DSN = os.getenv("PG_DSN")
GH_TOKEN = os.getenv("GH_TOKEN")
OPENAI_KEY = os.getenv("OPENAI_API_KEY")
OWNER_REPO = os.getenv("GITHUB_REPOSITORY")

def openai_cost():
    # crude estimate via usage endpoint (last 1 day)
    headers = {"Authorization": f"Bearer {OPENAI_KEY}"}
    r = requests.get("https://api.openai.com/dashboard/billing/usage",
                     headers=headers, params={"start_date":(datetime.date.today()-datetime.timedelta(days=1)).isoformat(),
                                              "end_date":datetime.date.today().isoformat()})
    r.raise_for_status()
    return r.json().get("total_usage",0)/100.0  # cents→USD

def ci_minutes():
    headers={"Authorization":f"Bearer {GH_TOKEN}"}
    r = requests.get(f"https://api.github.com/repos/{OWNER_REPO}/actions/usage", headers=headers)
    r.raise_for_status()
    return r.json()["billable"]["UBUNTU"]["total_minutes_used"]

def store(date,llm,ci):
    conn=psycopg2.connect(PG_DSN)
    cur=conn.cursor()
    cur.execute("""CREATE TABLE IF NOT EXISTS costs_daily
                   (date DATE PRIMARY KEY, llm_usd NUMERIC, ci_minutes NUMERIC)""")
    cur.execute("INSERT INTO costs_daily (date,llm_usd,ci_minutes) VALUES (%s,%s,%s) "
                "ON CONFLICT (date) DO UPDATE SET llm_usd=EXCLUDED.llm_usd, ci_minutes=EXCLUDED.ci_minutes",
                (date,llm,ci))
    conn.commit();cur.close();conn.close()

def main():
    date=datetime.date.today()
    llm=openai_cost()
    ci=ci_minutes()
    store(date,llm,ci)
    print("Stored cost:",date,llm,ci)

if __name__=="__main__":
    if not (PG_DSN and GH_TOKEN and OPENAI_KEY):
        sys.exit("Missing env vars")
    main()