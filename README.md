# OpenWA — WhatsApp API Gateway

> OpenWA but without the jitters from the original repo. Open-source, self-hosted HTTP API for WhatsApp. Built with NestJS, React, and whatsapp-web.js.

OpenWA exposes a RESTful API and a real-time dashboard for managing WhatsApp sessions, sending/receiving messages, managing groups, webhooks, and more — all from a single deployment.

---

## Features

- **Multi-session** — manage multiple WhatsApp accounts simultaneously
- **REST API** — full-featured HTTP API with Swagger documentation
- **Dashboard** — real-time React dashboard with session management, message tester, and logs
- **Webhooks** — configurable per-session webhook delivery with retry logic
- **Plugin system** — extensible engine, storage, and queue adapters
- **SQLite / PostgreSQL** — pluggable database backend
- **Docker ready** — single-image deployment with Chromium built-in

---

## Quick Start

Choose the method that suits your needs:

| Method | Best for |
| --- | --- |
| [🐳 Docker (recommended)](#docker) | Production, fastest setup |
| [💻 Development](#development) | Contributing, debugging, local hacking |
| [🚀 Production (bare metal)](#production) | Servers without Docker |

---

## Docker

The fastest way to run OpenWA. The image includes Chromium, Node.js, and the pre-built dashboard — everything in one container.

### Using Docker Run

```bash
docker run -d \
  --name openwa \
  --restart unless-stopped \
  -p 2785:2785 \
  -p 2886:2886 \
  0xtashuop/openwa:latest
```

### Using Docker Compose

Create a `docker-compose.yml`:

```yaml
services:
  openwa:
    image: 0xtashuop/openwa:latest
    container_name: openwa
    restart: unless-stopped

    ports:
      - "2785:2785"
      - "2886:2886"

    environment:
      NODE_ENV: development

    volumes:
      - openwa_data:/app/data

volumes:
  openwa_data:
```

Then run:

```bash
docker compose up -d
```

### Build from Source (Docker)

If you want to build the image locally instead of pulling from Docker Hub:

```bash
docker build -t openwa:latest .
docker compose up -d
```

### Access

Once running, open your browser:

| Service | URL |
| --- | --- |
| Dashboard | [http://localhost:2785](http://localhost:2785) |
| API Docs (Swagger) | [http://localhost:2785/api/docs](http://localhost:2785/api/docs) |

On first startup, an API key will be printed in the container logs:

```bash
docker logs openwa
```

Look for the line:

```
🔑 API Key:
   owa_k1_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Use this key to authenticate in the dashboard and for API requests.

---

## Development

### Prerequisites

- **Node.js** ≥ 22
- **npm** ≥ 10
- **Google Chrome / Chromium** (for whatsapp-web.js puppeteer)

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/rmyndharis/OpenWA.git
cd OpenWA

# 2. Install dependencies (backend + dashboard)
npm install

# 3. Create the data directories
mkdir -p data/sessions data/media

# 4. Create your .env file
cp .env.example .env
```

Edit `.env` with minimal dev settings:

```env
PORT=2785
NODE_ENV=development

# SQLite (no external DB needed)
DATABASE_TYPE=sqlite
DATABASE_NAME=./data/openwa.sqlite
DATABASE_SYNCHRONIZE=true
DATABASE_LOGGING=false

# WhatsApp Engine
ENGINE_TYPE=whatsapp-web.js
SESSION_DATA_PATH=./data/sessions
PUPPETEER_HEADLESS=true
PUPPETEER_ARGS=--no-sandbox,--disable-setuid-sandbox,--disable-dev-shm-usage

# Storage
STORAGE_TYPE=local
STORAGE_LOCAL_PATH=./data/media

# Disable optional services
REDIS_ENABLED=false
QUEUE_ENABLED=false
CACHE_ENABLED=false
```

### Run

```bash
npm run dev
```

This starts both services concurrently with hot-reload:

| Service | URL | Description |
| --- | --- | --- |
| API | [http://localhost:2785](http://localhost:2785) | NestJS backend with hot-reload |
| Dashboard | [http://localhost:2886](http://localhost:2886) | Vite React app with HMR |

The dashboard dev server proxies `/api` requests to the backend automatically.

### Useful Commands

```bash
npm run dev              # Start API + Dashboard (dev mode with hot-reload)
npm run start:dev        # Start API only (dev mode)
npm run dashboard:dev    # Start Dashboard only (dev mode)
npm run build            # Build backend for production
npm run dashboard:build  # Build dashboard for production
npm run lint             # Run ESLint
npm run test             # Run tests
```

---

## Production

For deploying on a server without Docker.

### Prerequisites

- **Node.js** ≥ 22
- **npm** ≥ 10
- **Chromium / Google Chrome** installed on the server

### Build

```bash
# 1. Clone and install
git clone https://github.com/rmyndharis/OpenWA.git
cd OpenWA
npm install

# 2. Build the backend
npm run build

# 3. Build the dashboard
npm run dashboard:build

# 4. Create data directories
mkdir -p data/sessions data/media

# 5. Create .env
cp .env.example .env
# Edit .env — set NODE_ENV=production, configure your database, etc.
```

### Run

```bash
node dist/main
```

In production, the NestJS server serves both the API and the dashboard static files on a single port (default `2785`).

| Service | URL |
| --- | --- |
| Dashboard | [http://your-server:2785](http://your-server:2785) |
| API Docs | [http://your-server:2785/api/docs](http://your-server:2785/api/docs) |

### Process Manager (Recommended)

Use PM2 or systemd to keep OpenWA running:

```bash
# Using PM2
npm install -g pm2
pm2 start dist/main.js --name openwa
pm2 save
pm2 startup
```

---

## Configuration

All configuration is done via environment variables (`.env` file or Docker environment).

See [`.env.example`](.env.example) for a full reference of all available options.

### Key Variables

| Variable | Default | Description |
| --- | --- | --- |
| `PORT` | `2785` | API server port |
| `NODE_ENV` | `production` | `development` or `production` |
| `DATABASE_TYPE` | `sqlite` | `sqlite` or `postgres` |
| `DATABASE_NAME` | `./data/openwa.sqlite` | SQLite file path or Postgres DB name |
| `DATABASE_SYNCHRONIZE` | `false` | Auto-sync schema (set `true` for dev/first run) |
| `ENGINE_TYPE` | `whatsapp-web.js` | WhatsApp engine plugin |
| `STORAGE_TYPE` | `local` | `local` or `s3` |
| `API_MASTER_KEY` | *(empty)* | Master API key (auto-generated if empty) |
| `CORS_ORIGINS` | `*` | Allowed CORS origins (comma-separated) |
| `PUPPETEER_HEADLESS` | `true` | Run Chromium headless |

---

## API Authentication

All API endpoints (except `/api/health`) require an API key.

Pass the key in the `x-api-key` header:

```bash
curl -H "x-api-key: YOUR_API_KEY" http://localhost:2785/api/sessions
```

On first startup, a key is auto-generated and printed to the console. Additional keys can be managed through the dashboard.

---

## Architecture

```
┌─────────────────────────────────────────────┐
│                  Port 2785                  │
│  ┌───────────────────────────────────────┐  │
│  │          NestJS API Server            │  │
│  │   /api/*  → REST endpoints           │  │
│  │   /socket.io → Real-time events      │  │
│  │   /*      → Dashboard (static)       │  │
│  └───────────────────────────────────────┘  │
│  ┌──────────┐ ┌──────────┐ ┌────────────┐  │
│  │  SQLite  │ │  Plugins │ │ WWeb.js +  │  │
│  │ /Postgres│ │  System  │ │  Chromium  │  │
│  └──────────┘ └──────────┘ └────────────┘  │
└─────────────────────────────────────────────┘
```

---

## Project Structure

```
OpenWA/
├── src/                    # NestJS backend
│   ├── main.ts             # Entry point
│   ├── app.module.ts       # Root module
│   ├── common/             # Shared services, guards, interceptors
│   ├── config/             # Configuration schema
│   ├── core/               # Plugin system & hook event bus
│   ├── engine/             # WhatsApp engine abstraction
│   └── modules/            # Feature modules (sessions, messages, groups, etc.)
├── dashboard/              # React frontend (Vite)
│   ├── src/
│   │   ├── pages/          # Dashboard pages
│   │   ├── components/     # Reusable UI components
│   │   └── services/       # API client
│   └── vite.config.ts
├── data/                   # Runtime data (SQLite DB, sessions, media)
├── Dockerfile              # Multi-stage production build
├── docker-compose.yml      # Docker Compose configuration
├── .env.example            # Environment variable reference
└── package.json
```

---

## License

This project is licensed under the MIT License – free for personal and commercial use.

## Things To Do

Add support for Minio for storage, Redis for cache, and Postgres for data storage.
