#!/bin/bash

echo "🧪 Testing Route Compilation..."
echo "==============================="

cd "$(dirname "$0")"

echo ""
echo "1️⃣ Checking if Next.js can compile the route files..."
echo ""

# Try to build just to see if there are errors
echo "Attempting to build Next.js (this will show compilation errors)..."
echo "Press Ctrl+C after you see the errors (if any)"
echo ""

# Run next build but stop early
timeout 30 npm run build 2>&1 | head -100 || true

echo ""
echo "✅ Test complete"
echo ""
echo "If you saw compilation errors above, those are preventing routes from being registered"
echo "If the build started successfully, the issue might be something else"

