# Multi-stage build for Slack MCP Gateway
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies for build
RUN npm ci

# Copy application code
COPY . .

# Main stage
FROM node:20-alpine

WORKDIR /app

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --only=production

# Copy application code
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Ensure files are owned by nodejs user
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose health port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ["/bin/sh", "-c", "wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1"]

# Start application with dumb-init
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]