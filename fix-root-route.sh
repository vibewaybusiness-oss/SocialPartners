#!/bin/bash

echo "🔧 Fixing Root Route 404 Issue..."
echo "=================================="
echo ""

cd "$(dirname "$0")"

echo "1️⃣ Stopping Next.js if running..."
lsof -ti:3200 | xargs kill -9 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
sleep 2

echo ""
echo "2️⃣ Clearing Next.js cache..."
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

echo "✅ Route files exist"

echo ""
echo "4️⃣ Checking for TypeScript errors..."
if command -v npx >/dev/null 2>&1; then
    npx tsc --noEmit 2>&1 | head -30
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "✅ No TypeScript errors"
    else
        echo "⚠️  TypeScript errors found - these may prevent route compilation"
    fi
fi

echo ""
echo "5️⃣ Starting Next.js..."
echo "   The root route should compile automatically on first access"
echo "   Access http://localhost:3200/ in your browser"
echo ""

export PORT=3200
export NODE_OPTIONS="--max-old-space-size=4096"
export NEXT_TELEMETRY_DISABLED=1

npm run dev

