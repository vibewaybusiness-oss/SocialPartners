#!/bin/bash

echo "🔍 Debugging Next.js Route Issue..."
echo "===================================="

echo ""
echo "1️⃣ Checking what Next.js compiles when accessing /..."
echo "   (This will show in the terminal when you access http://localhost:3200/)"
echo ""
echo "2️⃣ Current .next directory structure:"
if [ -d ".next/server/app" ]; then
    echo "✅ .next/server/app exists"
    echo ""
    echo "Compiled routes:"
    find .next/server/app -type f -name "*.js" | grep -E "page|layout" | head -10
    echo ""
    echo "Checking for root route:"
    if [ -f ".next/server/app/page.js" ] || [ -f ".next/server/app/page.jsx" ]; then
        echo "✅ Root page.js found"
    else
        echo "❌ Root page.js NOT found - route hasn't compiled"
    fi
else
    echo "❌ .next/server/app doesn't exist"
    echo "   Routes haven't been compiled yet"
fi

echo ""
echo "3️⃣ Checking Next.js logs for compilation messages..."
if [ -f "/tmp/nextjs.log" ]; then
    echo "Recent compilation messages:"
    tail -100 /tmp/nextjs.log | grep -E "Compiling|Compiled|Error|error" | tail -20
else
    echo "⚠️  Log file not found"
fi

echo ""
echo "4️⃣ Testing route access..."
echo "   When you access http://localhost:3200/, you should see:"
echo "   - '○ Compiling / ...' (route found)"
echo "   - OR '○ Compiling /_not-found ...' (route NOT found)"
echo ""
echo "   Watch the terminal where Next.js is running for these messages"

echo ""
echo "5️⃣ Checking for TypeScript errors that might prevent compilation..."
if command -v npx >/dev/null 2>&1; then
    echo "Running TypeScript check on route files..."
    npx tsc --noEmit src/app/page.tsx src/app/layout.tsx 2>&1 | head -20
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "✅ No TypeScript errors in route files"
    else
        echo "⚠️  TypeScript errors found (may prevent route compilation)"
    fi
fi

echo ""
echo "✅ Debug complete!"
echo ""
echo "💡 Next steps:"
echo "   1. Access http://localhost:3200/ in your browser"
echo "   2. Watch the terminal for 'Compiling' messages"
echo "   3. If you see 'Compiling /_not-found', Next.js isn't finding your routes"
echo "   4. If you see 'Compiling /', wait for it to finish (may take 5-10 seconds)"
echo "   5. Share the compilation messages you see"

