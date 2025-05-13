# Use Node.js LTS
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci

# Copy all files
COPY . .

# Set proper NODE_ENV for production build
ENV NODE_ENV production

# Build the application with standalone output
RUN npm run build

# Production image
FROM node:18-alpine AS runner

# Set working directory
WORKDIR /app

# Don't run production as root
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
USER nextjs

# Set proper NODE_ENV for production
ENV NODE_ENV production
ENV HOSTNAME "0.0.0.0"
ENV PORT 3000

# Copy only the necessary files from the standalone output
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

# Expose port - this is the internal container port
EXPOSE 3000

# Run the application using the standalone server
CMD ["node", "server.js"]