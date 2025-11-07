#!/bin/bash

# CREATE A MINIMAL TEST PAGE TO ISOLATE THE ISSUE

echo "🧪 Creating minimal test page to isolate compilation issue..."
echo ""

cd "$(dirname "$0")"

# BACKUP ORIGINAL PAGE
if [ -f "src/app/page.tsx" ]; then
    echo "📦 Backing up original page.tsx..."
    cp src/app/page.tsx src/app/page.tsx.backup
    echo "✅ Backup created: src/app/page.tsx.backup"
fi

# CREATE MINIMAL PAGE
echo "📝 Creating minimal test page..."
cat > src/app/page.tsx << 'EOF'
export default function Home() {
  return (
    <div style={{ padding: '2rem', textAlign: 'center' }}>
      <h1>Test Page - If you see this, Next.js is working!</h1>
      <p>This is a minimal test page to verify compilation works.</p>
    </div>
  );
}
EOF

echo "✅ Minimal test page created"
echo ""
echo "🔄 Now try accessing http://localhost:3200"
echo ""
echo "If this works, the issue is with the original page.tsx"
echo "If this still 404s, the issue is with Next.js configuration"
echo ""
echo "To restore original page:"
echo "  mv src/app/page.tsx.backup src/app/page.tsx"

