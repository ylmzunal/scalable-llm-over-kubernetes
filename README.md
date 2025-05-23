# Scalable LLM Deployment on Kubernetes Infrastructure

## Master's Graduation Project

This project demonstrates how to deploy and scale Large Language Model (LLM) chatbots on Kubernetes infrastructure, with local development support and cloud deployment capabilities.

## 🏗️ Architecture Overview

- **Frontend**: React-based chat interface
- **Backend**: FastAPI with LLM integration
- **Infrastructure**: Kubernetes with horizontal auto-scaling
- **Deployment**: GitHub Actions CI/CD to Google Cloud
- **Local Development**: Minikube for local Kubernetes testing

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