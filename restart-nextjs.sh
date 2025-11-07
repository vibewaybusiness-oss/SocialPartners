#!/bin/bash

echo "🔄 Restarting Next.js development server on port 3200..."
echo "======================================================"

cd "$(dirname "$0")"

PORT=3200

echo "🛑 Stopping existing Next.js server on port $PORT..."
lsof -ti:$PORT | xargs kill -9 2>/dev/null || true
pkill -f "next dev.*$PORT" 2>/dev/null || true
pkill -f "next dev.*-p $PORT" 2>/dev/null || true
sleep 2

echo "🧹 Clearing Next.js cache..."
rm -rf .next
rm -rf node_modules/.cache

echo "🚀 Starting Next.js development server on port $PORT..."
export PORT=$PORT
npm run dev

