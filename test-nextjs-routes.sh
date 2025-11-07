#!/bin/bash

echo "🧪 Testing Next.js Routes..."
echo "============================"

PORT=3200
BASE_URL="http://localhost:$PORT"

echo ""
echo "⏳ Waiting for Next.js to be ready..."
sleep 3

echo ""
echo "🔍 Testing routes..."
echo ""

test_route() {
    local route=$1
    local name=$2
    echo -n "Testing $name ($route)... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$route" 2>/dev/null)
    
    if [ "$response" = "200" ]; then
        echo "✅ OK (200)"
        return 0
    elif [ "$response" = "404" ]; then
        echo "❌ Not Found (404)"
        return 1
    elif [ "$response" = "000" ]; then
        echo "⚠️  Server not responding"
        return 1
    else
        echo "⚠️  Unexpected status: $response"
        return 1
    fi
}

test_route "/" "Homepage"
test_route "/dashboard" "Dashboard"
test_route "/auth/login" "Login"
test_route "/pricing" "Pricing"

echo ""
echo "📋 Next.js compilation status:"
if [ -f "/tmp/nextjs.log" ]; then
    echo "Recent log entries:"
    tail -n 10 /tmp/nextjs.log | grep -E "Compiling|Compiled|Error|error" || echo "No compilation messages found"
else
    echo "Log file not found at /tmp/nextjs.log"
fi

echo ""
echo "✅ Route test complete!"

