# syntax=docker/dockerfile:1

# Build stage: dependencies and tooling never reach the runtime image.
FROM node:20.19.0-alpine3.21 AS build

WORKDIR /app

# Install dependencies from the lock file for reproducible builds.
COPY package.json package-lock.json ./
RUN npm ci --cache .npm --prefer-offline --no-audit --no-fund

COPY . .
RUN npm run build -- --configuration production

# Runtime stage: Nginx runs as an unprivileged user on port 8080.
FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime

COPY nginx/nginx.conf /etc/nginx/nginx.conf
# Angular's application builder places browser assets in the browser folder.
COPY --from=build /app/dist/olympic-games-starter/browser /app

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --spider --quiet http://127.0.0.1:8080/ || exit 1
