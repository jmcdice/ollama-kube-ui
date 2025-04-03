#!/usr/bin/env bash
# GCP Configuration
export ZONE="us-central1-a"              # Set your GCP compute zone
export CLUSTER_NAME="my-k8s-cluster"     # Choose a name for your Kubernetes cluster
export PROJECT="my-gcp-project"          # Set your GCP project ID
export ACCOUNT="your-email@example.com"  # Set your GCP account email

# Cluster Configuration
export MACHINE_TYPE="e2-standard-4"      # VM type for your nodes (e2-standard-4 is a good starting point)
export NUM_NODES="3"                     # Number of nodes for the main node pool

# Optional: Additional configurations
# Uncomment and modify as needed
# export REGION="us-central1"            # GCP region for resources
# export GPU_TYPE="nvidia-tesla-t4"      # GPU type if using GPU nodes
