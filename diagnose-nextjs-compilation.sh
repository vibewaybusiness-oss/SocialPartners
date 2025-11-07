#!/bin/bash

echo "🔍 Diagnosing Next.js Compilation Issues..."
echo ""

cd "$(dirname "$0")"

# CHECK FOR MISSING UI COMPONENTS
echo "📦 Checking for required UI components..."

MISSING_COMPONENTS=0

check_component() {
    if [ ! -f "$1" ]; then
        echo "❌ Missing: $1"
        MISSING_COMPONENTS=$((MISSING_COMPONENTS + 1))
    else
        echo "✅ Found: $1"
    fi
}

check_component "src/components/ui/button.tsx"
check_component "src/components/ui/input.tsx"
check_component "src/components/ui/card.tsx"
check_component "src/components/ui/badge.tsx"
check_component "src/components/ui/toaster.tsx"
check_component "src/components/ui/dialog.tsx"
check_component "src/components/ui/sheet.tsx"

echo ""

# CHECK FOR MISSING COMMON COMPONENTS
echo "📦 Checking for required common components..."

check_component "src/components/common/video-theater.tsx"
check_component "src/components/common/email-subscription.tsx"
check_component "src/components/common/clipizy-logo.tsx"
check_component "src/components/seo/structured-data.tsx"
check_component "src/components/layout/navigation.tsx"
check_component "src/components/layout/footer.tsx"
check_component "src/components/layout/conditional-layout.tsx"

echo ""

# CHECK FOR MISSING CONTEXTS
echo "📦 Checking for required contexts..."

check_component "src/contexts/ThemeContext.tsx"
check_component "src/contexts/auth-context.tsx"
check_component "src/contexts/pricing-context.tsx"

echo ""

# CHECK FOR MISSING HOOKS
echo "📦 Checking for required hooks..."

check_component "src/hooks/users/use-email-subscription.ts"
check_component "src/hooks/ui/use-toast.ts"

echo ""

# CHECK FOR MISSING UTILS
echo "📦 Checking for required utilities..."

check_component "src/lib/utils.ts"
check_component "src/lib/config.ts"

echo ""

if [ $MISSING_COMPONENTS -gt 0 ]; then
    echo "❌ Found $MISSING_COMPONENTS missing components!"
    echo ""
    exit 1
fi

echo "✅ All required components found"
echo ""

# CHECK NODE MODULES
echo "📦 Checking node_modules..."

if [ ! -d "node_modules" ]; then
    echo "❌ node_modules directory is missing!"
    echo "   Run: npm install"
    exit 1
fi

if [ ! -d "node_modules/next" ]; then
    echo "❌ Next.js is not installed!"
    echo "   Run: npm install"
    exit 1
fi

echo "✅ node_modules exists"
echo ""

# CHECK TYPESCRIPT CONFIG
echo "📝 Checking TypeScript configuration..."

if [ ! -f "tsconfig.json" ]; then
    echo "❌ tsconfig.json is missing!"
    exit 1
fi

echo "✅ tsconfig.json exists"
echo ""

# TRY TO RUN TYPESCRIPT CHECK
echo "🔍 Running TypeScript type check..."

if command -v npx > /dev/null 2>&1; then
    echo "   This may take a moment..."
    npx tsc --noEmit 2>&1 | head -50
    TSC_EXIT=$?
    
    if [ $TSC_EXIT -eq 0 ]; then
        echo "✅ TypeScript check passed"
    else
        echo "⚠️  TypeScript check found errors (see above)"
        echo "   These may prevent compilation"
    fi
else
    echo "⚠️  npx not found, skipping TypeScript check"
fi

echo ""

# CHECK NEXT.JS BUILD MANIFEST
echo "📋 Checking Next.js build manifest..."

if [ -f ".next/BUILD_ID" ]; then
    echo "✅ Build ID exists"
    BUILD_ID=$(cat .next/BUILD_ID)
    echo "   Build ID: $BUILD_ID"
else
    echo "⚠️  No BUILD_ID found - Next.js may not have initialized"
fi

echo ""

# CHECK FOR COMPILATION ERRORS IN .NEXT
echo "🔍 Checking for compilation artifacts..."

if [ -d ".next/server/app" ]; then
    echo "✅ Server app directory exists"
    
    # List what's actually compiled
    echo ""
    echo "📁 Compiled routes:"
    find .next/server/app -type d -maxdepth 2 2>/dev/null | sed 's|.next/server/app||' | grep -v "^$" | sort
    
    # Check if page.js exists for root
    if [ -f ".next/server/app/page.js" ] || [ -f ".next/server/app/page_client-reference-manifest.js" ]; then
        echo ""
        echo "✅ Root page appears to be compiled"
    else
        echo ""
        echo "❌ Root page (/) is NOT compiled"
        echo "   This is why you're getting 404"
    fi
else
    echo "❌ Server app directory doesn't exist"
fi

echo ""

# CHECK NEXT.JS PROCESS LOGS
echo "📋 Next.js Process Information:"

if pgrep -f "next dev" > /dev/null 2>&1; then
    NEXTJS_PID=$(pgrep -f "next dev" | head -1)
    echo "✅ Next.js is running (PID: $NEXTJS_PID)"
    
    # Try to get process info
    if command -v ps > /dev/null 2>&1; then
        echo ""
        echo "Process details:"
        ps -p $NEXTJS_PID -o pid,cmd --no-headers 2>/dev/null || true
    fi
else
    echo "❌ Next.js is NOT running"
fi

echo ""
echo "💡 Next Steps:"
echo "   1. Check the terminal where you ran 'npm run dev' for errors"
echo "   2. Look for red error messages about missing imports or TypeScript errors"
echo "   3. Try manually compiling:"
echo "      rm -rf .next"
echo "      npm run dev"
echo "   4. Check browser console for runtime errors"
echo ""

