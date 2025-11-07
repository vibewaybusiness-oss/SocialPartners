#!/bin/bash

echo "🔍 Deep Diagnosis of Root Route Issue..."
echo "========================================="
echo ""

cd /root/SocialPartners

echo "1️⃣ Checking for conflicting app directories..."
if [ -d "app" ] && [ ! -d "src/app" ]; then
    echo "   ⚠️  Found 'app' directory (Next.js will use this, not 'src/app')"
elif [ -d "app" ] && [ -d "src/app" ]; then
    echo "   ⚠️  Found BOTH 'app' and 'src/app' - Next.js will use 'app' first!"
    echo "   This is likely the problem!"
elif [ -d "src/app" ]; then
    echo "   ✅ Only 'src/app' exists (correct)"
fi
echo ""

echo "2️⃣ Checking file system and permissions..."
if [ -f "src/app/page.tsx" ]; then
    echo "   ✅ src/app/page.tsx exists"
    ls -la src/app/page.tsx
    echo ""
    echo "   File size: $(wc -c < src/app/page.tsx) bytes"
    echo "   First 100 characters:"
    head -c 100 src/app/page.tsx
    echo ""
    echo ""
else
    echo "   ❌ src/app/page.tsx NOT FOUND!"
fi
echo ""

echo "3️⃣ Checking Next.js version and configuration..."
if command -v npx >/dev/null 2>&1; then
    NEXT_VERSION=$(npx next --version 2>/dev/null || echo "unknown")
    echo "   Next.js version: $NEXT_VERSION"
fi
echo ""

echo "4️⃣ Checking if there's a pages directory (conflicts with app router)..."
if [ -d "pages" ]; then
    echo "   ⚠️  Found 'pages' directory - this can conflict with App Router!"
    echo "   Next.js will prioritize App Router if both exist, but this can cause issues"
    ls -la pages/ | head -10
else
    echo "   ✅ No 'pages' directory (good)"
fi
echo ""

echo "5️⃣ Checking tsconfig.json for srcDir configuration..."
if [ -f "tsconfig.json" ]; then
    if grep -q "srcDir\|appDir" tsconfig.json; then
        echo "   Found srcDir/appDir config:"
        grep "srcDir\|appDir" tsconfig.json
    else
        echo "   ✅ No srcDir/appDir override (Next.js will use default: src/app)"
    fi
fi
echo ""

echo "6️⃣ Testing if Next.js can actually read the file..."
if [ -f "src/app/page.tsx" ]; then
    # Try to see what Next.js would see
    echo "   Checking file encoding..."
    file src/app/page.tsx
    echo ""
    echo "   Checking for BOM or special characters..."
    if head -c 3 src/app/page.tsx | od -An -tx1 | grep -q "ef bb bf"; then
        echo "   ⚠️  File has UTF-8 BOM (Byte Order Mark) - this can cause issues!"
    else
        echo "   ✅ No BOM detected"
    fi
fi
echo ""

echo "7️⃣ Checking .next directory structure..."
if [ -d ".next/server/app" ]; then
    echo "   ✅ .next/server/app exists"
    echo "   Routes found in .next/server/app:"
    find .next/server/app -name "page.js" -o -name "page.jsx" 2>/dev/null | head -10
    echo ""
    echo "   Checking if root route is there:"
    if [ -f ".next/server/app/page.js" ] || [ -f ".next/server/app/page.jsx" ]; then
        echo "   ✅ Root route compiled!"
    else
        echo "   ❌ Root route NOT compiled"
        echo "   Checking what IS compiled:"
        ls -la .next/server/app/ 2>/dev/null | head -10
    fi
else
    echo "   ⚠️  .next/server/app doesn't exist (routes haven't been compiled)"
fi
echo ""

echo "8️⃣ Recommendation..."
if [ -d "app" ] && [ -d "src/app" ]; then
    echo "   🔧 FIX: Remove or rename the 'app' directory:"
    echo "      mv app app.backup"
    echo "      Then restart Next.js"
elif [ ! -f "src/app/page.tsx" ]; then
    echo "   🔧 FIX: Create src/app/page.tsx"
else
    echo "   🔧 Try: Clear cache and rebuild"
    echo "      rm -rf .next"
    echo "      npm run dev"
fi

