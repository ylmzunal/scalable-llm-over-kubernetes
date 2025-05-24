#!/bin/bash

# Test script for frontend Docker build
echo "🏗️  Testing Frontend Docker Build"
echo "================================="

# Change to frontend directory
cd frontend

# Build the Docker image
echo "📦 Building frontend Docker image..."
docker build -t llm-chatbot-frontend:test .

if [ $? -eq 0 ]; then
    echo "✅ Frontend Docker image built successfully"
    
    # Run the container for testing
    echo "🚀 Starting frontend container for testing..."
    docker run -d -p 3000:80 --name llm-chatbot-frontend-test llm-chatbot-frontend:test
    
    # Wait a moment for the container to start
    sleep 5
    
    # Test if the container is responding
    echo "🔍 Testing frontend health..."
    if curl -f http://localhost:3000/health > /dev/null 2>&1; then
        echo "✅ Frontend is responding to health checks"
        
        # Test if the main page loads
        echo "🔍 Testing main page..."
        if curl -f http://localhost:3000/ > /dev/null 2>&1; then
            echo "✅ Frontend main page is accessible"
            echo ""
            echo "🎉 Frontend Docker build test PASSED!"
            echo "   Frontend is running at: http://localhost:3000"
            echo ""
            echo "To stop the test container:"
            echo "   docker stop llm-chatbot-frontend-test"
            echo "   docker rm llm-chatbot-frontend-test"
        else
            echo "❌ Frontend main page is not accessible"
            docker logs llm-chatbot-frontend-test
        fi
    else
        echo "❌ Frontend health check failed"
        docker logs llm-chatbot-frontend-test
    fi
    
else
    echo "❌ Frontend Docker image build failed"
    exit 1
fi 