# recordtec-fe

Vue.js frontend for cloud networking test.

## Setup

```bash
npm install
```

## Development

```bash
npm run dev
```

Then open http://localhost:5173 in your browser.

## Build

```bash
npm run build
```

## Docker (Vue + Nginx)

### 1. UI only (no backend)

```bash
docker compose up -d --build
```

Open **http://localhost:8080** — the UI loads. The "Call Backend" button will fail until the backend is configured.

### 2. With backend (set IP — no hardcoding in the image)

```bash
cp .env.example .env
# Edit .env: BACKEND_HOST=<backend private IP>
docker compose up -d --build
```

Or: `BACKEND_HOST=10.10.1.4 docker compose up -d --build`

**Ansible:** See `deploy/ansible/README.md` — pass `recordtec_backend_host` into `BACKEND_HOST` for Docker or use the Jinja template for host Nginx.

### Troubleshooting

```bash
docker ps                    # Check if container is running
docker logs recordtec-frontend   # View logs
docker compose build --no-cache   # Rebuild without cache
```

## CI/CD (GitHub Actions)

On push to `main`, the workflow builds the Docker image and pushes to GHCR:

```
ghcr.io/<owner>/recordtec-fe:latest
ghcr.io/<owner>/recordtec-fe:main
ghcr.io/<owner>/recordtec-fe:<sha>
```

No extra secrets needed — uses `GITHUB_TOKEN`. Image is built for `linux/amd64` (GCP).

## Configuration

The backend API URL is proxied via `/api` in Nginx. Set `BACKEND_HOST` and `BACKEND_PORT` for the backend location.

# Zuul Tests
Dummy Change for zuul 1