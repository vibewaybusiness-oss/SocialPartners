#!/bin/bash

echo "🔄 Resetting Next.js completely..."
echo "=================================="

cd "$(dirname "$0")"

echo ""
echo "🛑 Stopping Next.js..."
lsof -ti:3200 | xargs kill -9 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
sleep 2

echo ""
echo "🧹 Clearing all Next.js artifacts..."
rm -rf .next
rm -rf .turbo
rm -rf .swc
rm -rf node_modules/.cache
rm -rf node_modules/.next
find . -type d -name ".next" -exec rm -rf {} + 2>/dev/null || true

echo ""
echo "✅ Cache cleared"
echo ""
echo "📁 Verifying app structure..."
if [ -f "src/app/page.tsx" ]; then
    echo "✅ src/app/page.tsx exists"
else
    echo "❌ src/app/page.tsx MISSING!"
    exit 1
fi

if [ -f "src/app/layout.tsx" ]; then
    echo "✅ src/app/layout.tsx exists"
else
    echo "❌ src/app/layout.tsx MISSING!"
    exit 1
fi

if [ -f "src/app/dashboard/page.tsx" ]; then
    echo "✅ src/app/dashboard/page.tsx exists"
else
    echo "❌ src/app/dashboard/page.tsx MISSING!"
    exit 1
fi

echo ""
echo "🔍 Checking for TypeScript errors..."
if command -v npx >/dev/null 2>&1; then
    echo "Running TypeScript check..."
    npx tsc --noEmit --skipLibCheck 2>&1 | head -20
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "✅ No TypeScript errors found"
    else
        echo "⚠️  TypeScript errors found (may not prevent routes from working)"
    fi
else
    echo "⚠️  npx not found, skipping TypeScript check"
fi

echo ""
echo "🚀 Ready to start Next.js"
echo "Run: npm run dev"
echo "Or: ./app.sh"

