FROM node:18-alpine

WORKDIR /app

# Copy the simpler server file
COPY storage-proxy-simple.js .

# Expose the port
EXPOSE 5000

# Set healthcheck
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:5000/health || exit 1

# Run the proxy server
CMD ["node", "storage-proxy-simple.js"]