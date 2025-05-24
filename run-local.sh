#!/bin/bash

# Local development setup script
echo "🚀 Starting Scalable LLM Chatbot - Local Development"

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama not found. Installing..."
    
    # Install Ollama on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        curl -fsSL https://ollama.com/install.sh | sh
    else
        echo "Please install Ollama from https://ollama.com/download"
        exit 1
    fi
fi

# Start Ollama in background
echo "🔄 Starting Ollama..."
ollama serve &
OLLAMA_PID=$!

# Wait for Ollama to start
sleep 5

# Download TinyLlama if not exists
echo "📦 Checking TinyLlama model..."
if ! ollama list | grep -q tinyllama; then
    echo "⬇️ Downloading TinyLlama model..."
    ollama pull tinyllama
fi

# Install Python dependencies
echo "🐍 Installing Python dependencies..."
pip install -r requirements.txt

# Set environment variables
export ENVIRONMENT=local
export PORT=8000
export LLM_MODEL_PROVIDER=ollama
export LLM_MODEL_NAME=tinyllama
export LLM_BASE_URL=http://localhost:11434

# Start backend
echo "🔧 Starting backend..."
cd app
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload &
BACKEND_PID=$!
cd ..

# Install and start frontend
echo "🎨 Starting frontend..."
cd frontend
if [ ! -d "node_modules" ]; then
    echo "📦 Installing Node.js dependencies..."
    npm install
fi

if [ ! -d "build" ]; then
    echo "🏗️ Building React app..."
    npm run build
fi

# Serve frontend
if command -v serve &> /dev/null; then
    serve -s build -l 3000 &
else
    echo "Installing serve globally..."
    npm install -g serve
    serve -s build -l 3000 &
fi
FRONTEND_PID=$!
cd ..

echo ""
echo "✅ Services started successfully!"
echo "🌐 Frontend: http://localhost:3000"
echo "🔧 Backend API: http://localhost:8000"
echo "🤖 Ollama: http://localhost:11434"
echo ""
echo "Press Ctrl+C to stop all services"

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping services..."
    kill $OLLAMA_PID $BACKEND_PID $FRONTEND_PID 2>/dev/null
    echo "✅ All services stopped"
    exit 0
}

# Trap Ctrl+C
trap cleanup SIGINT

# Wait for any process to exit
wait 