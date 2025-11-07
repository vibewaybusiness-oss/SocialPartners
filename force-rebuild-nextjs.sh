#!/bin/bash

echo "🔨 Force Rebuilding Next.js Routes..."
echo "====================================="

cd "$(dirname "$0")"

echo ""
echo "🛑 Stopping Next.js..."
lsof -ti:3200 | xargs kill -9 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
sleep 3

echo ""
echo "🧹 Complete cache cleanup..."
rm -rf .next
rm -rf .turbo  
rm -rf .swc
rm -rf node_modules/.cache
rm -rf node_modules/.next
find . -maxdepth 3 -type d -name ".next" -exec rm -rf {} + 2>/dev/null || true

echo ""
echo "✅ Cache cleared"
echo ""
echo "🔍 Verifying route files..."
ROUTES_OK=true

check_route() {
    if [ -f "$1" ]; then
        echo "✅ $1 exists"
        if grep -q "export default" "$1"; then
            echo "   ✓ Has default export"
        else
            echo "   ❌ Missing default export!"
            ROUTES_OK=false
        fi
    else
        echo "❌ $1 MISSING!"
        ROUTES_OK=false
    fi
}

check_route "src/app/page.tsx"
check_route "src/app/layout.tsx"
check_route "src/app/dashboard/page.tsx"

if [ "$ROUTES_OK" = false ]; then
    echo ""
    echo "❌ Route files have issues!"
    exit 1
fi

echo ""
echo "🔧 Checking Next.js can detect routes..."
if [ -d "src/app" ]; then
    ROUTE_COUNT=$(find src/app -name "page.tsx" -o -name "page.ts" 2>/dev/null | wc -l)
    echo "Found $ROUTE_COUNT route files in src/app"
    if [ "$ROUTE_COUNT" -eq 0 ]; then
        echo "❌ No route files found!"
        exit 1
    fi
else
    echo "❌ src/app directory not found!"
    exit 1
fi

echo ""
echo "🚀 Starting Next.js with verbose output..."
export PORT=3200
export NODE_OPTIONS="--max-old-space-size=4096"

echo ""
echo "Starting server... (check terminal for compilation output)"
echo "After it says 'Ready', wait 5 seconds then try:"
echo "  http://localhost:3200/"
echo "  http://localhost:3200/dashboard"
echo ""

npm run dev

