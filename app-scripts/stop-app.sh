#!/bin/bash

# SocialPartners Development Environment Stop Script
# This script stops all running services and processes related to the project
# 
# NOTE: Uses unique container names (socialpartners-*) to avoid conflicts
# with other projects that may use clipizy-* container names

echo "🛑 Stopping SocialPartners Development Environment..."
echo "====================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to kill processes on a specific port
kill_port() {
    local port=$1
    local service_name=$2
    
    if lsof -ti:$port >/dev/null 2>&1; then
        echo -e "${BLUE}🔪 Killing processes on port $port ($service_name)...${NC}"
        # Try graceful kill first
        kill $(lsof -ti:$port) 2>/dev/null || true
        sleep 2
        # Force kill if still running
        if lsof -ti:$port >/dev/null 2>&1; then
            kill -9 $(lsof -ti:$port) 2>/dev/null || true
        fi
        echo -e "${GREEN}✅ Port $port ($service_name) cleared${NC}"
    else
        echo -e "${YELLOW}⚠️  No processes found on port $port ($service_name)${NC}"
    fi
}

# Function to stop Docker containers
stop_docker_container() {
    local container_name=$1
    local service_name=$2
    
    if docker ps -q -f name=$container_name | grep -q .; then
        echo -e "${BLUE}🐳 Stopping $service_name container...${NC}"
        docker stop $container_name 2>/dev/null || true
        docker rm $container_name 2>/dev/null || true
        echo -e "${GREEN}✅ $service_name container stopped and removed${NC}"
    else
        echo -e "${YELLOW}⚠️  $service_name container not found${NC}"
    fi
}

# PROJECT-SPECIFIC CONTAINER NAMES - Use unique names to avoid conflicts with other projects
PROJECT_PREFIX="socialpartners"
POSTGRES_CONTAINER="${PROJECT_PREFIX}-postgres"
MINIO_CONTAINER="${PROJECT_PREFIX}-minio"

# Stop Docker containers
echo -e "${BLUE}🐳 Stopping Docker containers...${NC}"
stop_docker_container "${MINIO_CONTAINER}" "MinIO"
stop_docker_container "${POSTGRES_CONTAINER}" "PostgreSQL"

# Stop all possible frontend ports
echo -e "${BLUE}⚛️  Stopping Frontend services...${NC}"
kill_port 3200 "Next.js (default)"
kill_port 3201 "Next.js (alternative)"
kill_port 3202 "Next.js (alternative 2)"
kill_port 3203 "Next.js (alternative 3)"

# Stop backend services
echo -e "${BLUE}🐍 Stopping Backend services...${NC}"
kill_port 8200 "FastAPI"
kill_port 8201 "FastAPI (alternative)"
kill_port 8202 "FastAPI (alternative 2)"

# Stop ComfyUI
echo -e "${BLUE}🎨 Stopping ComfyUI...${NC}"
kill_port 8388 "ComfyUI"
kill_port 8389 "ComfyUI (alternative)"

# Stop MinIO ports
echo -e "${BLUE}🗄️  Stopping MinIO services...${NC}"
kill_port 9200 "MinIO"
kill_port 9201 "MinIO Console"

# Stop PostgreSQL ports
echo -e "${BLUE}🗄️  Stopping PostgreSQL services...${NC}"
kill_port 5632 "PostgreSQL (default)"
kill_port 5633 "PostgreSQL (alternative)"

# Kill any remaining Python processes related to SocialPartners project
echo -e "${BLUE}🐍 Killing remaining Python processes...${NC}"
# Only kill processes on our specific ports to avoid interfering with clipizy
# Kill uvicorn processes on our port (8200) - clipizy uses 8000
pkill -f "uvicorn.*port.*8200" 2>/dev/null || true
pkill -f "uvicorn.*8200" 2>/dev/null || true
# Kill our specific start script processes
pkill -f "python.*scripts/backend/start.py" 2>/dev/null || true

# Kill any remaining Node.js processes related to the project on our port
echo -e "${BLUE}⚛️  Killing remaining Node.js processes...${NC}"
pkill -f "next dev.*3200" 2>/dev/null || true
pkill -f "next dev.*-p 3200" 2>/dev/null || true
pkill -f "npx.*next dev.*3200" 2>/dev/null || true

# Note: We rely on port-based isolation rather than process name matching
# This ensures we don't accidentally kill clipizy processes
# Ports are already isolated: SocialPartners uses 3200/8200, clipizy uses 3000/8000

# Clear caches to prevent webpack cache corruption
echo -e "${BLUE}🧹 Clearing application caches...${NC}"
if [ -d ".next" ]; then
    echo -e "${BLUE}🗑️  Removing Next.js build cache (.next)...${NC}"
    rm -rf .next
    echo -e "${GREEN}✅ Next.js build cache cleared${NC}"
else
    echo -e "${YELLOW}⚠️  No .next directory found${NC}"
fi

if [ -d "node_modules/.cache" ]; then
    echo -e "${BLUE}🗑️  Removing Node.js cache (node_modules/.cache)...${NC}"
    rm -rf node_modules/.cache
    echo -e "${GREEN}✅ Node.js cache cleared${NC}"
else
    echo -e "${YELLOW}⚠️  No node_modules/.cache directory found${NC}"
fi

# Clear Python cache files
echo -e "${BLUE}🗑️  Removing Python cache files (__pycache__)...${NC}"
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -delete 2>/dev/null || true
echo -e "${GREEN}✅ Python cache files cleared${NC}"

# Clear npm cache
echo -e "${BLUE}🗑️  Clearing npm cache...${NC}"
npm cache clean --force 2>/dev/null || true
echo -e "${GREEN}✅ npm cache cleared${NC}"

# Clean up any remaining processes on our development ports
echo -e "${BLUE}🧹 Cleaning up our development ports...${NC}"
for port in 3200 3201 3202 3203 8200 8201 8202 8388 8389 9200 9201 5632 5633; do
    if lsof -ti:$port >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Found remaining process on port $port, force killing...${NC}"
        kill -9 $(lsof -ti:$port) 2>/dev/null || true
    fi
done

# Show final status
echo ""
echo -e "${GREEN}🎉 All SocialPartners services stopped!${NC}"
echo "====================================================="

# Check if any ports are still in use
echo -e "${BLUE}📊 Final port status check:${NC}"
ports_to_check=(3200 3201 3202 3203 8200 8201 8202 8388 8389 9200 9201 5632 5633)
any_ports_in_use=false

for port in "${ports_to_check[@]}"; do
    if lsof -ti:$port >/dev/null 2>&1; then
        echo -e "${RED}❌ Port $port is still in use${NC}"
        any_ports_in_use=true
    else
        echo -e "${GREEN}✅ Port $port is free${NC}"
    fi
done

if [ "$any_ports_in_use" = true ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Some ports are still in use. You may need to manually kill those processes.${NC}"
    echo -e "${YELLOW}💡 To see what's using a port, run: lsof -i :PORT_NUMBER${NC}"
    echo -e "${YELLOW}💡 To force kill a process, run: kill -9 PID${NC}"
else
    echo ""
    echo -e "${GREEN}✅ All ports are now free!${NC}"
fi

echo ""
echo -e "${YELLOW}💡 To start services again, run: ./app.sh${NC}"
echo -e "${YELLOW}💡 To check running processes, run: ps aux | grep -E '(python|node|next)'${NC}"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"
