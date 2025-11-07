#!/bin/bash

echo "🔍 Checking Next.js route configuration..."
echo "=========================================="

cd "$(dirname "$0")"

echo ""
echo "📁 Checking app directory structure..."
if [ -d "src/app" ]; then
    echo "✅ src/app directory exists"
    
    if [ -f "src/app/page.tsx" ]; then
        echo "✅ src/app/page.tsx exists"
    else
        echo "❌ src/app/page.tsx MISSING!"
    fi
    
    if [ -f "src/app/layout.tsx" ]; then
        echo "✅ src/app/layout.tsx exists"
    else
        echo "❌ src/app/layout.tsx MISSING!"
    fi
    
    if [ -f "src/app/dashboard/page.tsx" ]; then
        echo "✅ src/app/dashboard/page.tsx exists"
    else
        echo "❌ src/app/dashboard/page.tsx MISSING!"
    fi
else
    echo "❌ src/app directory MISSING!"
fi

echo ""
echo "📦 Checking Next.js configuration..."
if [ -f "next.config.ts" ]; then
    echo "✅ next.config.ts exists"
else
    echo "❌ next.config.ts MISSING!"
fi

if [ -f "package.json" ]; then
    echo "✅ package.json exists"
    if grep -q '"dev".*3200' package.json; then
        echo "✅ package.json dev script configured for port 3200"
    else
        echo "⚠️  package.json dev script may not be configured for port 3200"
    fi
else
    echo "❌ package.json MISSING!"
fi

echo ""
echo "🗑️  Checking build artifacts..."
if [ -d ".next" ]; then
    echo "⚠️  .next directory exists (will be cleared on next start)"
    if [ -d ".next/server/app" ]; then
        echo "   .next/server/app exists"
        ROUTE_COUNT=$(find .next/server/app -name "page.js" -o -name "page.jsx" 2>/dev/null | wc -l)
        echo "   Found $ROUTE_COUNT compiled route files"
    else
        echo "   .next/server/app does not exist (routes not compiled)"
    fi
else
    echo "✅ .next directory does not exist (will be created on first build)"
fi

echo ""
echo "🔧 Checking TypeScript configuration..."
if [ -f "tsconfig.json" ]; then
    echo "✅ tsconfig.json exists"
    if grep -q '"@/\*":\s*\["./src/\*"\]' tsconfig.json; then
        echo "✅ Path alias @/* configured correctly"
    else
        echo "⚠️  Path alias @/* may not be configured correctly"
    fi
else
    echo "❌ tsconfig.json MISSING!"
fi

echo ""
echo "✅ Diagnostic complete!"

