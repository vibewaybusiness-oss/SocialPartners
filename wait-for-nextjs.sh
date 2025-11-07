#!/bin/bash

# WAIT FOR NEXTJS TO BE READY AND ROUTE COMPILED

echo "⏳ Waiting for Next.js to be ready..."

MAX_ATTEMPTS=30
ATTEMPT=0
PORT=3200

# WAIT FOR PORT TO BE LISTENING
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if ss -tuln 2>/dev/null | grep -q ":$PORT " || netstat -tuln 2>/dev/null | grep -q ":$PORT "; then
        echo "✅ Port $PORT is listening"
        break
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
        echo "❌ Timeout waiting for port $PORT"
        exit 1
    fi
    
    sleep 1
done

echo "🔥 Warming up homepage route..."

# TRIGGER HOMEPAGE COMPILATION
HTTP_CODE=0
WARMUP_ATTEMPTS=0
MAX_WARMUP_ATTEMPTS=10

while [ $WARMUP_ATTEMPTS -lt $MAX_WARMUP_ATTEMPTS ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/ 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Homepage is ready (HTTP $HTTP_CODE)"
        echo ""
        echo "🎉 Next.js is fully ready!"
        echo "📱 Access at: http://localhost:$PORT"
        exit 0
    fi
    
    WARMUP_ATTEMPTS=$((WARMUP_ATTEMPTS + 1))
    echo "   Attempt $WARMUP_ATTEMPTS/$MAX_WARMUP_ATTEMPTS - HTTP $HTTP_CODE (compiling...)"
    sleep 2
done

echo "⚠️  Homepage returned HTTP $HTTP_CODE after $MAX_WARMUP_ATTEMPTS attempts"
echo "   You may need to manually refresh the page"
echo "   or check for compilation errors in the Next.js logs"
exit 1

