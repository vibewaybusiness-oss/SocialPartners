#!/bin/bash

echo "🔧 Force Fixing Root Route Detection..."
echo "======================================="
echo ""

cd /root/SocialPartners

echo "1️⃣ Stopping Next.js..."
lsof -ti:3200 | xargs kill -9 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
sleep 2

echo "2️⃣ Clearing cache..."
rm -rf .next .turbo .swc node_modules/.cache node_modules/.next
echo "✅ Cache cleared"

echo ""
echo "3️⃣ Verifying route file structure..."
if [ ! -f "src/app/page.tsx" ]; then
    echo "❌ ERROR: src/app/page.tsx missing!"
    exit 1
fi

# Check if there's a conflicting app directory
if [ -d "app" ] && [ ! -d "src/app" ]; then
    echo "⚠️  Found 'app' directory - Next.js will use this instead of 'src/app'"
fi

echo "✅ Route files verified"
echo ""

echo "4️⃣ Creating a minimal test to verify Next.js can see routes..."
# Create a simple test route to see if Next.js detects it
mkdir -p src/app/test
cat > src/app/test/page.tsx << 'EOF'
export default function TestPage() {
  return <div>Test Route Works!</div>;
}
EOF
echo "✅ Created test route at src/app/test/page.tsx"
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
    echo "7️⃣ Testing routes..."
    echo "   Testing root route: http://localhost:3200/"
    sleep 2
    HTTP_ROOT=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:3200/ 2>/dev/null || echo "000")
    echo "   Root route response: $HTTP_ROOT"
    
    echo ""
    echo "   Testing test route: http://localhost:3200/test"
    sleep 2
    HTTP_TEST=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:3200/test 2>/dev/null || echo "000")
    echo "   Test route response: $HTTP_TEST"
    echo ""
    
    if [ "$HTTP_TEST" = "200" ]; then
        echo "✅ Test route works! Next.js CAN detect routes."
        echo "   The issue is specific to the root route."
        echo ""
        echo "💡 Possible causes:"
        echo "   1. Import error in src/app/page.tsx"
        echo "   2. Client component issue"
        echo "   3. File system detection issue"
        echo ""
        echo "   Check logs: tail -f /tmp/nextjs.log"
        echo "   Look for 'Compiling /' or 'Error compiling /'"
    else
        echo "⚠️  Test route also failed - Next.js may have route detection issues"
    fi
    
    echo ""
    echo "📋 Recent compilation messages:"
    tail -30 /tmp/nextjs.log | grep -E "Compiling|Compiled|Error|GET" | tail -10
else
    echo "⚠️  Next.js may still be starting..."
    echo "   Check logs: tail -f /tmp/nextjs.log"
fi

echo ""
echo "🌐 Access these URLs:"
echo "   Root: http://localhost:3200/"
echo "   Test: http://localhost:3200/test"
echo ""
echo "💡 If root route still doesn't work, check for compilation errors in the logs"

