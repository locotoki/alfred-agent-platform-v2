FROM node:18-alpine

WORKDIR /app

# Install curl and wget for health checks
RUN apk add --no-cache curl wget

# Copy package dependencies
COPY package.json ./
COPY package-lock.json* ./

# Install dependencies
RUN npm install

# Copy server files
COPY server.js ./
COPY integrate-with-social-intel.js ./
COPY health.js ./
COPY tests ./tests/
COPY public ./public/

# Expose port
EXPOSE 3007

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3007

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3007/health || exit 1

# Start the application
CMD ["node", "server.js"]
