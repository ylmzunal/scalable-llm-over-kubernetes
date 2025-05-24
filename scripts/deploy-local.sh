#!/bin/bash

# Scalable LLM Chatbot - Local Deployment Script
# For MacBook Pro M3 with Minikube

set -e

echo "🚀 Starting Local Deployment to Minikube..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if minikube is running
print_status "Checking Minikube status..."
if ! minikube status | grep -q "host: Running"; then
    print_warning "Minikube is not running. Starting Minikube..."
    minikube start --driver=docker --memory=4096 --cpus=2
    print_success "Minikube started successfully"
else
    print_success "Minikube is already running"
fi

# Configure Docker to use Minikube's Docker daemon
print_status "Configuring Docker environment for Minikube..."
eval $(minikube docker-env)

# Build the backend Docker image
print_status "Building backend Docker image..."
docker build -t llm-chatbot-backend:latest .
print_success "Backend image built successfully"

# Apply Kubernetes manifests
print_status "Applying Kubernetes manifests..."

# Apply in order - using local configurations
kubectl apply -f k8s/rbac.yaml
kubectl apply -f k8s/configmap-local.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/backend-deployment.yaml

# Wait for deployments to be ready
print_status "Waiting for deployment to be ready..."
kubectl rollout status deployment/llm-chatbot-backend --timeout=300s

# Apply HPA (after deployment is ready)
print_status "Applying Horizontal Pod Autoscaler..."
kubectl apply -f k8s/hpa.yaml

print_success "All Kubernetes resources applied successfully"

# Create secrets if they don't exist
if ! kubectl get secret llm-chatbot-secrets &> /dev/null; then
    print_status "Creating secrets..."
    kubectl create secret generic llm-chatbot-secrets \
        --from-literal=openai_api_key="" \
        --dry-run=client -o yaml | kubectl apply -f -
    print_success "Secrets created"
fi

# Get service information
print_status "Getting service information..."
kubectl get pods,services,hpa -l app=llm-chatbot

# Set up port forwarding
print_status "Setting up port forwarding..."
print_warning "Starting port forwarding in background. Use 'pkill -f kubectl.*port-forward' to stop."

# Kill any existing port forwards
pkill -f "kubectl.*port-forward" || true
sleep 2

# Start port forwarding for backend
kubectl port-forward service/llm-chatbot-backend-service 8000:80 &
PORT_FORWARD_PID=$!

# Wait a moment for port forward to establish
sleep 5

# Test the backend
print_status "Testing backend connection..."
if curl -s http://localhost:8000/health > /dev/null; then
    print_success "Backend is responding at http://localhost:8000"
    print_success "API Documentation available at http://localhost:8000/docs"
    print_success "Health endpoint: http://localhost:8000/health"
    print_success "Metrics endpoint: http://localhost:8000/metrics"
    print_success "Stats endpoint: http://localhost:8000/stats"
else
    print_error "Backend is not responding. Check the logs:"
    echo "kubectl logs -l app=llm-chatbot,component=backend"
fi

echo ""
print_success "=== Deployment Complete ==="
echo ""
print_status "Backend API: http://localhost:8000"
print_status "API Docs: http://localhost:8000/docs"
echo ""
print_status "To view logs: kubectl logs -f -l app=llm-chatbot"
print_status "To scale manually: kubectl scale deployment llm-chatbot-backend --replicas=3"
print_status "To stop port forwarding: pkill -f 'kubectl.*port-forward'"
echo ""
print_status "Next steps:"
echo "1. Open frontend/package.json and run 'npm install && npm start'"
echo "2. Test the chat interface at http://localhost:3000"
echo "3. Monitor scaling with: kubectl get hpa -w"
echo ""

# Keep the script running to maintain port forwarding
if [ "$1" != "--no-wait" ]; then
    print_status "Port forwarding is active. Press Ctrl+C to stop..."
    wait $PORT_FORWARD_PID
fi 