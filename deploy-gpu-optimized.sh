#!/bin/bash

echo "🚀 Deploying Scalable LLM Chatbot - M3 GPU Optimized"

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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
if ! minikube status | grep -q "Running"; then
    print_status "Starting minikube..."
    minikube start --memory=4096 --cpus=4
fi

# Check if Ollama is running natively
print_status "Checking native Ollama service..."
if ! pgrep -f "ollama serve" > /dev/null; then
    print_warning "Ollama not running natively. Starting in background..."
    ollama serve &
    sleep 5
fi

# Download optimized models for M3
print_status "Downloading GPU-optimized models..."
if ! ollama list | grep -q "phi3:mini"; then
    print_status "Downloading Phi-3 Mini (3.8B, Apple Silicon optimized)..."
    ollama pull phi3:mini
fi

if ! ollama list | grep -q "llama3.2:1b"; then
    print_status "Downloading Llama 3.2 1B (fast inference)..."
    ollama pull llama3.2:1b
fi

# Build Docker images
print_status "Building Docker images..."
eval $(minikube docker-env)

print_status "Building backend image..."
docker build -t llm-chatbot-backend:local .

print_status "Building frontend image..."
docker build -t llm-chatbot-frontend:local -f frontend/Dockerfile frontend/

# Enable minikube host.minikube.internal access
print_status "Configuring minikube for host access..."
minikube ssh -- sudo ip route add $(route -n get default | grep gateway | awk '{print $2}')/32 dev eth0

# Deploy to Kubernetes
print_status "Deploying backend to Kubernetes..."
kubectl apply -f k8s/backend-deployment-gpu-optimized.yaml

print_status "Deploying frontend to Kubernetes..."
kubectl apply -f k8s/frontend-deployment-gpu-optimized.yaml

# Wait for deployments
print_status "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/llm-chatbot-backend-gpu -n llm-gpu-cluster
kubectl wait --for=condition=available --timeout=300s deployment/llm-chatbot-frontend-gpu -n llm-gpu-cluster

# Get service information
print_success "🎉 GPU-optimized deployment complete!"
echo ""
echo "📊 M3 GPU Optimization Details:"
echo "  • Native Ollama: Running on M3 GPU/Neural Engine"
echo "  • Model: Phi-3 Mini (3.8B parameters)"
echo "  • Memory: Optimized for Apple Silicon"
echo "  • Inference: Hardware-accelerated via Metal"
echo ""

# Show access information
FRONTEND_URL=$(minikube service llm-chatbot-frontend-service-gpu -n llm-gpu-cluster --url)
BACKEND_URL=$(minikube service llm-chatbot-backend-service-gpu -n llm-gpu-cluster --url)

echo "🌐 Access URLs:"
echo "  Frontend: $FRONTEND_URL"
echo "  Backend API: $BACKEND_URL"
echo ""

echo "🔧 Alternative Access (if URLs don't work):"
echo "  kubectl port-forward -n llm-gpu-cluster service/llm-chatbot-frontend-service-gpu 8080:80"
echo "  Then visit: http://localhost:8080"
echo ""

echo "📱 Quick Status Check:"
kubectl get pods -n llm-gpu-cluster
echo ""

echo "💡 GPU Performance Tips:"
echo "  • Ollama automatically uses M3 GPU/Neural Engine"
echo "  • Monitor with: ollama ps"
echo "  • Check GPU usage: sudo powermetrics --samplers gpu_power -n 1"
echo ""

print_success "Ready for GPU-accelerated LLM inference! 🚀" 