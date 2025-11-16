#!/bin/bash

echo "🔧 Setting up all projects..."

# Shared types
echo "📦 Installing shared-types dependencies..."
cd ../shared-types
npm install
npm run build

# Backend
echo "🔧 Installing backend dependencies..."
cd ../repos/backend
npm install

# Frontend
echo "⚛️  Installing frontend dependencies..."
cd ../frontend
npm install

cd ../..

echo "✓ Setup complete!"
