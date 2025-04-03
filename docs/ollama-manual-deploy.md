# Deploying Ollama to Kubernetes: Command Line Guide

This guide walks you through manually deploying Ollama to a Kubernetes cluster using command-line tools. Rather than running the script that automates this process from above (`01-deploy-ollama.sh`), this is the step-by-step guide to help you learn.

## Prerequisites

- `gcloud` CLI installed and configured
- `kubectl` installed and configured
- `helm` installed
- A GKE cluster with GPU support
- A values file for Ollama configuration

## Step 1: Connect to Your Kubernetes Cluster

Connect to your GKE cluster to set up your `kubectl` context:

```bash
# Replace CLUSTER_NAME and ZONE with your specific values
export CLUSTER_NAME="your-cluster-name"
export ZONE="your-cluster-zone"

# Get credentials for your cluster
gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$ZONE"

# Verify connection
kubectl cluster-info
```

## Step 2: Deploy Ollama with Helm

Add the Ollama Helm repository and deploy Ollama:

```bash
# Add the Ollama Helm repository
helm repo add ollama-helm https://otwld.github.io/ollama-helm/

# Update Helm repositories
helm repo update

# Deploy Ollama using your values file
# Replace path/to/your-values.yaml with the path to your configuration file
helm upgrade --install ollama ollama-helm/ollama \
  --namespace ollama \
  --create-namespace \
  --values config/ollama-values.yaml \
  --set ollama.host="0.0.0.0:11434" \
  --wait \
  --timeout 5m
```

## Step 3: Verify the Deployment

Check if your Ollama pods are running correctly:

```bash
# Wait for pods to be ready
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=ollama -n ollama --timeout=2m

# Check pod status
kubectl get pods -n ollama

# Check GPU allocation
kubectl get nodes -o=custom-columns=NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu
```

## Step 4: Access Ollama

Set up port forwarding to access Ollama locally:

```bash
# Forward the Ollama service port to your local machine
kubectl port-forward svc/ollama -n ollama 11434:11434
```

You can now access Ollama at http://localhost:11434

## Troubleshooting

If you encounter issues:

- Check pod logs: `kubectl logs -n ollama <pod-name>`
- Verify Helm release: `helm list -n ollama`
- Check for events: `kubectl get events -n ollama`

## Cleanup

To remove the Ollama deployment:

```bash
helm uninstall ollama -n ollama
```

For a complete cleanup, delete the namespace:

```bash
kubectl delete namespace ollama
```
