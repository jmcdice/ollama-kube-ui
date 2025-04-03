# Deploying Open WebUI in OllamaKubeUI

![Open WebUI interface](https://open-webui.com/assets/open-webui-hero.webp)

## What You'll Learn

This guide shows you how to deploy Open WebUI—a user-friendly web interface for interacting with AI models—on your Kubernetes cluster. This setup connects to your existing Ollama instance and exposes the interface publicly, allowing direct access without port-forwarding.

## Prerequisites

Before starting, make sure you have:

- A running GKE cluster (created using `scripts/00-create-gke-cluster.sh`)
- Ollama deployed and running (from `scripts/01-deploy-ollama.sh`)
- Helm installed on your machine
- `kubectl` configured to access your cluster

## Deployment Process

### Step 1: Run the Deployment Script

From the `scripts/` directory, execute:

```bash
./02-deploy-webui.sh ../config/webui-values.yaml
```

### Step 2: Observe the Deployment Process

The script performs three key operations:

1. **Connects to your GKE cluster**
2. **Deploys Open WebUI using Helm**
3. **Verifies the deployment and provides access information**

### Sample Output:

```
[1/3] Connecting to cluster 'joecool-k8s' [⠋] 
[1/3] Connected to cluster! [✔]

[2/3] Deploying Open WebUI to 'joecool-k8s' [⠙] 
[2/3] Open WebUI deployed! [✔]
      Namespace: open-webui  |  Port: 8080

[3/3] Verifying Open WebUI deployment [⠹] 
[3/3] Deployment verified! [✔]
      Pod Status:
      NAME                STATUS
      open-webui-0        Running
      
      Access URL: http://34.56.78.90:8080

Open WebUI deployed successfully to OllamaKubeUI!
Access it at: http://34.56.78.90:8080
```

> **What's happening behind the scenes?** The script connects to your cluster, uses Helm to deploy Open WebUI, and then verifies that it's running with a public IP. The configuration in `../config/webui-values.yaml` sets up a LoadBalancer service and connects to your Ollama instance at `http://ollama.ollama.svc.cluster.local:11434`.

## Accessing Open WebUI

Unlike Ollama, Open WebUI is exposed publicly via a LoadBalancer—no port-forwarding required!

### Step 1: Get the External IP

The deployment script outputs the URL (e.g., `http://34.56.78.90:8080`). If you need to find it later:

```bash
kubectl get svc open-webui -n open-webui
```

Look for the `EXTERNAL-IP` column (it might take a minute to be assigned).

### Step 2: Visit the UI

1. Open your browser to `http://<EXTERNAL-IP>:8080`
2. Create an admin account on your first visit
3. Log in with your new credentials

### Step 3: Verify Ollama Connection

1. Navigate to **Settings > Connections** in the UI
   - You should see Ollama configured at `http://ollama.ollama.svc.cluster.local:11434`

2. In the chat interface:
   - Select phi4 (or your deployed model) from the model dropdown
   - Type "Hello, world!" and send the message
   - You should receive a response from the AI model

## How It Works

This setup has several key components:

- **LoadBalancer Service**: Exposes Open WebUI on port 8080 with a public IP address
- **Kubernetes Internal DNS**: Connects to your Ollama instance using `http://ollama.ollama.svc.cluster.local:11434`
- **Configuration**: Uses a custom values file that disables the embedded Ollama (`ollama.enabled: false`) to use your standalone deployment

## Troubleshooting

If Open WebUI isn't connecting to Ollama:

### Check Pod Status
```bash
kubectl get pods -n open-webui
```
All pods should show `Running` status.

### Verify Environment Variables
```bash
kubectl exec -it open-webui-0 -n open-webui -- env | grep OLLAMA_BASE_URL
```
Should display: `OLLAMA_BASE_URL=http://ollama.ollama.svc.cluster.local:11434`

### Test Connectivity
```bash
kubectl exec -it open-webui-0 -n open-webui -- curl -I http://ollama.ollama.svc.cluster.local:11434
```
Should return `HTTP/1.1 200 OK`.

### Check Logs
```bash
kubectl logs open-webui-0 -n open-webui
```
Look for any connection errors or issues.

### LoadBalancer IP Not Assigned?
```bash
kubectl get svc open-webui -n open-webui
```
If `EXTERNAL-IP` shows `<pending>`, wait a few minutes and check again. GCP sometimes takes time to provision IPs.

## Cleanup

To remove Open WebUI when you're done:

```bash
helm uninstall open-webui -n open-webui
kubectl delete namespace open-webui
```

## Impressive Test Questions for DeepSeek

When demonstrating to students, try these advanced questions that showcase DeepSeek's capabilities:

1. "Design a distributed system architecture for a real-time multiplayer game that needs to support 100,000 concurrent users. Explain key components and how they would handle scaling challenges."

2. "Compare and contrast different approaches to implementing a distributed database system. What are the tradeoffs between consistency, availability, and partition tolerance in practical implementations?"

3. "Explain how you would implement a simple compiler for a subset of Python. Walk through the lexing, parsing, semantic analysis, and code generation steps with examples."

4. "If you were designing a new programming language for parallel computing, what features would you include to make concurrency safer and more intuitive than in current languages?"

5. "Explain quantum computing algorithms to a CS student who understands classical algorithms. What makes Shor's algorithm and Grover's algorithm significant?"

---

