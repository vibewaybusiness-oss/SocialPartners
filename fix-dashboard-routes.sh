#!/bin/bash

echo "🔧 Fixing dashboard routes..."

cd "$(dirname "$0")"

if [ -d "src/app/dashboard/[[...slug]]" ]; then
    echo "🗑️  Removing optional catch-all route [[...slug]]..."
    rm -rf "src/app/dashboard/[[...slug]]"
    echo "✅ Removed [[...slug]] directory"
fi

if [ -d "src/app/dashboard/[...slug]" ]; then
    echo "✅ Required catch-all route [...slug] exists"
else
    echo "⚠️  Warning: [...slug] directory not found"
fi

echo ""
echo "📋 Current dashboard structure:"
ls -la src/app/dashboard/ | grep -E "slug|page.tsx|layout.tsx" || echo "  (check manually)"

echo ""
echo "✅ Dashboard route fix complete!"
echo ""
echo "The issue was:"
echo "  - [[...slug]] (optional catch-all) matches /dashboard itself"
echo "  - [...slug] (required catch-all) only matches /dashboard/*"
echo ""
echo "Now /dashboard should work, and /dashboard/create will redirect to /dashboard"

