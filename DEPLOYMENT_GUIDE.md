# 🚀 Deployment Guide: Scalable LLM Chatbot

This guide explains how to deploy the LLM chatbot both locally and on Google Cloud.

## 📋 Overview

- **Local Development**: Uses Ollama with 6 LLM models for privacy and full functionality
- **Cloud Deployment**: Uses Hugging Face models via Google Kubernetes Engine (GKE) for internet accessibility

## 🏠 Local Development Setup

### Prerequisites
- Docker Desktop
- Minikube 
- kubectl
- Node.js 16+
- Ollama
- Python 3.9+

### Quick Start
```bash
# 1. Start local services
ollama serve &
minikube start

# 2. Deploy locally
./scripts/deploy-local.sh

# 3. Start frontend
cd frontend
npm install
npm start &
```

### Available Models (Local)
Your Ollama setup includes these 6 models:
- **Phi-2 (Microsoft)** - 2.7B parameters, fast inference
- **Llama 2 (Meta)** - 7B parameters, general purpose  
- **DeepSeek Coder** - 6.7B parameters, code generation
- **Code Llama (Meta)** - 7B parameters, coding assistant
- **Mistral 7B** - 7B parameters, instruction following
- **Neural Chat (Intel)** - 7B parameters, conversational

### Local Access
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health

## ☁️ Cloud Deployment Setup

### Prerequisites
- Google Cloud account (free tier sufficient)
- GitHub repository
- gcloud CLI installed

### Step 1: Google Cloud Setup
```bash
# Run the automated setup script
./scripts/setup-cloud.sh
```

This script will:
- Create a GKE cluster optimized for free tier
- Set up service accounts and permissions
- Generate authentication keys
- Configure the cluster

### Step 2: GitHub Secrets Configuration

Add these secrets to your GitHub repository at `Settings > Secrets and variables > Actions`:

| Secret Name | Description | Required |
|-------------|-------------|----------|
| `GCP_PROJECT_ID` | Your Google Cloud Project ID | ✅ Yes |
| `GCP_SA_KEY` | Service account JSON key | ✅ Yes |
| `HF_API_TOKEN` | Hugging Face API token | ⚠️ Optional* |

*Optional but recommended for higher rate limits

### Step 3: Deploy to Cloud
```bash
# Push to main branch to trigger deployment
git add .
git commit -m "Deploy to cloud"
git push origin main
```

### Cloud Model Configuration
The cloud deployment uses **microsoft/DialoGPT-medium** from Hugging Face:
- Free to use with API
- Optimized for conversations
- No GPU requirements
- Suitable for free tier limits

## 🔄 Switching Between Environments

### Local Development
```bash
# Apply local configuration
kubectl apply -f k8s/configmap-local.yaml
kubectl rollout restart deployment/llm-chatbot-backend
```

### Cloud Testing
```bash
# Apply cloud configuration  
kubectl apply -f k8s/configmap-cloud.yaml
kubectl rollout restart deployment/llm-chatbot-backend
```

## 📊 Monitoring & Scaling

### Local Monitoring
```bash
# View logs
kubectl logs -f -l app=llm-chatbot

# Monitor scaling
kubectl get hpa -w

# Resource usage
kubectl top pods
```

### Cloud Monitoring
- **Google Cloud Console**: Monitor cluster in GKE section
- **External IP**: Get from `kubectl get services`
- **Scaling**: Automatic based on CPU/memory usage (1-3 replicas)

## 🛠️ Configuration Details

### Resource Allocation

| Environment | CPU Request | Memory Request | CPU Limit | Memory Limit |
|-------------|-------------|----------------|-----------|--------------|
| Local | 200m | 256Mi | 500m | 512Mi |
| Cloud | 100m | 128Mi | 250m | 256Mi |

### Scaling Configuration

| Environment | Min Replicas | Max Replicas | CPU Threshold | Memory Threshold |
|-------------|--------------|--------------|---------------|------------------|
| Local | 2 | 5 | 70% | 80% |
| Cloud | 1 | 3 | 60% | 70% |

## 🔧 Troubleshooting

### Local Issues

**Ollama Connection Failed**
```bash
# Check Ollama status
ollama list
curl http://localhost:11434/api/version

# Restart if needed
pkill ollama
ollama serve &
```

**Minikube Issues**
```bash
# Reset Minikube
minikube delete
minikube start --driver=docker
```

### Cloud Issues

**Deployment Failed**
```bash
# Check deployment status
kubectl get pods -l app=llm-chatbot
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**External IP Pending**
```bash
# Check service status
kubectl get services
kubectl describe service llm-chatbot-backend-service
```

## 📈 Performance Optimization

### Local Optimization
- Use Phi-2 for fastest responses
- Use Llama 2 for best quality
- Use DeepSeek/Code Llama for coding

### Cloud Optimization
- Monitor Hugging Face API rate limits
- Consider upgrading to paid HF plan for production
- Scale replicas based on traffic patterns

## 🔒 Security Considerations

### Local Security
- All data stays on your machine
- No external API calls (except optional HF)
- Full model privacy

### Cloud Security
- HTTPS encryption in transit
- Kubernetes RBAC enabled
- Non-root container execution
- Network policies applied

## 💰 Cost Management

### Local Costs
- **Free**: Complete local development
- **Hardware**: Recommend 8GB+ RAM for multiple models

### Cloud Costs (Google Cloud Free Tier)
- **GKE**: Free tier includes small cluster
- **Load Balancer**: ~$18/month (can use NodePort for testing)
- **Storage**: Minimal (container images)
- **Networking**: Free tier includes data transfer

### Cost Optimization Tips
1. Use preemptible nodes (60-91% savings)
2. Scale down during low usage
3. Monitor with budget alerts
4. Consider Cloud Run for lighter workloads

## 🚀 Next Steps

1. **Test locally** with all 6 models
2. **Deploy to cloud** using the setup script
3. **Monitor performance** and adjust scaling
4. **Add custom models** or fine-tuning
5. **Implement CI/CD** improvements

## 📞 Support

For issues:
1. Check the troubleshooting section
2. Review GitHub Actions logs
3. Monitor Kubernetes events
4. Check Google Cloud Console

Happy deploying! 🎉 