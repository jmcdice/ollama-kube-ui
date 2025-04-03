# Deploying Open WebUI to Kubernetes: Command Line Guide

This guide walks you through manually deploying Open WebUI to a Kubernetes cluster using command-line tools. Following these steps will help you understand the deployment process (as opposed to running the script: 02-deploy-webui.sh).

## Prerequisites

- `gcloud` CLI installed and configured
- `kubectl` installed and configured
- `helm` installed
- A GKE cluster
- A values file for Open WebUI configuration

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

## Step 2: Deploy Open WebUI with Helm

Add the Open WebUI Helm repository and deploy:

```bash
# Add the Open WebUI Helm repository
helm repo add open-webui https://open-webui.github.io/helm-charts/

# Update Helm repositories
helm repo update

# Deploy Open WebUI using your values file
# Replace path/to/your-values.yaml with the path to your configuration file
helm upgrade --install open-webui open-webui/open-webui \
  --namespace open-webui \
  --create-namespace \
  --values config/webui-values.yaml \
  --wait \
  --timeout 5m
```

## Step 3: Verify the Deployment

Check if your Open WebUI pods are running correctly:

```bash
# Wait for pods to be ready
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/component=open-webui -n open-webui --timeout=2m

# Check pod status
kubectl get pods -n open-webui
```

## Step 4: Get the External IP

Retrieve the LoadBalancer's external IP to access the UI:

```bash
# Get the external IP address
kubectl get svc open-webui -n open-webui

# Alternative command to directly get the IP
# Note: It may take a few minutes for the LoadBalancer to assign an IP
kubectl get svc open-webui -n open-webui -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Once you have the external IP, you can access Open WebUI at:
`http://<EXTERNAL_IP>:8080`

## Troubleshooting

If you encounter issues:

- Check pod logs: `kubectl logs -n open-webui <pod-name>`
- Check pod events: `kubectl describe pod <pod-name> -n open-webui`
- View recent namespace events: `kubectl get events -n open-webui --sort-by='.metadata.creationTimestamp'`
- Verify service configuration: `kubectl describe svc open-webui -n open-webui`

## Cleanup

To remove the Open WebUI deployment:

```bash
helm uninstall open-webui -n open-webui
```

For a complete cleanup, delete the namespace:

```bash
kubectl delete namespace open-webui
```
