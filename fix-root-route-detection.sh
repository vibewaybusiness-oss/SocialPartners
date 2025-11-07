#!/bin/bash

echo "🔧 Fixing Root Route Detection Issue..."
echo "========================================"
echo ""

cd /root/SocialPartners

echo "1️⃣ Stopping Next.js..."
lsof -ti:3200 | xargs kill -9 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
sleep 2

echo "2️⃣ Checking for actual errors in page.tsx (not Next.js types)..."
# Check for syntax errors in the actual file
if command -v node >/dev/null 2>&1; then
    # Try to parse the file for basic syntax errors
    echo "   Checking file syntax..."
    node --check src/app/page.tsx 2>&1 | grep -v "node_modules" | head -10 || echo "   ✅ No syntax errors detected"
fi

echo ""
echo "3️⃣ Creating a backup and testing with minimal page..."
cp src/app/page.tsx src/app/page.tsx.backup

# Create a minimal version to test
cat > src/app/page.tsx << 'EOF'
"use client";

export default function Home() {
  return (
    <div style={{ padding: '2rem', textAlign: 'center' }}>
      <h1>Root Route Test</h1>
      <p>If you see this, the root route is working!</p>
    </div>
  );
}
EOF

echo "✅ Created minimal test page"
echo ""

echo "4️⃣ Clearing cache..."
rm -rf .next .turbo .swc node_modules/.cache node_modules/.next
echo "✅ Cache cleared"

echo ""
echo "5️⃣ Starting Next.js..."
export PORT=3200
export BACKEND_URL="http://localhost:8200"
export FRONTEND_URL="http://localhost:3200"
export NODE_OPTIONS="--max-old-space-size=4096"
export NEXT_TELEMETRY_DISABLED=1

nohup npm run dev > /tmp/nextjs.log 2>&1 &
NEXTJS_PID=$!

echo "✅ Next.js started (PID: $NEXTJS_PID)"
echo "📋 View logs: tail -f /tmp/nextjs.log"
echo ""

echo "6️⃣ Waiting for Next.js to be ready..."
sleep 8

if tail -n 50 /tmp/nextjs.log 2>/dev/null | grep -qi "Ready"; then
    echo "✅ Next.js is ready!"
    echo ""
    echo "7️⃣ Testing root route..."
    echo "   Accessing http://localhost:3200/ ..."
    sleep 3
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://localhost:3200/ 2>/dev/null || echo "000")
    echo "   HTTP Response: $HTTP_CODE"
    echo ""
    
    echo "📋 Checking compilation logs..."
    tail -50 /tmp/nextjs.log | grep -E "Compiling|Compiled|Error|GET /" | tail -15
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo ""
        echo "✅ SUCCESS! Root route is working with minimal page!"
        echo ""
        echo "💡 This means the issue is in the original page.tsx file"
        echo "   (likely an import or component error)"
        echo ""
        echo "   Restoring backup and checking for problematic imports..."
        mv src/app/page.tsx.backup src/app/page.tsx
        
        echo ""
        echo "   Next steps:"
        echo "   1. Check the logs for compilation errors: tail -f /tmp/nextjs.log"
        echo "   2. Look for 'Error compiling /' messages"
        echo "   3. Try commenting out imports one by one to find the problematic one"
    else
        echo ""
        echo "❌ Root route still not working even with minimal page"
        echo "   This suggests a Next.js configuration or file system issue"
        echo ""
        echo "   Restoring backup..."
        mv src/app/page.tsx.backup src/app/page.tsx
    fi
else
    echo "⚠️  Next.js may still be starting..."
    echo "   Check logs: tail -f /tmp/nextjs.log"
    echo ""
    echo "   Restoring backup..."
    mv src/app/page.tsx.backup src/app/page.tsx
fi

echo ""
echo "🌐 Test URL: http://localhost:3200/"
echo "📋 View logs: tail -f /tmp/nextjs.log"

