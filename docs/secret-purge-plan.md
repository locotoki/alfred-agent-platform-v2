# Historical Secret Purge Plan 🧹 *(Draft)*

> **Scope:** Issues #532-#534 — remove leaked keys pre-GA
> **Tooling:** [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)

## Steps

1. **Dry-run list** of offending blobs
   ```bash
   bfg --delete-files ops/bfg/secret-patterns.txt --no-blob-protection
   ```

2. **Backup main**
   ```bash
   git tag backup/pre-bfg-$(date +%Y%m%d)
   ```

3. **Rewrite & force-push**
   ```bash
   ./ops/bfg/run-bfg.sh
   ```

<\!-- TODO: Fill table below once SHA1s/patterns confirmed -->

 < /dev/null |  SHA-1 Blob | Notes | Replacement |
| --- | --- | --- |
| TBD | legacy AWS key | `<removed>` |
