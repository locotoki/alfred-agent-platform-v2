FROM ghcr.io/alfred/healthcheck:0.3.1 AS healthcheck

FROM node:20-alpine AS base
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
EXPOSE 8080

FROM base AS build
RUN npm run build

FROM node:20-alpine AS production
WORKDIR /app
RUN npm install -g serve@14.2.1
COPY --from=build /app/dist ./dist
# Copy healthcheck binary
COPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck

EXPOSE 8080
CMD ["serve", "-s", "dist", "-l", "8080"]