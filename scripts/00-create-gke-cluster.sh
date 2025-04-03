#!/usr/bin/env bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Load variables from env.sh
source env.sh

# Function to check required variables
check_required_vars() {
    local required_vars=("ZONE" "CLUSTER_NAME" "MAIN_MACHINE_TYPE" "GPU_MACHINE_TYPE" "NUM_NODES")
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
        printf "\r%s" "${spin:$i:1}"
        sleep 0.1
    done
    printf "\r"
}

# Function to create main cluster
create_main_cluster() {
    echo -n "[1/4] Creating GKE cluster '$CLUSTER_NAME' [⠋] "
    gcloud config set compute/zone "$ZONE" --quiet >/dev/null 2>&1
    
    gcloud container clusters create "$CLUSTER_NAME" \
        --zone "$ZONE" \
        --num-nodes "$NUM_NODES" \
        --machine-type "$MAIN_MACHINE_TYPE" \
        --enable-autoupgrade \
        --enable-autorepair \
        --scopes cloud-platform \
        --quiet > cluster_output.txt 2>&1 & 
    local pid=$!
    
    spinner "$pid"
    if ! wait "$pid"; then
        local error_line=$(grep -o "ERROR:.*" cluster_output.txt || echo "Unknown error")
        local reason=""
        local details=""
        if [[ "$error_line" =~ "code=409" ]]; then
            reason="Cluster already exists"
            details=$(echo "$error_line" | grep -o "projects/.*" || echo "Unknown details")
        else
            reason="Unknown failure"
            details=$(echo "$error_line" | cut -d':' -f2-)
        fi
        
        echo "[1/4] Failed to create cluster '$CLUSTER_NAME' [✘]"
        echo "      Reason: $reason"
        echo "      Details: $details"
        echo "      Tip: Use a different CLUSTER_NAME or delete the existing cluster first"
        rm cluster_output.txt
        exit 1
    fi
    rm cluster_output.txt
}

# Function to display cluster info
cluster_info() {
    # Small delay to ensure GKE registers the cluster
    sleep 2
    
    # Get cluster details from gcloud container clusters list
    local cluster_info=$(gcloud container clusters list --filter="name=$CLUSTER_NAME" --format="value(endpoint, status)")
    local master_ip=$(echo "$cluster_info" | awk '{print $1}')
    local status=$(echo "$cluster_info" | awk '{print $2}')
    
    if [[ -z "$master_ip" || -z "$status" ]]; then
        echo "[1/4] Cluster '$CLUSTER_NAME' created, but details unavailable [✔]"
        echo "      Location: $ZONE  |  IP: Unknown (check 'gcloud container clusters list')"
        echo "      Type: $MAIN_MACHINE_TYPE     |  Nodes: $NUM_NODES"
        echo "      Status: Unknown (check 'gcloud container clusters list')"
    else
        echo "[1/4] Cluster '$CLUSTER_NAME' created! [✔]"
        echo "      Location: $ZONE  |  IP: $master_ip"
        echo "      Type: $MAIN_MACHINE_TYPE     |  Nodes: $NUM_NODES"
        echo "      Status: $status"
    fi
    echo
}

# Function to add GPU node pool
add_gpu_node_pool() {
    echo -n "[2/4] Adding GPU node pool 'gpu-pool' [⠙] "
    gcloud container node-pools create "gpu-pool" \
        --cluster "$CLUSTER_NAME" \
        --zone "$ZONE" \
        --machine-type "$GPU_MACHINE_TYPE" \
        --accelerator "type=nvidia-tesla-t4,count=1" \
        --num-nodes 1 \
        --enable-autoupgrade \
        --enable-autorepair \
        --quiet > nodepool_output.txt 2>&1 & 
    local pid=$!
    
    spinner "$pid"
    wait "$pid" || {
        echo "[2/4] Failed to add GPU node pool [✘]"
        cat nodepool_output.txt
        rm nodepool_output.txt
        exit 1
    }
    
    local disk_size="100 GB"
    echo "[2/4] GPU pool added! [✔]"
    echo "      Type: $GPU_MACHINE_TYPE  |  Disk: $disk_size"
    echo
    rm nodepool_output.txt
}

# Function to configure kubectl
configure_kubectl() {
    echo -n "[3/4] Fetching credentials [⠹] "
    gcloud container clusters get-credentials "$CLUSTER_NAME" \
        --zone "$ZONE" \
        --quiet > /dev/null 2>&1 & 
    local pid=$!
    
    spinner "$pid"
    wait "$pid" || {
        echo "[3/4] Failed to fetch credentials [✘]"
        exit 1
    }
    
    echo "[3/4] Credentials ready! [✔]"
    echo
}

# Function to verify nodes
verify_nodes() {
    echo -n "[4/4] Verifying nodes [⠸] "
    local timeout=300
    local start_time=$(date +%s)
    
    while true; do
        if kubectl get nodes | grep -q "Ready" && [ $(kubectl get nodes | grep -c "Ready") -eq "$((NUM_NODES + 1))" ]; then
            echo "[4/4] All nodes ready! [✔]"
            echo
            break
        fi
        local current_time=$(date +%s)
        if [ $((current_time - start_time)) -gt "$timeout" ]; then
            echo "[4/4] Node verification timed out [✘]"
            exit 1
        fi
        sleep 5
    done
}

# Main execution
main() {
    check_required_vars
    
    create_main_cluster
    cluster_info
    add_gpu_node_pool
    configure_kubectl
    verify_nodes
    
    echo "🚀 OllamaKubeUI cluster deployed successfully!"
}

# Run main function
main

