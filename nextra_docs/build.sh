#!/bin/bash
set -e

echo "🚀 Building Nextra documentation..."
cd nextra_docs

echo "📦 Installing dependencies..."
npm ci

echo "🏗️ Building site..."
npm run build

echo "📁 Listing output directory..."
ls -la out/

echo "✅ Build completed successfully!"
