#!/bin/bash

# FIX NEXTJS 404 ERROR

echo "🔧 Fixing Next.js 404 Error..."
echo ""

cd "$(dirname "$0")"

# CHECK IF NEXTJS IS RUNNING
if ! pgrep -f "next dev" > /dev/null 2>&1; then
    echo "❌ Next.js is not running"
    echo "   Start it with: npm run dev"
    echo "   Or run: bash app.sh"
    exit 1
fi

echo "✅ Next.js process is running"
echo ""

# CHECK PORT
if ss -tuln 2>/dev/null | grep -q ":3200 " || netstat -tuln 2>/dev/null | grep -q ":3200 "; then
    echo "✅ Port 3200 is listening"
else
    echo "⚠️  Port 3200 is not listening yet - waiting..."
    sleep 3
fi

echo ""
echo "🔥 Triggering route compilation..."
echo "   This will force Next.js to compile the homepage"
echo ""

# TRIGGER COMPILATION WITH MULTIPLE REQUESTS
for i in {1..5}; do
    echo "   Request $i/5..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3200/ 2>/dev/null || echo "000")
    echo "   Response: HTTP $HTTP_CODE"
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo ""
        echo "✅ SUCCESS! Homepage is now compiled and accessible"
        echo "🌐 Open in browser: http://localhost:3200"
        echo ""
        echo "💡 Tip: The cache clearing in app/start-nextjs.sh has been"
        echo "   disabled to prevent this issue on future starts"
        exit 0
    fi
    
    sleep 2
done

echo ""
echo "❌ Still getting errors after 5 attempts"
echo ""
echo "📋 Next Steps:"
echo "   1. Check Next.js terminal logs for compilation errors"
echo "   2. Look for TypeScript or import errors"
echo "   3. Try rebuilding:"
echo "      rm -rf .next"
echo "      npm run dev"
echo ""
echo "   4. Check if there are any missing dependencies:"
echo "      npm install"
echo ""
echo "   5. Verify src/app/page.tsx exists and is valid TypeScript"
echo ""

# CHECK FOR COMMON ISSUES
if [ ! -f "src/app/page.tsx" ]; then
    echo "❌ ERROR: src/app/page.tsx is missing!"
fi

if [ ! -f "src/app/layout.tsx" ]; then
    echo "❌ ERROR: src/app/layout.tsx is missing!"
fi

if [ ! -d "node_modules" ]; then
    echo "❌ ERROR: node_modules directory is missing - run npm install"
fi

exit 1

