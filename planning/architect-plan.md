<!-- ARCHITECT PROMPT: You are an AI architect.  
Generate a task breakdown from the planning bullets below.  
Return a markdown table with columns: | Status | ID | File | Description |.  
Use [ ] for unchecked tasks and [x] for completed ones. -->

## System Overview · 18 Jun 2025
Alfred Agent Platform is at **v 1.0.8** (main green).  
All mandatory CI gates pass (`ci-summary`, `trivy-image`, `flake-detector`, …); images are signed; Slack socket-mode bot is live.  
Sprint **v 1.1 “Stabilisation”** closes **25 Jun 2025**.  
Open high-priority items: Dependabot/Trivy automation, BizDev agent groundwork, Cloudflare tunnel for Slack, final CI gate cleanup.

## Planning bullets
- Finish umbrella PR #710: enable optional **E2E** & **perf-stress** jobs and make **flake-detector** a required gate  
- Kick-off **Dependabot + weekly Trivy automation** (issue #695)  
- **Migrate Slack adapter** from ngrok to **Cloudflare Tunnel** and update Slack manifest  
- Begin **BizDev agent scaffold** (issue #697)


