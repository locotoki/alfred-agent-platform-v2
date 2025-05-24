#!/bin/bash
set -e
locust -f perf/locustfile.py --headless -u 50 -r 10 --run-time 20s --csv perf/results
python3 perf/parse_results.py perf/results_stats.csv
