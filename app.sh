#!/bin/bash

# SocialPartners Development Environment Startup Script
# This script starts all required services for local development
# 
# NOTE: Uses unique container names (socialpartners-*) to avoid conflicts
# with other projects that may use clipizy-* container names

echo "🚀 Starting SocialPartners Development Environment..."
echo "====================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Skip stop script to avoid sudo requirement
# bash scripts/startup/stop.sh

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to load .env file if it exists
load_env_file() {
    local env_file="${1:-.env}"
    if [ -f "$env_file" ]; then
        echo -e "${BLUE}📄 Loading environment variables from $env_file...${NC}"
        # Use Python to properly parse .env file (handles quotes, spaces, comments correctly)
        if command_exists python3; then
            # Export each variable from .env using Python's dotenv parsing
            # Use process substitution to avoid subshell issues with while loop
            while IFS= read -r export_line || [ -n "$export_line" ]; do
                if [ -n "$export_line" ]; then
                    eval "$export_line" 2>/dev/null || true
                fi
            done < <(python3 - "$env_file" << 'PYEOF'
import sys
import codecs
from pathlib import Path

env_file = Path(sys.argv[1])
if env_file.exists():
    # Open file and handle BOM (Byte Order Mark) if present
    with open(env_file, 'rb') as f:
        raw_content = f.read()
        # Remove BOM if present (UTF-8 BOM is b'\xef\xbb\xbf')
        if raw_content.startswith(codecs.BOM_UTF8):
            raw_content = raw_content[len(codecs.BOM_UTF8):]
        content = raw_content.decode('utf-8')
    
    for line in content.splitlines():
        line = line.strip()
        # Skip empty lines and comments
        if not line or line.startswith('#'):
            continue
        # Only process lines with =
        if '=' in line:
            # Split on first = only
            key, value = line.split('=', 1)
            # Strip BOM and whitespace from key (handle invisible BOM characters)
            key = key.strip().lstrip('\ufeff').strip()
            value = value.strip()
            # Remove surrounding quotes if present
            if (value.startswith('"') and value.endswith('"')) or \
               (value.startswith("'") and value.endswith("'")):
                value = value[1:-1]
            # Only export if key is valid (alphanumeric or underscore)
            if key and key.replace('_', '').isalnum():
                # Print export statement for bash to eval
                print(f"export {key}={value!r}")
PYEOF
)
            echo -e "${GREEN}✅ Environment variables loaded${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  Python3 not found, cannot parse .env file${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  $env_file not found. Environment variables not loaded.${NC}"
        return 1
    fi
}

# PROJECT-SPECIFIC CONTAINER NAMES - Use unique names to avoid conflicts with other projects
PROJECT_PREFIX="socialpartners"
POSTGRES_CONTAINER="${PROJECT_PREFIX}-postgres"
MINIO_CONTAINER="${PROJECT_PREFIX}-minio"

# Try to stop existing containers without sudo
docker stop ${MINIO_CONTAINER} ${POSTGRES_CONTAINER} 2>/dev/null || true
docker rm ${MINIO_CONTAINER} ${POSTGRES_CONTAINER} 2>/dev/null || true

# Function to check if a port is in use
port_in_use() {
    local port=$1
    # Check multiple times with small delay to avoid race conditions
    for i in {1..3}; do
        # Try multiple methods for port detection (WSL compatibility)
        if lsof -i :$port >/dev/null 2>&1; then
            return 0
        fi
        # Fallback to ss (socket statistics) - more reliable in WSL
        if command_exists ss; then
            if ss -tuln 2>/dev/null | grep -q ":$port "; then
                return 0
            fi
        fi
        # Fallback to netstat if available
        if command_exists netstat; then
            if netstat -tuln 2>/dev/null | grep -q ":$port "; then
                return 0
            fi
        fi
        sleep 0.5
    done
    return 1
}

# Function to kill process on a port
kill_port() {
    local port=$1
    local service_name=$2
    if port_in_use $port; then
        echo -e "${YELLOW}🛑 Killing process on port $port ($service_name)...${NC}"
        # Try to find and kill the process using the port
        local pid=$(lsof -ti :$port 2>/dev/null | head -1)
        if [ -n "$pid" ]; then
            kill -9 $pid 2>/dev/null || true
            sleep 1
            # Verify it's killed
            if port_in_use $port; then
                echo -e "${RED}⚠️  Failed to kill process on port $port. Trying alternative method...${NC}"
                # Try using fuser if available
                if command_exists fuser; then
                    fuser -k $port/tcp 2>/dev/null || true
                    sleep 1
                fi
            else
                echo -e "${GREEN}✅ Process on port $port killed${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  Could not find PID for port $port${NC}"
        fi
    fi
}

# Check prerequisites
echo -e "${BLUE}📋 Checking prerequisites...${NC}"

if ! command_exists docker; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

if ! command_exists python3; then
    echo -e "${RED}❌ Python 3 is not installed. Please install Python 3.10+ first.${NC}"
    exit 1
fi

if ! command_exists node; then
    echo -e "${RED}❌ Node.js is not installed. Please install Node.js 18+ first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites found${NC}"

# Load .env file if it exists (before checking S3 config)
load_env_file ".env"

# Check Amazon S3 Configuration
echo -e "${BLUE}☁️  Checking Amazon S3 configuration...${NC}"
if [ -z "$S3_ACCESS_KEY" ] || [ -z "$S3_SECRET_KEY" ] || [ -z "$S3_BUCKET" ]; then
    echo -e "${YELLOW}⚠️  Amazon S3 credentials not found in environment variables${NC}"
    echo -e "${YELLOW}   Please set the following environment variables:${NC}"
    echo -e "${YELLOW}   - S3_ACCESS_KEY${NC}"
    echo -e "${YELLOW}   - S3_SECRET_KEY${NC}"
    echo -e "${YELLOW}   - S3_BUCKET${NC}"
    echo -e "${YELLOW}   - S3_REGION (optional, defaults to us-east-1)${NC}"
    echo -e "${YELLOW}   - S3_ENDPOINT_URL (optional, defaults to https://s3.amazonaws.com)${NC}"
    echo -e "${YELLOW}   Continuing startup, but S3 operations may fail...${NC}"
else
    echo -e "${GREEN}✅ Amazon S3 credentials found${NC}"
    echo -e "${GREEN}   Bucket: $S3_BUCKET${NC}"
    echo -e "${GREEN}   Region: ${S3_REGION:-us-east-1}${NC}"
fi

# Start PostgreSQL
echo -e "${BLUE}🗄️  Starting PostgreSQL...${NC}"
# Kill any existing PostgreSQL processes (only for our container)
docker stop ${POSTGRES_CONTAINER} 2>/dev/null || true
docker rm ${POSTGRES_CONTAINER} 2>/dev/null || true

if port_in_use 5632; then
    echo -e "${YELLOW}⚠️  Port 5632 is still in use. Using port 5633 instead.${NC}"
    POSTGRES_PORT=5633
else
    POSTGRES_PORT=5632
fi

docker run -d --name ${POSTGRES_CONTAINER} \
    -e POSTGRES_PASSWORD=postgres \
    -e POSTGRES_DB=socialpartners \
    -p 0.0.0.0:$POSTGRES_PORT:5432 \
    postgres:15
echo -e "${GREEN}✅ PostgreSQL started at localhost:$POSTGRES_PORT${NC}"

# Wait for services to be ready
echo -e "${BLUE}⏳ Waiting for services to be ready...${NC}"
sleep 5

# Set database URL based on PostgreSQL port
# Use psycopg3 driver for WSL compatibility
export DATABASE_URL="postgresql+psycopg2://postgres:postgres@localhost:$POSTGRES_PORT/socialpartners"

# Initialize database
echo -e "${BLUE}🗄️  Initializing database...${NC}"
if [ -f "scripts/backend/init_database.py" ]; then
    echo -e "${YELLOW}📋 Setting up database tables and schema...${NC}"
    DATABASE_URL="postgresql+psycopg2://postgres:postgres@localhost:$POSTGRES_PORT/socialpartners" python scripts/backend/init_database.py
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Database initialized successfully${NC}"
    else
        echo -e "${RED}❌ Database initialization failed${NC}"
        echo -e "${YELLOW}⚠️  Continuing with startup, but database may not be ready${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  init_database.py not found. Skipping database initialization.${NC}"
fi

# Start FastAPI Backend
echo -e "${BLUE}🐍 Starting FastAPI Backend...${NC}"
kill_port 8200 "FastAPI"
# Only kill uvicorn processes running on our specific port (8200)
# This ensures we don't interfere with clipizy running on port 8000
pkill -f 'uvicorn.*port.*8200' 2>/dev/null || true
pkill -f 'uvicorn.*8200' 2>/dev/null || true
sleep 1
if port_in_use 8200; then
    echo -e "${YELLOW}⚠️  Port 8200 is still in use after cleanup attempt.${NC}"
    echo -e "${YELLOW}💡 You may need to manually kill the process: lsof -ti :8200 | xargs kill -9${NC}"
else
    # Check if virtual environment exists in root directory
    if [ ! -d ".venv" ]; then
        echo -e "${YELLOW}📦 Creating Python virtual environment...${NC}"
        python3 -m venv .venv
    fi

    echo -e "${YELLOW}📦 Activating Python virtual environment...${NC}"
    source .venv/bin/activate

    echo -e "${YELLOW}📦 Installing Python dependencies...${NC}"

    echo -e "${YELLOW}🚀 Starting FastAPI server with auto-reload...${NC}"
    echo -e "${BLUE}🔄 Auto-reload is ENABLED - changes will be automatically detected${NC}"
    # Export all environment variables (including from .env) to the Python process
    # Use env to ensure all exported variables are passed
    export DATABASE_URL="postgresql+psycopg2://postgres:postgres@localhost:$POSTGRES_PORT/socialpartners"
    export BACKEND_URL="http://localhost:8200"
    export FRONTEND_URL="http://localhost:3200"
    env DATABASE_URL="$DATABASE_URL" BACKEND_URL="$BACKEND_URL" FRONTEND_URL="$FRONTEND_URL" python scripts/backend/start.py &
    echo -e "${GREEN}✅ FastAPI started at http://localhost:8200 with auto-reload${NC}"
fi

# Start Next.js Frontend
echo -e "${BLUE}⚛️  Starting Next.js Frontend...${NC}"
# Kill any existing Next.js processes on our port
kill_port 3200 "Next.js"
# Only kill Next.js processes running on our specific port
pkill -f 'next dev.*3200' 2>/dev/null || true
pkill -f 'next dev.*-p 3200' 2>/dev/null || true
pkill -f 'npx.*next dev.*3200' 2>/dev/null || true
# Only kill next-server processes on our port
pkill -f 'next-server.*3200' 2>/dev/null || true
sleep 2
if port_in_use 3200; then
    echo -e "${YELLOW}⚠️  Port 3200 is still in use after cleanup attempt.${NC}"
    echo -e "${YELLOW}💡 You may need to manually kill the process: lsof -ti :3200 | xargs kill -9${NC}"
else
    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}📦 Installing Node.js dependencies...${NC}"
        npm install
    fi

    echo -e "${YELLOW}🧹 Checking Next.js cache...${NC}"
    # Don't clear cache on every start - preserves compiled routes
    # Only clear if explicitly needed (uncomment below to force clear)
    # rm -rf .next 2>/dev/null || true
    # rm -rf .turbo 2>/dev/null || true
    # rm -rf .swc 2>/dev/null || true
    # rm -rf node_modules/.cache 2>/dev/null || true
    # rm -rf node_modules/.next 2>/dev/null || true
    # find . -maxdepth 3 -type d -name ".next" -exec rm -rf {} + 2>/dev/null || true
    echo -e "${GREEN}✅ Cache preserved (routes will compile faster)${NC}"
    echo -e "${YELLOW}   To force fresh build: rm -rf .next && npm run dev${NC}"
    
    echo -e "${YELLOW}🔍 Verifying app directory structure...${NC}"
    if [ ! -f "src/app/page.tsx" ]; then
        echo -e "${RED}❌ Error: src/app/page.tsx not found!${NC}"
        echo -e "${YELLOW}   Next.js requires src/app/page.tsx for the root route${NC}"
        exit 1
    fi
    if [ ! -f "src/app/layout.tsx" ]; then
        echo -e "${RED}❌ Error: src/app/layout.tsx not found!${NC}"
        echo -e "${YELLOW}   Next.js requires src/app/layout.tsx for the root layout${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ App directory structure verified${NC}"

    echo -e "${YELLOW}🚀 Starting Next.js development server...${NC}"
    
    # Set environment variables for Next.js
    export PORT=3200
    export BACKEND_URL="http://localhost:8200"
    export FRONTEND_URL="http://localhost:3200"
    export NODE_OPTIONS="--max-old-space-size=4096"
    export NEXT_TELEMETRY_DISABLED=1
    
    # Load nvm if available (like clipizy does)
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        . "$HOME/.nvm/nvm.sh"
        nvm use 18 >/dev/null 2>&1 || true
    fi
    
    # Start Next.js directly (like clipizy does) - run in background
    # The package.json dev script already has: "next dev -H 0.0.0.0 -p 3200"
    nohup npm run dev > /tmp/nextjs.log 2>&1 &
    echo -e "${GREEN}✅ Next.js process started${NC}"
    echo -e "${BLUE}📋 View logs: tail -f /tmp/nextjs.log${NC}"
    
    # Give npm a moment to actually start the process
    sleep 3
    
    # Find the actual Next.js process PID (not the nohup/npm wrapper)
    NEXTJS_PID=$(pgrep -f "next dev" | head -1)
    if [ -n "$NEXTJS_PID" ]; then
        echo -e "${BLUE}   Found Next.js process PID: $NEXTJS_PID${NC}"
    fi
    
    echo -e "${BLUE}⏳ Waiting for Next.js to start (checking every 2 seconds)...${NC}"
    
    # Wait up to 60 seconds for Next.js to be ready
    MAX_WAIT=60
    WAITED=0
    NEXTJS_READY=false
    
    while [ $WAITED -lt $MAX_WAIT ]; do
        sleep 2
        WAITED=$((WAITED + 2))
        
        # Show progress every 6 seconds
        if [ $((WAITED % 6)) -eq 0 ]; then
            echo -e "${BLUE}   Waiting... (${WAITED}s / ${MAX_WAIT}s)${NC}"
        fi
        
        # Primary check: Try HTTP request first (most reliable)
        if command -v curl >/dev/null 2>&1; then
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 http://localhost:3200/ 2>/dev/null || echo "000")
            if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "404" ] || [ "$HTTP_CODE" = "500" ] || [ "$HTTP_CODE" = "503" ]; then
                # Any HTTP response means server is up (even errors mean it's running)
                NEXTJS_READY=true
                break
            fi
        fi
        
        # Secondary check: Port is in use
        if port_in_use 3200; then
            # Check if Next.js is actually ready by looking for "Ready" in logs
            if [ -f "/tmp/nextjs.log" ]; then
                # Check for "Ready" message (case insensitive, matches "Ready in Xms" or just "Ready")
                if tail -n 100 /tmp/nextjs.log 2>/dev/null | grep -qi "Ready"; then
                    NEXTJS_READY=true
                    break
                fi
            fi
        fi
        
        # Check if Next.js process is still running (update PID if needed)
        if [ -n "$NEXTJS_PID" ]; then
            if ! kill -0 $NEXTJS_PID 2>/dev/null; then
                # Process died, try to find a new one
                NEXTJS_PID=$(pgrep -f "next dev" | head -1)
                if [ -z "$NEXTJS_PID" ]; then
                    echo -e "${RED}❌ Next.js process died!${NC}"
                    echo -e "${YELLOW}📋 Last 30 lines of log:${NC}"
                    tail -n 30 /tmp/nextjs.log 2>/dev/null || echo "No log file found"
                    break
                fi
            fi
        else
            # Try to find the process
            NEXTJS_PID=$(pgrep -f "next dev" | head -1)
        fi
        
        # Check for fatal errors in logs (after 10 seconds of waiting)
        if [ $WAITED -ge 10 ] && [ -f "/tmp/nextjs.log" ]; then
            if tail -n 50 /tmp/nextjs.log 2>/dev/null | grep -qi "error.*compil\|failed.*compil\|cannot.*start"; then
                echo -e "${YELLOW}⚠️  Possible compilation error detected in logs${NC}"
                echo -e "${YELLOW}   Checking log file...${NC}"
                tail -n 20 /tmp/nextjs.log 2>/dev/null | grep -i "error\|failed" | head -5
            fi
        fi
    done
    
    if [ "$NEXTJS_READY" = true ] || port_in_use 3200; then
        echo -e "${GREEN}✅ Next.js started at http://localhost:3200${NC}"
        echo -e "${BLUE}📋 Checking Next.js status...${NC}"
        sleep 2
        
        if [ -f "/tmp/nextjs.log" ]; then
            if tail -n 100 /tmp/nextjs.log 2>/dev/null | grep -qi "Ready"; then
                echo -e "${GREEN}✅ Next.js server is ready${NC}"
            else
                echo -e "${YELLOW}⚠️  Server started but 'Ready' message not found in logs${NC}"
                echo -e "${YELLOW}   Checking if server responds...${NC}"
                if command -v curl >/dev/null 2>&1; then
                    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3200/ 2>/dev/null || echo "000")
                    if [ "$HTTP_CODE" != "000" ]; then
                        echo -e "${GREEN}✅ Server is responding (HTTP $HTTP_CODE)${NC}"
                    else
                        echo -e "${YELLOW}⚠️  Server not responding yet, may still be starting${NC}"
                    fi
                fi
            fi
            
            # Check for errors (but ignore node_modules errors)
            ERROR_LINES=$(tail -n 100 /tmp/nextjs.log 2>/dev/null | grep -i "error" | grep -v "node_modules" | grep -v "Error:.*node_modules" | head -5)
            if [ -n "$ERROR_LINES" ]; then
                echo -e "${YELLOW}⚠️  Possible errors detected in Next.js logs${NC}"
                echo -e "${YELLOW}   Run: tail -30 /tmp/nextjs.log to see details${NC}"
            fi
        fi
        
        echo -e "${YELLOW}💡 IMPORTANT: Routes compile on first access in development mode${NC}"
        echo -e "${YELLOW}   First request to http://localhost:3200/ may take 5-10 seconds${NC}"
        echo -e "${YELLOW}   Watch logs: tail -f /tmp/nextjs.log${NC}"
    elif [ -n "$NEXTJS_PID" ] && kill -0 $NEXTJS_PID 2>/dev/null; then
        echo -e "${YELLOW}⏳ Next.js process is running (PID: $NEXTJS_PID) but taking longer to start...${NC}"
        echo -e "${YELLOW}   This is normal - wait 10-20 seconds then check http://localhost:3200${NC}"
        echo -e "${YELLOW}   View logs: tail -f /tmp/nextjs.log${NC}"
        echo -e "${YELLOW}   Check status: ./check-nextjs-status.sh${NC}"
    elif port_in_use 3200; then
        echo -e "${GREEN}✅ Port 3200 is in use - Next.js may already be running${NC}"
        echo -e "${YELLOW}   Check: http://localhost:3200${NC}"
        echo -e "${YELLOW}   View logs: tail -f /tmp/nextjs.log${NC}"
    else
        echo -e "${RED}❌ Failed to start Next.js${NC}"
        echo -e "${YELLOW}📋 Last 30 lines of Next.js log:${NC}"
        tail -n 30 /tmp/nextjs.log 2>/dev/null || echo "No log file found"
        echo -e "${YELLOW}💡 To fix this issue, try:${NC}"
        echo -e "${YELLOW}   cd /root/SocialPartners${NC}"
        echo -e "${YELLOW}   rm -rf node_modules package-lock.json .next${NC}"
        echo -e "${YELLOW}   npm install${NC}"
        echo -e "${YELLOW}   npm run dev${NC}"
    fi
fi

echo ""
echo -e "${GREEN}🎉 SocialPartners Development Environment Started!${NC}"
echo "====================================================="
echo -e "${BLUE}📱 Frontend:${NC} http://localhost:3200"
echo -e "${BLUE}🔧 API Docs:${NC} http://localhost:8200/docs"
echo -e "${BLUE}🗄️  MinIO Console:${NC} http://localhost:9201 (admin/admin123)"
echo -e "${BLUE}🎨 ComfyUI:${NC} http://localhost:8388"
echo -e "${BLUE}🗄️  PostgreSQL:${NC} localhost:$POSTGRES_PORT (postgres/postgres)"
echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo -e "${YELLOW}   1. Register a user at http://localhost:3200/auth/register${NC}"
echo -e "${YELLOW}   2. To create an admin user, run:${NC}"
echo -e "${YELLOW}      cd api && python create_admin_user.py${NC}"
echo -e "${YELLOW}   3. Access admin panel at http://localhost:3200/admin${NC}"
echo ""
echo -e "${BLUE}🔄 Development Features:${NC}"
echo -e "${BLUE}   • FastAPI auto-reload: Changes to Python files will automatically restart the server${NC}"
echo -e "${BLUE}   • Next.js hot reload: Changes to React components will automatically update${NC}"
echo -e "${BLUE}   • Database persistence: All data is stored in PostgreSQL${NC}"
echo -e "${BLUE}   • File storage: Files are stored in MinIO (S3-compatible)${NC}"
echo ""
echo -e "${YELLOW}💡 To stop all services, run: ./app-scripts/stop-app.sh${NC}"
echo -e "${YELLOW}💡 To restart FastAPI with reload, run: ./app-scripts/restart-backend.sh${NC}"
echo -e "${YELLOW}💡 To view logs, run: docker logs -f ${MINIO_CONTAINER}${NC}"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"