#!/bin/bash

# Start Next.js development server
# Get the script directory and navigate to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Set environment variables to avoid UNC path issues
export NODE_OPTIONS="--max-old-space-size=4096"
export NEXT_TELEMETRY_DISABLED=1

# If nvm is installed, load it and try to use Node 18+
if [ -z "${NVM_DIR:-}" ]; then
    export NVM_DIR="$HOME/.nvm"
fi
if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
    if command -v nvm >/dev/null 2>&1; then
        nvm use 18 >/dev/null 2>&1 || true
    fi
fi

# Enforce Node.js version >= 18 to avoid syntax errors like "Unexpected token ?"
REQUIRED_NODE_MAJOR=18
if command -v node >/dev/null 2>&1; then
    NODE_VER=$(node -v 2>/dev/null | sed 's/^v//')
    NODE_MAJOR=${NODE_VER%%.*}
    if [ "$NODE_MAJOR" -lt "$REQUIRED_NODE_MAJOR" ]; then
        echo "Node.js $NODE_VER detected. Please install Node.js >= $REQUIRED_NODE_MAJOR."
        echo "You can use nvm: nvm install $REQUIRED_NODE_MAJOR && nvm use $REQUIRED_NODE_MAJOR"
        exit 1
    fi
else
    echo "Node.js not found. Please install Node.js >= $REQUIRED_NODE_MAJOR."
    exit 1
fi

# Check if node_modules exists, if not install dependencies
if [ ! -d "node_modules" ]; then
    echo "Installing Node.js dependencies..."
    npm install
fi

# Start Next.js development server
echo "Starting Next.js development server..."

# Use PORT from environment or default to 3200
NEXTJS_PORT=${PORT:-3200}
export PORT=$NEXTJS_PORT

# Clear cache before starting (commented out to preserve compiled routes)
# echo "Clearing Next.js cache..."
# rm -rf .next 2>/dev/null || true
# rm -rf node_modules/.cache 2>/dev/null || true
echo "⚠️  Skipping cache clear to preserve compiled routes"
echo "   To force a fresh build, manually run: rm -rf .next"

# Verify app directory exists
if [ ! -d "src/app" ]; then
    echo "ERROR: src/app directory not found!"
    echo "Next.js requires src/app directory for App Router"
    exit 1
fi

# Verify route files are accessible
if [ ! -f "src/app/page.tsx" ]; then
    echo "ERROR: src/app/page.tsx not found!"
    exit 1
fi

# Use npm run dev which has the port configured in package.json
echo "Starting Next.js on port $NEXTJS_PORT using npm script..."
echo ""
echo "⚠️  IMPORTANT: Routes compile on first access in development mode"
echo "   First request to any route may take 5-10 seconds to compile"
echo "   Watch the logs for compilation messages"
echo ""

# Run npm run dev (app.sh handles background execution with nohup)
npm run dev
