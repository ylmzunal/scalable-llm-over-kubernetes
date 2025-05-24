# Scalable LLM Chatbot - Complete Frontend + Backend Deployment

## Master's Graduation Project

This project demonstrates a **production-ready, scalable LLM chatbot** with complete frontend and backend deployment to Kubernetes. Users can access your chatbot with locally downloaded models through a public web interface.

## 🏗️ Architecture Overview

- **Frontend**: React + Material-UI served by nginx (publicly accessible)
- **Backend**: FastAPI + Ollama with your local models (internal service)
- **Models**: Your downloaded LLM models (Phi-2, Llama 2, DeepSeek Coder, etc.)
- **Infrastructure**: Kubernetes with auto-scaling for both frontend and backend
- **Deployment**: GitHub Actions CI/CD deploys both frontend and backend to GKE
- **Access**: Public internet access via LoadBalancer + optional SSL

## 📋 Prerequisites

- Docker Desktop
- Minikube
- kubectl
- Node.js (for frontend)
- Python 3.9+
- Google Cloud account (free tier)

## 🚀 Quick Start

### Local Development

1. **Start Minikube**
```bash
minikube start --driver=docker
```

2. **Build and Deploy Locally**
```bash
./scripts/deploy-local.sh
```

3. **Access the Application**
```bash
minikube service chatbot-frontend --url
```

### Cloud Deployment

1. **Setup Google Cloud**
```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

2. **Deploy via GitHub Actions**
- Push to main branch
- GitHub Actions will automatically deploy to GKE

## 📁 Project Structure

```
├── app/                    # Backend FastAPI application
├── frontend/              # React frontend
├── k8s/                   # Kubernetes manifests
├── .github/workflows/     # GitHub Actions
├── scripts/              # Deployment scripts
├── docs/                 # Documentation
└── tests/                # Test suites
```

## 🔧 Features

- **Scalable LLM Backend**: Auto-scaling based on CPU/memory usage
- **WebSocket Support**: Real-time chat interface
- **Health Monitoring**: Kubernetes health checks and monitoring
- **CI/CD Pipeline**: Automated testing and deployment
- **Resource Optimization**: Efficient resource allocation for free tier usage

## 📊 Monitoring & Scaling

- Horizontal Pod Autoscaler (HPA) for automatic scaling
- Resource quotas and limits
- Health checks and readiness probes
- Metrics collection with Prometheus (optional)

## 🌐 Deployment Environments

- **Local**: Minikube for development and testing
- **Staging**: Google Cloud Run (free tier)
- **Production**: Google Kubernetes Engine (GKE) with free tier optimization

## 📝 License

This project is created for educational purposes as part of a Master's graduation project. 