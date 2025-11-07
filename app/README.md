# App Startup Scripts

This directory contains all startup and management scripts for the Clipizy development environment.

## Scripts

- **start-nextjs.sh** - Starts the Next.js frontend development server
- **restart-backend.sh** - Restarts the FastAPI backend with auto-reload
- **stop-app.sh** - Stops all running services (Docker containers, FastAPI, Next.js)

## Usage

These scripts are called by `app.sh` in the root directory. You can also run them directly:

```bash
# Start Next.js frontend
./app/start-nextjs.sh

# Restart FastAPI backend
./app/restart-backend.sh

# Stop all services
./app/stop-app.sh
```

## Main Entry Point

The main entry point is `app.sh` in the project root, which orchestrates all services:

```bash
./app.sh
```

