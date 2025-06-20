# PRD: Chat Export Feature
## Goal
Allow users to export any Architect chat thread as Markdown or PDF.

## Acceptance Tasks
- Provide "Export" button in UI chat header.
- Backend endpoint `/architect/export` returns Markdown.
- PDF conversion via server-side Pandoc.
- Include usage cost line item in exported file.

## Success Metrics
- 90 % of users can export within 10 s.
- No more than 1 ¢ average cost per export.
