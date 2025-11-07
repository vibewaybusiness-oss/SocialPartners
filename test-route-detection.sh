#!/bin/bash

echo "🔍 Testing Next.js Route Detection..."
echo "====================================="
echo ""

cd /root/SocialPartners

echo "1️⃣ Checking file structure..."
echo "   src/app/page.tsx exists: $([ -f src/app/page.tsx ] && echo 'YES' || echo 'NO')"
echo "   src/app/layout.tsx exists: $([ -f src/app/layout.tsx ] && echo 'YES' || echo 'NO')"
echo ""

echo "2️⃣ Checking file permissions..."
ls -la src/app/page.tsx 2>/dev/null | head -1
ls -la src/app/layout.tsx 2>/dev/null | head -1
echo ""

echo "3️⃣ Checking if Next.js can see the route..."
if [ -d ".next" ]; then
    echo "   .next directory exists"
    if [ -f ".next/server/app/page.js" ] || [ -f ".next/server/app/page.jsx" ]; then
        echo "   ✅ Root route compiled: .next/server/app/page.js"
    else
        echo "   ❌ Root route NOT compiled"
        echo "   Checking what routes ARE compiled:"
        find .next/server/app -name "page.js" -o -name "page.jsx" 2>/dev/null | head -10
    fi
else
    echo "   .next directory doesn't exist yet"
fi
echo ""

echo "4️⃣ Testing route compilation by accessing it..."
echo "   Making HTTP request to http://localhost:3200/ ..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://localhost:3200/ 2>/dev/null || echo "000")
echo "   HTTP Response: $HTTP_CODE"
echo ""

echo "5️⃣ Checking Next.js logs for compilation messages..."
if [ -f "/tmp/nextjs.log" ]; then
    echo "   Last 30 lines of log:"
    tail -30 /tmp/nextjs.log | grep -E "Compiling|Compiled|Error|error|GET" | tail -10
else
    echo "   Log file not found"
fi
echo ""

echo "6️⃣ Checking for TypeScript errors..."
if command -v npx >/dev/null 2>&1; then
    echo "   Running TypeScript check on page.tsx..."
    npx tsc --noEmit src/app/page.tsx 2>&1 | head -20
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "   ✅ No TypeScript errors"
    else
        echo "   ⚠️  TypeScript errors found"
    fi
fi

