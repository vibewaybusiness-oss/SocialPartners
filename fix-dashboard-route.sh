#!/bin/bash

echo "🔧 Fixing dashboard route issues..."
echo "===================================="

cd "$(dirname "$0")"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. Remove the empty [[...slug]] directory if it exists
echo -e "${BLUE}📁 Step 1: Removing empty catch-all directory...${NC}"
if [ -d "src/app/dashboard/[[...slug]]" ]; then
    rm -rf "src/app/dashboard/[[...slug]]"
    echo -e "${GREEN}✅ Removed [[...slug]] directory${NC}"
else
    echo -e "${GREEN}✅ [[...slug]] directory not found (already removed)${NC}"
fi

# 2. Verify the required catch-all exists
echo -e "${BLUE}📁 Step 2: Verifying catch-all route...${NC}"
if [ -f "src/app/dashboard/[...slug]/page.tsx" ]; then
    echo -e "${GREEN}✅ Required catch-all route [...slug] exists${NC}"
else
    echo -e "${RED}❌ Required catch-all route [...slug] is missing!${NC}"
fi

# 3. Verify the main dashboard page exists
echo -e "${BLUE}📁 Step 3: Verifying main dashboard page...${NC}"
if [ -f "src/app/dashboard/page.tsx" ]; then
    echo -e "${GREEN}✅ Main dashboard page exists${NC}"
else
    echo -e "${RED}❌ Main dashboard page is missing!${NC}"
fi

# 4. Clear Next.js cache
echo -e "${BLUE}🧹 Step 4: Clearing Next.js cache...${NC}"
rm -rf .next 2>/dev/null || true
rm -rf .turbo 2>/dev/null || true
rm -rf node_modules/.cache 2>/dev/null || true
echo -e "${GREEN}✅ Next.js cache cleared${NC}"

# 5. Show current structure
echo -e "${BLUE}📋 Step 5: Current dashboard structure:${NC}"
echo ""
ls -la src/app/dashboard/ 2>/dev/null | grep -E "^d|^-" | awk '{print $9}' | grep -v "^\.$" | grep -v "^\.\.$" | while read item; do
    if [ -n "$item" ]; then
        if [ -d "src/app/dashboard/$item" ]; then
            echo -e "  📁 $item/"
        elif [ -f "src/app/dashboard/$item" ]; then
            echo -e "  📄 $item"
        fi
    fi
done

echo ""
echo -e "${GREEN}✅ Route fix complete!${NC}"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo -e "${YELLOW}   1. Stop your Next.js dev server (Ctrl+C)${NC}"
echo -e "${YELLOW}   2. Restart with: ./app.sh${NC}"
echo -e "${YELLOW}   3. Try accessing: http://localhost:3200/dashboard${NC}"
echo ""
echo -e "${BLUE}Expected behavior:${NC}"
echo -e "  ✅ /dashboard → Should work (main dashboard page)"
echo -e "  ✅ /dashboard/create → Should redirect to /dashboard"
echo -e "  ✅ /dashboard/messaging → Should work"
echo -e "  ✅ /dashboard/collaborators → Should work"
echo ""

