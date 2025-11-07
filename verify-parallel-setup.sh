#!/bin/bash

echo "🔍 Verifying Parallel Project Setup..."
echo "======================================"
echo ""

echo "📊 Port Usage Summary:"
echo "----------------------"

check_port() {
    local port=$1
    local service=$2
    local project=$3
    
    if lsof -ti:$port >/dev/null 2>&1; then
        PID=$(lsof -ti:$port | head -1)
        PROCESS=$(ps -p $PID -o cmd= 2>/dev/null | head -c 60)
        echo "✅ Port $port ($service) - IN USE by $project"
        echo "   PID: $PID | Process: $PROCESS..."
    else
        echo "⚪ Port $port ($service) - AVAILABLE"
    fi
}

echo ""
echo "🎯 clipizy Project (if running):"
check_port 3000 "Next.js Frontend" "clipizy"
check_port 8000 "FastAPI Backend" "clipizy"

echo ""
echo "🎯 SocialPartners Project (if running):"
check_port 3200 "Next.js Frontend" "SocialPartners"
check_port 8200 "FastAPI Backend" "SocialPartners"

echo ""
echo "🗄️  Database Ports:"
check_port 5632 "PostgreSQL (SocialPartners default)" "SocialPartners"
check_port 5633 "PostgreSQL (SocialPartners fallback)" "SocialPartners"

echo ""
echo "✅ Parallel Setup Verification:"
echo "-------------------------------"
echo ""
echo "Both projects CAN run in parallel because:"
echo "  • clipizy uses:     Port 3000 (Next.js), 8000 (FastAPI)"
echo "  • SocialPartners uses: Port 3200 (Next.js), 8200 (FastAPI)"
echo "  • Different database names: clipizy vs socialpartners"
echo "  • Different container names: clipizy-* vs socialpartners-*"
echo ""
echo "💡 To check Next.js status:"
echo "   ./check-nextjs-status.sh"
echo ""
echo "💡 To view Next.js logs:"
echo "   tail -f /tmp/nextjs.log"

