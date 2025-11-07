#!/bin/bash

echo "🔍 Diagnosing Next.js Route Issues..."
echo "======================================"

cd "$(dirname "$0")"

echo ""
echo "1️⃣ Checking Next.js version..."
if command -v npx >/dev/null 2>&1; then
    npx next --version
else
    echo "❌ npx not found"
fi

echo ""
echo "2️⃣ Checking app directory structure..."
if [ -d "src/app" ]; then
    echo "✅ src/app exists"
    echo "Route files found:"
    find src/app -name "page.tsx" -o -name "page.ts" | head -10
else
    echo "❌ src/app not found!"
    if [ -d "app" ]; then
        echo "⚠️  Found 'app' directory instead of 'src/app'"
        echo "   Next.js will look for src/app or app"
    fi
fi

echo ""
echo "3️⃣ Checking for TypeScript errors in route files..."
if command -v npx >/dev/null 2>&1; then
    echo "Checking src/app/page.tsx..."
    npx tsc --noEmit src/app/page.tsx 2>&1 | head -10 || echo "No errors in page.tsx"
    
    echo ""
    echo "Checking src/app/layout.tsx..."
    npx tsc --noEmit src/app/layout.tsx 2>&1 | head -10 || echo "No errors in layout.tsx"
fi

echo ""
echo "4️⃣ Checking Next.js configuration..."
if [ -f "next.config.ts" ]; then
    echo "✅ next.config.ts exists"
    if grep -q "basePath\|trailingSlash" next.config.ts; then
        echo "⚠️  Found basePath or trailingSlash config (may affect routing)"
        grep "basePath\|trailingSlash" next.config.ts
    else
        echo "✅ No basePath/trailingSlash config found"
    fi
else
    echo "❌ next.config.ts not found"
fi

echo ""
echo "5️⃣ Checking if .next directory exists and structure..."
if [ -d ".next" ]; then
    echo "✅ .next directory exists"
    if [ -d ".next/server/app" ]; then
        echo "✅ .next/server/app exists"
        echo "Compiled routes found:"
        find .next/server/app -name "page.js" -o -name "page.jsx" 2>/dev/null | head -10
    else
        echo "⚠️  .next/server/app not found (routes not compiled)"
    fi
else
    echo "⚠️  .next directory doesn't exist (will be created on first build)"
fi

echo ""
echo "6️⃣ Testing route file syntax..."
if [ -f "src/app/page.tsx" ]; then
    if grep -q "export default" src/app/page.tsx; then
        echo "✅ src/app/page.tsx has default export"
        EXPORT_LINE=$(grep -n "export default" src/app/page.tsx | head -1)
        echo "   Found at line: $EXPORT_LINE"
    else
        echo "❌ src/app/page.tsx missing default export!"
    fi
fi

echo ""
echo "7️⃣ Checking for conflicting files..."
if [ -f "app/page.tsx" ]; then
    echo "⚠️  Found app/page.tsx (conflicts with src/app/page.tsx)"
    echo "   Next.js will use app/ if both exist"
fi

if [ -f "pages/index.tsx" ] || [ -f "pages/index.js" ]; then
    echo "⚠️  Found pages directory (Pages Router)"
    echo "   This conflicts with App Router - Next.js will use App Router if src/app exists"
fi

echo ""
echo "✅ Diagnosis complete!"
echo ""
echo "💡 Next steps:"
echo "   1. If routes aren't compiling, try: ./force-rebuild-nextjs.sh"
echo "   2. Check Next.js logs: tail -f /tmp/nextjs.log"
echo "   3. Verify server is running: curl http://localhost:3200/"

