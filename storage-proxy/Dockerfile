FROM node:18-alpine

WORKDIR /app

# Copy proxy server file
COPY ../storage-proxy.js .

# Install dependencies
RUN npm install express

# Expose the port
EXPOSE 5000

# Set healthcheck
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:5000/health || exit 1

# Run the proxy server
CMD ["node", "storage-proxy.js"]