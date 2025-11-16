#!/bin/bash

# Start all development servers

echo "🚀 Starting development servers..."

# Start shared types watch
echo "📦 Starting shared-types watch..."
cd ../shared-types
npm run dev &
TYPES_PID=$!

# Start backend
echo "🔧 Starting backend server..."
cd ../repos/backend
npm run dev &
BACKEND_PID=$!

# Start frontend
echo "⚛️  Starting frontend server..."
cd ../frontend
npm run dev &
FRONTEND_PID=$!

cd ../..

echo ""
echo "✓ All servers started!"
echo ""
echo "📦 Shared Types: watching for changes"
echo "🔧 Backend: http://localhost:3000"
echo "⚛️  Frontend: http://localhost:3001"
echo ""
echo "Press Ctrl+C to stop all servers"

# Wait for Ctrl+C
trap "kill $TYPES_PID $BACKEND_PID $FRONTEND_PID; exit" INT
wait
