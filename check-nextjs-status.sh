#!/bin/bash

echo "🔍 Checking Next.js Status..."
echo "============================="

PORT=3200

echo ""
echo "1️⃣ Checking if Next.js is running on port $PORT..."
if lsof -ti:$PORT >/dev/null 2>&1; then
    PID=$(lsof -ti:$PORT | head -1)
    echo "✅ Next.js is running (PID: $PID)"
    
    echo ""
    echo "2️⃣ Checking process details..."
    ps -p $PID -o pid,cmd --no-headers 2>/dev/null || echo "Process details not available"
else
    echo "❌ Next.js is NOT running on port $PORT"
    echo ""
    echo "Checking for any Next.js processes..."
    ps aux | grep -E "next dev|node.*next" | grep -v grep || echo "No Next.js processes found"
fi

echo ""
echo "3️⃣ Checking Next.js logs..."
if [ -f "/tmp/nextjs.log" ]; then
    echo "✅ Log file exists at /tmp/nextjs.log"
    echo ""
    echo "Last 30 lines:"
    echo "----------------------------------------"
    tail -30 /tmp/nextjs.log
    echo "----------------------------------------"
    
    echo ""
    echo "Checking for errors..."
    if tail -50 /tmp/nextjs.log | grep -qi "error\|failed\|cannot"; then
        echo "⚠️  Errors found in logs!"
        tail -50 /tmp/nextjs.log | grep -i "error\|failed\|cannot" | head -10
    else
        echo "✅ No obvious errors in recent logs"
    fi
    
    echo ""
    echo "Checking for route compilation..."
    if tail -50 /tmp/nextjs.log | grep -q "Compiling\|Compiled"; then
        echo "✅ Route compilation messages found"
        tail -50 /tmp/nextjs.log | grep "Compiling\|Compiled" | tail -5
    else
        echo "⚠️  No route compilation messages found"
    fi
else
    echo "⚠️  Log file /tmp/nextjs.log not found"
    echo "   Next.js may not have started yet"
fi

echo ""
echo "4️⃣ Testing if server responds..."
if command -v curl >/dev/null 2>&1; then
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/ 2>/dev/null)
    if [ "$response" = "200" ]; then
        echo "✅ Server responds with 200 OK"
    elif [ "$response" = "404" ]; then
        echo "❌ Server responds with 404 Not Found"
        echo "   Routes may not be compiled yet"
    elif [ "$response" = "000" ]; then
        echo "❌ Server not responding"
    else
        echo "⚠️  Server responds with status: $response"
    fi
else
    echo "⚠️  curl not available, cannot test server response"
fi

echo ""
echo "5️⃣ Checking .next directory..."
if [ -d ".next" ]; then
    echo "✅ .next directory exists"
    if [ -d ".next/server/app" ]; then
        echo "✅ .next/server/app exists"
        ROUTE_COUNT=$(find .next/server/app -name "page.js" -o -name "page.jsx" 2>/dev/null | wc -l)
        echo "   Found $ROUTE_COUNT compiled route files"
        if [ "$ROUTE_COUNT" -gt 0 ]; then
            echo "   Sample routes:"
            find .next/server/app -name "page.js" -o -name "page.jsx" 2>/dev/null | head -5
        fi
    else
        echo "⚠️  .next/server/app not found (routes not compiled)"
    fi
else
    echo "⚠️  .next directory doesn't exist"
    echo "   Routes will compile on first access"
fi

echo ""
echo "✅ Status check complete!"
echo ""
echo "💡 Next steps:"
if ! lsof -ti:$PORT >/dev/null 2>&1; then
    echo "   - Next.js is not running. Start it with: ./app.sh"
elif [ ! -d ".next/server/app" ]; then
    echo "   - Routes haven't compiled yet. Access http://localhost:$PORT/ to trigger compilation"
    echo "   - Watch logs: tail -f /tmp/nextjs.log"
else
    echo "   - Next.js appears to be running. Try accessing http://localhost:$PORT/"
    echo "   - If you get 404, check logs: tail -f /tmp/nextjs.log"
fi

