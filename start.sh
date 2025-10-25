#!/bin/bash

# NavigateHome AI - Quick Start Script
echo "🚀 Starting NavigateHome AI..."

# Check if Python is available
if command -v python3 &> /dev/null; then
    echo "✅ Python3 found"
else
    echo "❌ Python3 not found. Please install Python3 first."
    exit 1
fi

# Navigate to project directory
cd "$(dirname "$0")"

# Start the server
echo "🌐 Starting web server on http://localhost:3000"
echo "📱 Open your browser and go to: http://localhost:3000/enhanced.html"
echo ""
echo "🎯 Features available:"
echo "   • Real-time dashboard with progress tracking"
echo "   • Working AI chatbot with voice input"
echo "   • Document upload and management"
echo "   • Multi-language translation (20+ languages)"
echo "   • Resource finder with real data"
echo "   • Rights protection and emergency features"
echo "   • Healthcare navigation"
echo "   • Profile management"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start the server
python3 -m http.server 3000
