#!/usr/bin/env bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Load variables from env.sh
source "$(dirname "$0")/env.sh"

# Function to check required variables
check_required_vars() {
    local required_vars=("ZONE" "CLUSTER_NAME")
    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        echo "Error: Missing required environment variables: ${missing_vars[*]}"
        exit 1
    fi
}

# Function to simulate a spinner
spinner() {
    local pid=$1
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        i=$(((i + 1) % 10))
        printf "\r[Running] %s" "${spin:$i:1}"
        sleep 0.1
    done
    printf "\r"
}

# Function to connect to cluster
connect_to_cluster() {
    echo -n "[1/3] Connecting to cluster '$CLUSTER_NAME' [⠋] "
    gcloud container clusters get-credentials "$CLUSTER_NAME" \
        --zone "$ZONE" \
        --quiet > /dev/null 2>&1 &
    local pid=$!
    
    spinner "$pid"
    wait "$pid" || {
        echo "[1/3] Failed to connect to cluster '$CLUSTER_NAME' [✘]"
        echo "      Reason: Unable to fetch credentials"
        echo "      Tip: Check your gcloud auth or cluster status"
        exit 1
    }
    
    echo "[1/3] Connected to cluster! [✔]"
    echo
}

# Function to deploy Ollama with Helm
deploy_ollama() {
    local values_file="$1"
    
    # Check if values file exists
    if [[ ! -f "$values_file" ]]; then
        echo "[2/3] Failed to deploy Ollama [✘]"
        echo "      Reason: Values file '$values_file' not found"
        echo "      Tip: Provide a valid path to the Ollama values YAML file"
        exit 1
    fi
    
    echo -n "[2/3] Deploying Ollama to '$CLUSTER_NAME' [⠙] "
    
    # Add repo and update in background
    (
        helm repo add ollama-helm https://otwld.github.io/ollama-helm/ &&
        helm repo update &&
        helm upgrade --install ollama ollama-helm/ollama \
            --namespace ollama \
            --create-namespace \
            --values "$values_file" \
            --set ollama.host="0.0.0.0:11434" \
            --wait \
            --timeout 5m \
            > ollama_output.txt 2>&1
    ) &
    local pid=$!
    
    spinner "$pid"
    if ! wait "$pid"; then
        # Check if output file exists before grepping
        local reason="Unknown failure"
        if [[ -f ollama_output.txt ]]; then
            local error_line=$(grep -o "Error:.*" ollama_output.txt || echo "Unknown error")
            reason=$(echo "$error_line" | cut -d':' -f2- | sed 's/^[ \t]*//')
            echo "[2/3] Failed to deploy Ollama [✘]"
            echo "      Reason: ${reason:-Unknown failure}"
            echo "      Tip: Check the values file '$values_file' or Helm chart availability"
            cat ollama_output.txt
            rm -f ollama_output.txt
        else
            echo "[2/3] Failed to deploy Ollama [✘]"
            echo "      Reason: Helm command failed, no output captured"
            echo "      Tip: Ensure Helm is installed and configured correctly"
        fi
        exit 1
    fi
    
    echo "[2/3] Ollama deployed! [✔]"
    echo "      Namespace: ollama  |  Port: 11434"
    rm -f ollama_output.txt
    echo
}

# Function to verify deployment
verify_deployment() {
    echo -n "[3/3] Verifying Ollama deployment [⠹] "
    
    # Run verification in background
    (
        kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=ollama -n ollama --timeout=2m &&
        kubectl get pods -n ollama -o custom-columns="NAME:.metadata.name,STATUS:.status.phase" > pod_status.txt &&
        kubectl get nodes "-o=custom-columns=NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu" > gpu_status.txt
    ) &
    local pid=$!
    
    spinner "$pid"
    wait "$pid" || {
        echo "[3/3] Verification failed [✘]"
        echo "      Reason: Pods or nodes not ready"
        echo "      Tip: Check pod logs with 'kubectl logs -n ollama'"
        rm -f pod_status.txt gpu_status.txt
        exit 1
    }
    
    echo "[3/3] Deployment verified! [✔]"
    echo "      Pod Status:"
    cat pod_status.txt | sed 's/^/      /'
    echo "      GPU Allocation:"
    cat gpu_status.txt | sed 's/^/      /'
    rm -f pod_status.txt gpu_status.txt
    echo
}

# Main execution
main() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: $0 <path-to-ollama-values.yaml>"
        echo "Example: $0 ../config/ollama-values.yaml"
        exit 1
    fi
    
    local values_file="$1"
    
    check_required_vars
    connect_to_cluster
    deploy_ollama "$values_file"
    verify_deployment
    
    echo "🚀 Ollama deployed successfully to OllamaKubeUI!"
    echo "   Access it with: kubectl port-forward svc/ollama -n ollama 11434:11434"
    echo "   Then visit: http://localhost:11434"
}

# Run main function with argument
main "$@"

