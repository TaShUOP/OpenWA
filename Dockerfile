# =============================================================================
# OpenWA — Production Docker Image
# Multi-stage build: Dashboard (Vite) + Backend (NestJS) → single image
# =============================================================================

# ---- Stage 1: Build Dashboard ----
FROM node:22-alpine AS dashboard-build

WORKDIR /build

COPY dashboard/package*.json dashboard/.npmrc ./
RUN npm ci

COPY dashboard/ ./
RUN npm run build

# ---- Stage 2: Build Backend ----
FROM node:22-alpine AS backend-build

WORKDIR /build

COPY package*.json ./
RUN npm ci --ignore-scripts

COPY tsconfig*.json nest-cli.json ./
COPY src/ ./src/

RUN npx nest build

# ---- Stage 3: Production Runtime ----
FROM node:22-slim

# Install Chromium and dependencies for whatsapp-web.js (puppeteer)
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    fonts-liberation \
    fonts-noto-color-emoji \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Tell puppeteer to use system Chromium instead of downloading its own
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# Run as non-root for security
RUN groupadd -r openwa && useradd -r -g openwa -m openwa

WORKDIR /app

# Install production dependencies only
COPY package*.json ./
RUN npm ci --omit=dev --ignore-scripts \
    && npm rebuild sqlite3 \
    && npm cache clean --force

# Copy built backend from Stage 2
COPY --from=backend-build /build/dist ./dist

# Copy built dashboard from Stage 1
# NestJS serves these static files directly (no separate server needed)
COPY --from=dashboard-build /build/dist ./dashboard/dist

# Copy env reference files
COPY .env.example .env.minimal ./

# Create data directories and set ownership
RUN mkdir -p data/sessions data/media \
    && chown -R openwa:openwa /app

# Switch to non-root user
USER openwa

# Single port: API + Dashboard served by NestJS
EXPOSE 2785

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD node -e "fetch('http://localhost:2785/api/health').then(r => r.ok ? process.exit(0) : process.exit(1)).catch(() => process.exit(1))"

# Start the API server (also serves dashboard static files)
CMD ["node", "dist/main"]
