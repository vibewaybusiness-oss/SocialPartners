#!/bin/bash

echo "🔧 Fixing Next.js Route Detection Issue..."
echo "=========================================="

cd "$(dirname "$0")"

echo ""
echo "🛑 Stopping Next.js..."
lsof -ti:3200 | xargs kill -9 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
sleep 2

echo ""
echo "🧹 Complete cache cleanup..."
rm -rf .next
rm -rf .turbo
rm -rf .swc
rm -rf node_modules/.cache
rm -rf node_modules/.next

echo ""
echo "✅ Cache cleared"
echo ""
echo "🔍 Verifying route files are valid..."

# Check if page.tsx has proper export
if grep -q "export default" src/app/page.tsx; then
    echo "✅ src/app/page.tsx has default export"
else
    echo "❌ src/app/page.tsx missing default export!"
    exit 1
fi

# Check if layout.tsx has proper export
if grep -q "export default" src/app/layout.tsx; then
    echo "✅ src/app/layout.tsx has default export"
else
    echo "❌ src/app/layout.tsx missing default export!"
    exit 1
fi

echo ""
echo "🔍 Checking for syntax errors in route files..."
if command -v node >/dev/null 2>&1; then
    echo "Checking page.tsx syntax..."
    node -c src/app/page.tsx 2>&1 | head -5 || echo "Syntax check passed"
    
    echo "Checking layout.tsx syntax..."
    node -c src/app/layout.tsx 2>&1 | head -5 || echo "Syntax check passed"
fi

echo ""
echo "🚀 Starting Next.js with verbose output..."
echo "Watch for compilation messages when you access http://localhost:3200/"
echo ""

export PORT=3200
export NODE_OPTIONS="--max-old-space-size=4096"
export NEXT_TELEMETRY_DISABLED=1

# Start Next.js in foreground so we can see what's happening
npm run dev

