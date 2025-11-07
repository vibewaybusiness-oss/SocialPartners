#!/bin/bash

echo "🔧 Fixing App Directory Conflict..."
echo "==================================="
echo ""

cd /root/SocialPartners

echo "1️⃣ Stopping Next.js..."
lsof -ti:3200 | xargs kill -9 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
sleep 2

echo "2️⃣ Renaming conflicting 'app' directory..."
if [ -d "app" ]; then
    if [ -d "app-scripts" ]; then
        echo "   ⚠️  app-scripts already exists, removing old one..."
        rm -rf app-scripts
    fi
    mv app app-scripts
    echo "   ✅ Renamed 'app' to 'app-scripts'"
    echo "   Next.js will now use 'src/app'"
else
    echo "   ✅ No 'app' directory found (already fixed)"
fi
echo ""

echo "3️⃣ Verifying src/app structure..."
if [ -f "src/app/page.tsx" ] && [ -f "src/app/layout.tsx" ]; then
    echo "   ✅ src/app/page.tsx exists"
    echo "   ✅ src/app/layout.tsx exists"
else
    echo "   ❌ Missing route files in src/app!"
    exit 1
fi
echo ""

echo "4️⃣ Clearing Next.js cache..."
rm -rf .next .turbo .swc node_modules/.cache node_modules/.next
echo "   ✅ Cache cleared"
echo ""

echo "5️⃣ Starting Next.js..."
export PORT=3200
export BACKEND_URL="http://localhost:8200"
export FRONTEND_URL="http://localhost:3200"
export NODE_OPTIONS="--max-old-space-size=4096"
export NEXT_TELEMETRY_DISABLED=1

nohup npm run dev > /tmp/nextjs.log 2>&1 &
NEXTJS_PID=$!

echo "   ✅ Next.js started (PID: $NEXTJS_PID)"
echo "   📋 View logs: tail -f /tmp/nextjs.log"
echo ""

echo "6️⃣ Waiting for Next.js to be ready..."
sleep 8

if tail -n 50 /tmp/nextjs.log 2>/dev/null | grep -qi "Ready"; then
    echo "   ✅ Next.js is ready!"
    echo ""
    echo "7️⃣ Testing root route..."
    sleep 3
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://localhost:3200/ 2>/dev/null || echo "000")
    echo "   HTTP Response: $HTTP_CODE"
    echo ""
    
    echo "📋 Checking compilation logs..."
    tail -30 /tmp/nextjs.log | grep -E "Compiling|Compiled|Error|GET /" | tail -10
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo ""
        echo "✅ SUCCESS! Root route is now working!"
        echo "🌐 Access: http://localhost:3200/"
    elif tail -n 50 /tmp/nextjs.log 2>/dev/null | grep -q "Compiling /"; then
        echo ""
        echo "✅ Route is compiling! Wait a few seconds and try again."
        echo "   The first compilation may take 5-10 seconds"
        echo "🌐 Access: http://localhost:3200/"
    else
        echo ""
        echo "⚠️  Route may still be compiling..."
        echo "   Check logs: tail -f /tmp/nextjs.log"
        echo "   Look for 'Compiling /' message"
    fi
else
    echo "   ⚠️  Next.js may still be starting..."
    echo "   Check logs: tail -f /tmp/nextjs.log"
fi

echo ""
echo "💡 Note: Scripts moved from 'app/' to 'app-scripts/'"
echo "   Update any references if needed"

