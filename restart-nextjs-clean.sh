#!/bin/bash

echo "🔄 Restarting Next.js with Clean Cache..."
echo "========================================="
echo ""

cd /root/SocialPartners

echo "1️⃣ Stopping Next.js..."
lsof -ti:3200 | xargs kill -9 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
pkill -f "next-server" 2>/dev/null || true
sleep 3

echo "✅ Next.js stopped"
echo ""

echo "2️⃣ Clearing all Next.js cache..."
rm -rf .next
rm -rf .turbo
rm -rf .swc
rm -rf node_modules/.cache
rm -rf node_modules/.next
echo "✅ Cache cleared"
echo ""

echo "3️⃣ Verifying route files..."
if [ ! -f "src/app/page.tsx" ]; then
    echo "❌ ERROR: src/app/page.tsx is missing!"
    exit 1
fi

if [ ! -f "src/app/layout.tsx" ]; then
    echo "❌ ERROR: src/app/layout.tsx is missing!"
    exit 1
fi
echo "✅ Route files verified"
echo ""

echo "4️⃣ Starting Next.js..."
export PORT=3200
export BACKEND_URL="http://localhost:8200"
export FRONTEND_URL="http://localhost:3200"
export NODE_OPTIONS="--max-old-space-size=4096"
export NEXT_TELEMETRY_DISABLED=1

nohup npm run dev > /tmp/nextjs.log 2>&1 &
NEXTJS_PID=$!

echo "✅ Next.js started (PID: $NEXTJS_PID)"
echo "📋 View logs: tail -f /tmp/nextjs.log"
echo ""
echo "⏳ Waiting for Next.js to be ready..."
sleep 5

MAX_WAIT=30
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if tail -n 50 /tmp/nextjs.log 2>/dev/null | grep -qi "Ready"; then
        echo "✅ Next.js is ready!"
        echo ""
        echo "🌐 Access: http://localhost:3200"
        echo "   The root route will compile on first access (may take 5-10 seconds)"
        exit 0
    fi
    sleep 2
    WAITED=$((WAITED + 2))
    echo "   Waiting... (${WAITED}s)"
done

echo "⚠️  Next.js may still be starting..."
echo "   Check logs: tail -f /tmp/nextjs.log"
echo "   Access: http://localhost:3200"

