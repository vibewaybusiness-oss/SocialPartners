#!/bin/bash

echo "🔍 Checking Next.js Compilation Status..."
echo ""

# CHECK IF NEXTJS PROCESS IS RUNNING
if pgrep -f "next dev" > /dev/null 2>&1; then
    echo "✅ Next.js process is running"
    NEXTJS_PID=$(pgrep -f "next dev" | head -1)
    echo "   PID: $NEXTJS_PID"
else
    echo "❌ Next.js process is NOT running"
    echo "   Start it with: npm run dev"
    exit 1
fi

echo ""

# CHECK IF PORT 3200 IS LISTENING
if ss -tuln 2>/dev/null | grep -q ":3200 " || netstat -tuln 2>/dev/null | grep -q ":3200 "; then
    echo "✅ Port 3200 is listening"
else
    echo "⚠️  Port 3200 is NOT listening yet"
    echo "   Next.js may still be starting up..."
fi

echo ""

# CHECK .NEXT DIRECTORY
if [ -d ".next" ]; then
    echo "✅ .next directory exists"
    
    # Check if app pages are built
    if [ -d ".next/server/app" ]; then
        echo "   Server app directory exists"
        
        # Count compiled pages
        PAGE_COUNT=$(find .next/server/app -name "*.js" 2>/dev/null | wc -l)
        echo "   Compiled pages: $PAGE_COUNT"
        
        # List app routes
        echo ""
        echo "📁 Compiled routes in .next/server/app:"
        find .next/server/app -type d -maxdepth 2 2>/dev/null | sed 's|.next/server/app||' | grep -v "^$" | head -20
    else
        echo "   ⚠️  Server app directory doesn't exist yet"
    fi
else
    echo "❌ .next directory doesn't exist"
    echo "   Run: npm run dev"
    exit 1
fi

echo ""
echo "🌐 Testing HTTP response..."

# Try to fetch the homepage
if command -v curl > /dev/null 2>&1; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3200/ 2>/dev/null)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Homepage returns HTTP $HTTP_CODE (OK)"
    elif [ "$HTTP_CODE" = "404" ]; then
        echo "❌ Homepage returns HTTP $HTTP_CODE (Not Found)"
        echo ""
        echo "💡 This likely means the route hasn't compiled yet."
        echo "   Next.js compiles routes on FIRST ACCESS in development mode."
        echo ""
        echo "🔄 Trying to trigger compilation..."
        
        # Make a few requests to trigger compilation
        for i in {1..3}; do
            echo "   Request $i/3..."
            curl -s http://localhost:3200/ > /dev/null 2>&1
            sleep 2
        done
        
        echo ""
        echo "🔄 Testing again..."
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3200/ 2>/dev/null)
        
        if [ "$HTTP_CODE" = "200" ]; then
            echo "✅ Homepage now returns HTTP $HTTP_CODE (OK)"
            echo "   ✨ Compilation successful!"
        else
            echo "❌ Homepage still returns HTTP $HTTP_CODE"
            echo ""
            echo "📝 Check Next.js logs for compilation errors:"
            echo "   tail -f /tmp/nextjs.log"
            echo "   OR check the terminal where you ran 'npm run dev'"
        fi
    else
        echo "⚠️  Homepage returns HTTP $HTTP_CODE"
    fi
else
    echo "❌ curl not found - cannot test HTTP response"
fi

echo ""
echo "📊 Next.js Status Summary:"
echo "   Process: $(pgrep -f 'next dev' > /dev/null 2>&1 && echo 'Running' || echo 'Not Running')"
echo "   Port: $(ss -tuln 2>/dev/null | grep -q ':3200 ' && echo 'Listening' || echo 'Not Listening')"
echo "   .next dir: $([ -d '.next' ] && echo 'Exists' || echo 'Missing')"
echo "   Compiled pages: $(find .next/server/app -name '*.js' 2>/dev/null | wc -l)"
echo ""
echo "💡 If homepage is 404:"
echo "   1. Wait 10-15 seconds for initial compilation"
echo "   2. Refresh your browser (Ctrl+Shift+R)"
echo "   3. Check terminal logs for compilation errors"
echo "   4. Try: rm -rf .next && npm run dev"

