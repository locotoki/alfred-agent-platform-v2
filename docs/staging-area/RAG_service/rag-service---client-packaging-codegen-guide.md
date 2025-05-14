# RAG Service - Client Packaging & Codegen Guide

# RAG Client – Packaging & Codegen Guide

## 1. Publishing `@acme/rag-client` to npm

> Toolchain: pnpm + tsup (fast ESM/CJS bundles) with optional bun for local dev speed.
> 

### 1.1 Project layout

```
packages/
  rag-client/
    src/
      rag_client_retriever.ts
    package.json
    tsconfig.json
    tsup.config.ts

```

### 1.2 `package.json`

```
{
  "name": "@acme/rag-client",
  "version": "0.1.0",
  "description": "RAG Gateway SDK for Node.js and browsers",
  "main": "dist/index.js",        // CJS
  "module": "dist/index.mjs",     // ESM
  "types": "dist/index.d.ts",
  "exports": {
    "import": "./dist/index.mjs",
    "require": "./dist/index.js"
  },
  "files": ["dist"],
  "scripts": {
    "build": "tsup src/index.ts --dts --format esm,cjs",
    "dev": "tsup src/index.ts --watch --dts",
    "bun:dev": "bun build src/index.ts --watch --outdir dist --target node",
    "prepublishOnly": "pnpm run build"
  },
  "dependencies": {
    "@langchain/core": "^0.1.11"
  },
  "devDependencies": {
    "tsup": "^8.0.1",
    "typescript": "^5.4.3",
    "bun-types": "^1.0.11" // optional
  },
  "engines": {
    "node": ">=18"
  },
  "publishConfig": {
    "access": "public"
  }
}

```

### 1.3 `tsup.config.ts`

```
import { defineConfig } from "tsup";
export default defineConfig({
  entry: ["src/index.ts"],
  format: ["esm", "cjs"],
  dts: true,
  sourcemap: true,
  clean: true,
  outDir: "dist",
});

```

### 1.4 `src/index.ts`

```
export * from "./rag_client_retriever";

```

### 1.5 Publish flow

```bash
pnpm i
pnpm build   # generates dist/
npm publish --access public  # or pnpm publish

```

---

## 2. Bun alternative (super‑fast local build)

If you prefer **bun**:

```bash
bun build src/index.ts \
  --outdir dist \
  --target node \
  --format esm,cjs \
  --splitting false \
  --external:@langchain/core

```

Add to `package.json` scripts:

```json
"bun:build": "bun build src/index.ts --outdir dist --target node --format esm,cjs"

```

---

## 3. OA3 Typescript client generation (fetch‑based)

### 3.1 Generate with `openapi-generator-cli`

```bash
pnpm dlx @openapitools/openapi-generator-cli generate \
  -i ../../docs/RAG_Service_OpenAPI_3.1.yaml \
  -g typescript-fetch \
  -o packages/rag-client-gen \
  --additional-properties=supportsES6=true,npmName="@acme/rag-client-gen",npmVersion=0.1.0

```

This produces a fully‑typed client; you can then re‑export the typed methods from your hand‑written SDK if desired.

### 3.2 Bun + OA3 generator

```bash
bunx @openapitools/openapi-generator-cli generate -i path/to/spec.yaml -g typescript-fetch -o packages/rag-client-gen

```

---

## 4. GitHub Actions CI

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
        with:
          version: latest
      - name: Install deps
        run: pnpm i --frozen-lockfile
      - name: Lint
        run: pnpm eslint src --max-warnings 0
      - name: Build
        run: pnpm build
      - name: Publish dry‑run
        if: github.event_name == 'pull_request'
        run: npm publish --dry-run

```

> Tip: For private registry publish, add npm_token secret and a second publish job gated on tags.
> 

---

## 5. Versioning & SemVer

- Follows the RFC §8.3 model version propagation; bump **minor** for non‑breaking client changes, **major** if you change path/ schema. Use `changesets` for automated changelog + version bump.

---

### Done!

You now have: a) build scripts via tsup or bun, b) an auto‑generated OA3 fetch client, and c) CI pipeline ready for npm publish.