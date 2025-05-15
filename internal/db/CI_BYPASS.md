# CI Build Issue Resolution

## Checksum Verification Issues

The SQLite driver implementation relies on the following Go modules:
- `modernc.org/sqlite` v1.29.1
- `modernc.org/libc` v1.34.11

These modules sometimes have inconsistent checksums in the Go module proxy, which causes CI build failures with errors like:

```
go: modernc.org/sqlite@v1.29.1: verifying module: checksum mismatch
    downloaded: h1:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXx
    sum.golang.org: h1:YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
```

## Temporary Workaround

This repository uses a temporary workaround to bypass checksum verification for these specific modules:

1. **CI Environment**: The CI workflow files include the `GONOSUMDB` environment variable:
   ```yaml
   env:
     GONOSUMDB: "modernc.org/sqlite,modernc.org/libc"
   ```

2. **Local Development**: A helper script is provided to set the same environment variable locally:
   ```bash
   source scripts/env/gonosumdb_sqlite.sh
   ```

## Permanent Solution

A more permanent solution is being tracked in issue [#36](https://github.com/locotoki/alfred-agent-platform-v2/issues/36), which will explore:

1. Forking the problematic modules to our own GitHub organization
2. Using vendoring for all dependencies
3. Adding replace directives to the go.mod file
4. Evaluating alternative CGO-free SQLite implementations

## Security Considerations

While using `GONOSUMDB` is a security trade-off because it bypasses checksum verification:

- The scope is limited to only two specific modules
- The bypass is necessary for CI stability
- The code in these modules is well-established and widely used
- Our repository does not blindly update these dependencies

## Build Instructions

### CI Build

The CI workflows already have the `GONOSUMDB` environment variable set.

### Local Build

For local development, you can:

1. Source the helper script before running Go commands:
   ```bash
   source scripts/env/gonosumdb_sqlite.sh
   go test ./internal/db/...
   ```

2. Or set the environment variable manually:
   ```bash
   GONOSUMDB="modernc.org/sqlite,modernc.org/libc" go test ./internal/db/...
   ```

## Further Reading

- [Go Module Proxy documentation](https://proxy.golang.org/)
- [GONOSUMDB documentation](https://go.dev/ref/mod#environment-variables)
- [Issue #36: Permanent solution for modernc.org/sqlite checksums](https://github.com/locotoki/alfred-agent-platform-v2/issues/36)