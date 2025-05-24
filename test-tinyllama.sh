#!/bin/bash

echo "🔍 Testing TinyLlama Deployment"
echo "================================"

# Check pod status
echo "📊 Pod Status:"
kubectl get pods -n llm-tinyllama-cluster

echo ""
echo "🌐 Getting Service URLs:"

# Get service URLs
FRONTEND_URL=$(minikube service llm-chatbot-frontend-service-tinyllama -n llm-tinyllama-cluster --url 2>/dev/null)
BACKEND_URL=$(minikube service llm-chatbot-backend-service-tinyllama -n llm-tinyllama-cluster --url 2>/dev/null)

echo "Frontend: $FRONTEND_URL"
echo "Backend: $BACKEND_URL"

echo ""
echo "🧪 Testing Backend Health:"
timeout 5 curl -s $BACKEND_URL/health || echo "❌ Health check failed or timed out"

echo ""
echo "🎯 Quick TinyLlama Test:"
echo "Testing with simple message..."
timeout 15 curl -s -X POST $BACKEND_URL/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hi!"}' || echo "❌ Chat test failed or timed out"

echo ""
echo "📱 Access URLs:"
echo "  Frontend: $FRONTEND_URL"
echo "  Backend:  $BACKEND_URL"
echo ""
echo "💡 Try opening the frontend URL in your browser!" 