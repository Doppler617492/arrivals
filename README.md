# Arrivals – Dev Tooling, CI, and One‑Command Stack

This repo contains a Flask + Postgres backend and a Vite/React frontend. It now includes:
- One‑command Docker Compose stack (backend + frontend + Postgres)
- Linters/formatters for both backend and frontend
- Minimal tests and configured test runners
- GitHub Actions CI (lint + tests for both apps)
- Pre‑commit hooks to catch issues before committing

## Quick Start

- Start everything (frontend at http://localhost:5173, backend at http://localhost:8081):
```
docker compose up -d --build
```
- Stop:
```
docker compose down
```

## Backend (Python)

- Run locally:
```
cd arrivals-backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
FLASK_APP=app.py FLASK_DEBUG=1 python app.py  # or use the provided Docker setup
```
- Lint / type check / tests:
```
black arrivals-backend
flake8 arrivals-backend
mypy arrivals-backend
pytest -q arrivals-backend
```
- Structured logs: enabled via structlog in `arrivals-backend/app.py`. Set `LOG_HTTP=1` to log request timing lines.

## Frontend (React + Vite)

- Dev server:
```
cd arrivals-frontend
npm install
npm run dev  # http://localhost:5173
```
- Lint / format / tests:
```
npm run lint
npm run format
npm test
```
- Vitest is configured in `vite.config.ts` with jsdom. Test setup lives in `src/test/setup.ts`.

## CI (GitHub Actions)

Workflow: `.github/workflows/ci.yml`
- Backend job: installs Python deps, spins up Postgres, runs Black (check), Flake8, Mypy, and Pytest
- Frontend job: installs Node deps (npm ci), runs ESLint, Prettier check, and Vitest

## Pre‑commit Hooks

Install once and enable for this repo:
```
python -m pip install pre-commit  # or pip install -r arrivals-backend/requirements.txt
pre-commit install
```
Run on all files to verify:
```
pre-commit run --all-files
```
Hooks include:
- Black, Flake8, Mypy for `arrivals-backend`
- Pytest for backend (fast sanity suite)
- ESLint (with --fix) and Prettier for `arrivals-frontend`

Pre‑push checks:
- Backend tests (pytest)
- Frontend tests (vitest)

Requires Node.js (v18+ recommended, v20 used in CI) available in PATH for JS hooks.

## Ports
- Frontend: http://localhost:5173
- Backend: http://localhost:8081
- Postgres: 5432 (exposed; data persisted in `arrivals-backend/data/pg`)

## Notes
- Frontend relies on `VITE_API_BASE` env (in compose already set to `http://localhost:8081`).
- If you encounter dev‑only React StrictMode double‑mount issues (e.g., Leaflet maps), we disable StrictMode in dev; prod renders with StrictMode enabled.
