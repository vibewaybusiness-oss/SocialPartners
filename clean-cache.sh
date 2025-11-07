#!/bin/bash

echo "🧹 Cleaning all cache files..."
echo "================================"

# Python cache
echo "📦 Removing Python cache files..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
find . -type f -name "*.pyo" -delete 2>/dev/null || true
find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true

# Next.js cache
echo "⚛️  Removing Next.js cache..."
rm -rf .next 2>/dev/null || true
rm -rf .turbo 2>/dev/null || true
rm -rf .swc 2>/dev/null || true

# Node.js cache
echo "📦 Removing Node.js cache..."
rm -rf node_modules/.cache 2>/dev/null || true

# Test coverage
echo "🧪 Removing test coverage files..."
find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name ".coverage" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name ".coverage.*" -delete 2>/dev/null || true
find . -type d -name "htmlcov" -exec rm -rf {} + 2>/dev/null || true

# Build artifacts
echo "🔨 Removing build artifacts..."
find . -type d -name "dist" -not -path "./node_modules/*" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "build" -not -path "./node_modules/*" -exec rm -rf {} + 2>/dev/null || true

echo ""
echo "✅ Cache cleanup complete!"
echo "================================"
echo "Removed:"
echo "  - Python __pycache__ directories"
echo "  - Python .pyc and .pyo files"
echo "  - Next.js .next directory"
echo "  - Node.js cache directories"
echo "  - Test coverage files"
echo "  - Build artifacts"

