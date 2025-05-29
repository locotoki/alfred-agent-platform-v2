FROM node:18-alpine

WORKDIR /app

# Install dependencies (if package.json exists)
COPY package*.json ./
RUN if [ -f package.json ]; then npm install; else echo '{}' > package.json && npm install express; fi

# Copy source code
COPY . .

# Create a minimal index.js if it doesn't exist
RUN if [ ! -d src ]; then mkdir -p src; fi
RUN if [ ! -f src/index.js ]; then \
    echo 'const express = require("express");\nconst app = express();\nconst port = process.env.PORT || 8012;\n\napp.get("/", (req, res) => {\n  res.send("Mission Control is running");\n});\n\napp.get("/healthz", (req, res) => {\n  res.status(200).json({ status: "healthy" });\n});\n\napp.listen(port, () => {\n  console.log(`Mission Control listening on port ${port}`);\n  console.log(`Environment: ${process.env.ENVIRONMENT || "not set"}`);\n});' > src/index.js; \
    fi

EXPOSE 8012

CMD ["node", "src/index.js"]
