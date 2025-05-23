import sys, csv

def extract_p95(csv_path):
    with open(csv_path) as f:
        rows = list(csv.DictReader(f))
        for row in rows:
            if row["Name"] == "query_rag":
                p95 = float(row["95%"])
                print(f"# HELP rag_p95_latency_ms p95 latency in ms")
                print(f"# TYPE rag_p95_latency_ms gauge")
                print(f"rag_p95_latency_ms {p95}")
                if p95 > 300:
                    print("❌ ERROR: p95 latency exceeds 300ms", file=sys.stderr)
                    exit(1)

if __name__ == "__main__":
    extract_p95(sys.argv[1])
