# OllamaKubeUI

A repository for deploying GPU-enabled Kubernetes clusters on GCP with Ollama AI model server and Open WebUI. Built for CS students to explore cloud computing, Kubernetes, and AI technologies.

## Overview

This project demonstrates:

1. GKE cluster creation with GPU node pools
2. Ollama deployment via Helm charts
3. Open WebUI configuration for model interaction
4. Kubernetes service management and networking

## Prerequisites

- Google Cloud SDK (`gcloud`)
- Helm 3.x
- kubectl
- GCP project with billing enabled and necessary APIs activated
- Basic knowledge of Kubernetes concepts

## Quickstart

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/ollama-kube-ui.git
   cd ollama-kube-ui
   ```

2. **Configure environment**:
   ```bash
   cp config/example.env.sh scripts/env.sh
   # Edit scripts/env.sh with your GCP project details
   ```

3. **Deploy the infrastructure**:
   ```bash
   cd scripts
   ./00-create-gke-cluster.sh
   ./01-deploy-ollama.sh ../config/ollama-values.yaml
   ./02-deploy-webui.sh ../config/webui-values.yaml
   ```

4. **Access services**:
   - For Ollama API: 
     ```bash
     kubectl port-forward svc/ollama -n ollama 11434:11434
     # Test with: curl http://localhost:11434/api/tags
     ```
   - For Open WebUI: The external IP is automatically provided by the deployment script
     ```bash
     # If needed, get the IP manually:
     kubectl get svc open-webui -n open-webui
     # Navigate to http://<EXTERNAL-IP>:8080
     ```

## Directory Structure

```
ollama-kube-ui/
├── config/                # Configuration files
│   ├── example.env.sh     # Environment variables template
│   ├── ollama-values.yaml # Helm values for Ollama
│   └── webui-values.yaml  # Helm values for Open WebUI
├── docs/                  # Documentation
│   ├── ollama-readme.md   # Ollama deployment guide
│   └── open-webui-readme.md # Open WebUI deployment guide
└── scripts/              # Deployment scripts
    ├── 00-create-gke-cluster.sh # Creates a GKE cluster with GPU support
    ├── 01-deploy-ollama.sh      # Deploys Ollama using Helm
    └── 02-deploy-webui.sh       # Deploys Open WebUI using Helm
```

## Environment Configuration

Key parameters in `scripts/env.sh`:

```bash
# GCP Configuration
export ZONE="us-central1-a"              # GCP compute zone
export CLUSTER_NAME="ollama-k8s-cluster" # Kubernetes cluster name
export PROJECT="your-gcp-project-id"     # GCP project ID
export ACCOUNT="your-email@example.com"  # GCP account email

# Cluster Configuration
export MACHINE_TYPE="e2-standard-4"      # VM type for standard nodes
export NUM_NODES="3"                     # Number of nodes in main pool
export GPU_TYPE="nvidia-tesla-t4"        # GPU type for GPU nodes
```

## Deployed AI Models

The default configuration deploys:

1. **Phi-3 Mini (3.8B)** - Microsoft's compact model optimized for instruction following
   - Good performance/resource balance
   - ~4GB of VRAM required

2. **DeepSeek R1 (8B)** - Advanced reasoning model
   - Strong coding and analytical capabilities
   - ~8GB of VRAM required

## Technical Implementation

### GKE Cluster
- Creates a standard node pool for system components
- Creates a GPU node pool with NVIDIA Tesla T4 GPUs
- Installs NVIDIA device plugins automatically

### Ollama Deployment
- Runs in a dedicated namespace
- Uses a PersistentVolumeClaim for model storage
- GPU scheduling configured via resource requests
- Internal Service for cluster communication

### Open WebUI
- LoadBalancer Service for external access
- Pre-configured to connect to Ollama internal Service
- No embedded Ollama instance (uses the dedicated deployment)

## Resource Requirements

| Component | CPU | Memory | Storage | GPU |
|-----------|-----|--------|---------|-----|
| GKE standard nodes | 4 vCPU | 16GB | 100GB | - |
| GKE GPU nodes | 4 vCPU | 16GB | 100GB | 1x NVIDIA T4 |
| Ollama | 1-2 cores | 4GB | 15GB PV | 1 GPU |
| Open WebUI | 0.5 cores | 1GB | - | - |

## Advanced Usage

### Command-line Ollama Interaction

With port-forwarding running:

```bash
# Set Ollama host
export OLLAMA_HOST=http://localhost:11434

# List available models
ollama list

# Run model with prompt
ollama run phi3:mini "Explain Kubernetes pods"
```

### GPU Optimization

For better model performance:

```bash
# Check GPU utilization
kubectl exec -it -n ollama $(kubectl get pods -n ollama -o name | head -n 1) -- nvidia-smi

# Adjust model parameters via API
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "phi3:mini", 
  "prompt": "Hello", 
  "options": {"num_gpu": 1, "num_thread": 8}
}'
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| GPU not detected | `kubectl describe nodes \| grep nvidia` to verify drivers |
| Out of memory | Reduce model size or increase node VM size |
| Open WebUI can't connect to Ollama | Check `kubectl logs open-webui-0 -n open-webui` |
| Slow inference | Verify GPU scheduling with `kubectl describe pod -n ollama` |

## Cleanup

Complete cleanup:
```bash
gcloud container clusters delete ${CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT}
```

Selective cleanup:
```bash
kubectl delete namespace ollama
kubectl delete namespace open-webui
```

