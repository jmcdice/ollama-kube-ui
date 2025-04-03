#!/usr/bin/env bash

# GCP Configuration
export ZONE="us-central1-a"              # Set your GCP compute zone
export CLUSTER_NAME="my-k8s-cluster"     # Choose a name for your Kubernetes cluster
export PROJECT="my-gcp-project"          # Set your GCP project ID
export ACCOUNT="your-email@example.com"  # Set your GCP account email

# Cluster Configuration
export MAIN_MACHINE_TYPE="e2-small"      # VM type for the main node pool (e2-small is lightweight for Open WebUI)
export GPU_MACHINE_TYPE="n1-standard-4"  # VM type for the GPU node pool (n1-standard-4 supports NVIDIA Tesla T4)
export NUM_NODES="3"                     # Number of nodes for the main node pool

# Optional: Additional configurations
# export REGION="us-central1"            # GCP region for resources
# export GPU_TYPE="nvidia-tesla-t4"      # GPU type if using GPU nodes (already set in script, but adjustable here)
