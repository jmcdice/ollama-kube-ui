# Deploying Ollama in OllamaKubeUI

![Ollama on Kubernetes](https://raw.githubusercontent.com/ollama/ollama/main/docs/ollama.png)

## What You'll Learn
In this guide, you'll deploy Ollama (an AI model server) on your Kubernetes cluster and interact with its API. Ollama will run on a GPU-enabled node, providing fast inference for AI models like Phi-4 or Llama 2.

## Prerequisites

Before starting, make sure you have:

- A running GKE cluster (created using `scripts/00-create-gke-cluster.sh`)
- Helm installed on your machine
- `kubectl` configured to access your cluster
- `jq` installed (for parsing JSON responses)
- Ollama CLI installed (optional, for enhanced interaction)

## Deployment Process

### Step 1: Run the Deployment Script

From the `scripts/` directory, execute:

```bash
./01-deploy-ollama.sh ../config/ollama-values.yaml
```

### Step 2: Watch the Process

The script performs three key operations:

1. **Connects to your GKE cluster**
2. **Deploys Ollama using Helm**
3. **Verifies the deployment and GPU allocation**

### Sample Output:

```
[1/3] Connecting to cluster 'joecool-k8s' [⠋] 
[1/3] Connected to cluster! [✔]

[2/3] Deploying Ollama to 'joecool-k8s' [⠙] 
[2/3] Ollama deployed! [✔]
      Namespace: ollama  |  Port: 11434

[3/3] Verifying Ollama deployment [⠹] 
[3/3] Deployment verified! [✔]
      Pod Status:
      NAME                      STATUS
      ollama-79d74fbdd8-245jq   Running
      GPU Allocation:
      NAME                                         GPU
      gke-joecool-k8s-default-pool-a16477af-1q5r   <none>
      gke-joecool-k8s-default-pool-a16477af-1w8c   <none>
      gke-joecool-k8s-default-pool-a16477af-br96   <none>
      gke-joecool-k8s-gpu-pool-66f62c69-1klx       1

🚀 Ollama deployed successfully to OllamaKubeUI!
   Access it with: kubectl port-forward svc/ollama -n ollama 11434:11434
   Then visit: http://localhost:11434
```

> **What's happening behind the scenes?** The script connects to your cluster, uses Helm to deploy Ollama, and then verifies that it's running with proper GPU support. The configuration in `../config/ollama-values.yaml` sets up a 100Gi persistent volume and pulls your AI model (phi4 or llama2).

## Accessing Ollama

Ollama runs in its own namespace and isn't exposed outside the cluster by default. You'll need to use port-forwarding to communicate with it from your local machine.

### Start Port-Forwarding

In a dedicated terminal window, run:

```bash
kubectl port-forward svc/ollama -n ollama 11434:11434
```

You should see:
```
Forwarding from 127.0.0.1:11434 -> 11434
```

> **Important:** Keep this terminal window open while you're working with Ollama!

### Method 1: Using the REST API

#### Check Available Models

In a new terminal, verify which models Ollama has loaded:

```bash
curl -s http://localhost:11434/api/tags
```

**Example response:**
```json
{
  "models": [
    {
      "name": "phi4:latest",
      "modified_at": "2025-04-03T17:14:48.968109835Z",
      "size": 3829271040,
      "digest": "sha256:abc123..."
    }
  ]
}
```

This confirms that your model (in this case, phi4) is loaded and ready to use.

## Interacting with Ollama API

Now for the fun part - let's talk to our AI model!

#### Developer View (Full Response)

To see everything Ollama returns, including technical details:

```bash
curl -s -X POST http://localhost:11434/api/generate -d '{"model": "phi4", "prompt": "Hello, world!", "stream": false}' | jq
```

**Example response:**
```json
{
  "model": "phi4",
  "created_at": "2025-04-03T17:16:04.659269337Z",
  "response": "Hello! How can I assist you today? Whether you have questions or need information on a specific topic, feel free to let me know.",
  "done": true,
  "done_reason": "stop",
  "context": [
    100264, 882, 100266, 198, 9906, 11, 1917, 0, 100265, 198,
    100264, 78191, 100266, 198, 9906, 0, 2650, 649, 358, 7945,
    499, 3432, 30, 13440, 499, 617, 4860, 477, 1205, 2038,
    389, 264, 3230, 8712, 11, 2733, 1949, 311, 1095, 757, 1440, 13
  ],
  "total_duration": 1238987532,
  "load_duration": 17022697,
  "prompt_eval_count": 14,
  "prompt_eval_duration": 9763721,
  "eval_count": 29,
  "eval_duration": 1211383304
}
```

**Response breakdown:**
- `response`: The AI's actual answer
- `context`: Token IDs representing the conversation history
- `total_duration`: Time taken for processing (in nanoseconds)
- `stream: false` ensures we get the complete response at once (not token-by-token)

#### User View (Just the Text)

For a cleaner output with only the AI's response:

```bash
curl -s -X POST http://localhost:11434/api/generate -d '{"model": "phi4", "prompt": "Hello, world!", "stream": false}' | jq -r '.response'
```

**Example response:**
```
Hello! How can I assist you today? Whether you have questions or need information on a specific topic, feel free to let me know.
```

> **Note:** This cleaner output is perfect for demos or when integrating with other scripts!

### Method 2: Using the Ollama CLI

If you have the Ollama CLI installed on your machine, you can interact with your Kubernetes-deployed Ollama directly:

#### Set the Ollama Host

First, tell the CLI where to find your Ollama service:

```bash
export OLLAMA_HOST=http://localhost:11434
```

#### List Available Models

Check which models are available:

```bash
ollama list
```

**Example output:**
```
NAME              ID              SIZE      MODIFIED
deepseek-r1:8b    28f8fd6cdc67    4.9 GB    14 minutes ago
phi4:latest       ac896e5b8b34    9.1 GB    15 minutes ago
```

#### Run a Model

You can now run queries directly using the CLI:

```bash
ollama run phi4 "Explain Kubernetes in simple terms"
```

## Troubleshooting

If you encounter issues with Ollama:

1. **Check pod status:**
   ```bash
   kubectl get pods -n ollama
   ```

2. **View the logs:**
   ```bash
   kubectl logs <pod-name> -n ollama
   ```

3. **Inspect pod details:**
   ```bash
   kubectl describe pod <pod-name> -n ollama
   ```
   Look at the Events section for delays like image pulls or volume mounts.

4. **Verify CLI connectivity:**
   ```bash
   # Ensure port-forwarding is running
   echo $OLLAMA_HOST
   # Should return http://localhost:11434
   ```

## Learning Objectives Achieved

By completing this guide, you've:
- Deployed an AI model server on Kubernetes
- Connected to a service running in your cluster
- Interacted with a REST API
- Used GPU resources in a container environment
- Practiced debugging techniques for Kubernetes deployments
- Used environment variables to configure CLI tools

## Next Steps

With Ollama running, you're ready to:
1. Deploy Open WebUI (see `02-deploy-webui.sh`) for a user-friendly interface
2. Experiment with different prompts and model parameters
3. Build applications that interact with your AI model

