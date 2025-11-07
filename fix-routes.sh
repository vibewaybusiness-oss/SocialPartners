#!/bin/bash

echo "🔧 Fixing dashboard routes..."

cd "$(dirname "$0")"

echo "🗑️  Removing empty [[...slug]] directory..."
if [ -d "src/app/dashboard/[[...slug]]" ]; then
    rm -rf "src/app/dashboard/[[...slug]]"
    echo "✅ Removed [[...slug]] directory"
else
    echo "ℹ️  [[...slug]] directory not found"
fi

echo ""
echo "🧹 Clearing Next.js cache..."
rm -rf .next 2>/dev/null || true
echo "✅ Next.js cache cleared"

echo ""
echo "📋 Current dashboard structure:"
ls -la src/app/dashboard/ 2>/dev/null | head -20 || echo "  (check manually)"

echo ""
echo "✅ Route fix complete!"
echo ""
echo "Next steps:"
echo "  1. Restart your Next.js dev server"
echo "  2. Try accessing /dashboard"
echo "  3. /dashboard/create should redirect to /dashboard"

