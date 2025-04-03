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

# Function to deploy Open WebUI with Helm
deploy_webui() {
    local values_file="$1"
    
    if [[ ! -f "$values_file" ]]; then
        echo "[2/3] Failed to deploy Open WebUI [✘]"
        echo "      Reason: Values file '$values_file' not found"
        echo "      Tip: Provide a valid path to the WebUI values YAML file"
        exit 1
    fi
    
    echo -n "[2/3] Deploying Open WebUI to '$CLUSTER_NAME' [⠙] "
    
    (
        #helm repo add open-webui https://open-webui.github.io/helm-charts/ &&
        #helm repo update &&
        helm upgrade --install open-webui open-webui/open-webui \
            --namespace open-webui \
            --create-namespace \
            --values "$values_file" \
            --wait \
            --timeout 5m \
            > webui_output.txt 2>&1
    ) &
    local pid=$!
    
    spinner "$pid"
    if ! wait "$pid"; then
        local error_line=$(grep -o "Error:.*" webui_output.txt || echo "Unknown error")
        local reason=$(echo "$error_line" | cut -d':' -f2- | sed 's/^[ \t]*//')
        echo "[2/3] Failed to deploy Open WebUI [✘]"
        echo "      Reason: ${reason:-Unknown failure}"
        echo "      Tip: Check the values file '$values_file' or Helm chart availability"
        cat webui_output.txt
        rm -f webui_output.txt
        exit 1
    fi
    
    echo "[2/3] Open WebUI deployed! [✔]"
    echo "      Namespace: open-webui  |  Port: 8080"
    rm -f webui_output.txt
    echo
}

# Function to verify deployment and get external IP
verify_deployment() {
    echo -n "[3/3] Verifying Open WebUI deployment [⠹] "
    
    # Check pod readiness
    (
        kubectl wait --for=condition=Ready pod -l app.kubernetes.io/component=open-webui -n open-webui --timeout=2m &&
        kubectl get pods -n open-webui -o custom-columns="NAME:.metadata.name,STATUS:.status.phase" > pod_status.txt
    ) &
    local pod_pid=$!
    spinner "$pod_pid"
    if ! wait "$pod_pid"; then
        echo "[3/3] Verification failed [✘]"
        echo "      Reason: Pods not ready"
        echo "      Current Pod Status:"
        kubectl get pods -n open-webui -o custom-columns="NAME:.metadata.name,STATUS:.status.phase" | sed 's/^/      /'
        echo "      Recent Events:"
        kubectl get events -n open-webui --sort-by='.metadata.creationTimestamp' | tail -n 5 | sed 's/^/      /'
        echo "      Tip: Check pod logs with 'kubectl logs -n open-webui'"
        rm -f pod_status.txt
        exit 1
    fi
    
    # Wait for LoadBalancer IP with retries
    local retries=12  # 2 minutes total (12 * 10s)
    local external_ip=""
    for ((i=1; i<=retries; i++)); do
        external_ip=$(kubectl get svc open-webui -n open-webui -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        if [[ -n "$external_ip" ]]; then
            break
        fi
        echo -n "[Running] Waiting for LoadBalancer IP ($i/$retries) [⠹] "
        sleep 10
        printf "\r"
    done
    
    if [[ -z "$external_ip" ]]; then
        echo "[3/3] Verification failed [✘]"
        echo "      Reason: LoadBalancer IP not assigned"
        echo "      Current Service Status:"
        kubectl get svc open-webui -n open-webui | sed 's/^/      /'
        echo "      Tip: Ensure the LoadBalancer service is provisioned correctly"
        rm -f pod_status.txt
        exit 1
    fi
    
    echo "[3/3] Deployment verified! [✔]"
    echo "      Pod Status:"
    cat pod_status.txt | sed 's/^/      /'
    echo "      Access URL: http://$external_ip:8080"
    rm -f pod_status.txt
    echo
}

# Main execution
main() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: $0 <path-to-webui-values.yaml>"
        echo "Example: $0 ../config/webui-values.yaml"
        exit 1
    fi
    
    local values_file="$1"
    
    check_required_vars
    connect_to_cluster
    deploy_webui "$values_file"
    verify_deployment
    
    echo "🚀 Open WebUI deployed successfully to OllamaKubeUI!"
    echo "   Access it at: http://$(kubectl get svc open-webui -n open-webui -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):8080"
}

# Run main function with argument
main "$@"

