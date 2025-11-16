#!/bin/bash

echo "🧪 Running tests..."

# Backend tests
echo "Testing backend..."
cd ../repos/backend
npm test

# Frontend tests (if configured)
echo "Testing frontend..."
cd ../frontend
npm test

cd ../..

echo "✓ Tests complete!"
