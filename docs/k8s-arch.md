%title: Kubernetes Architecture Deep Dive
%author: CU Boulder
%date: April 2, 2025

-> # Kubernetes Architecture Deep Dive <-

-> *Understanding the Technical Components* <-

---

# 1. Kubernetes Core Architecture

## High-Level Architecture Overview

* **Control Plane**: Brain of the system
* **Worker Nodes**: Where applications run
* **Distributed Key-Value Store**: etcd
* **API-Driven Design**: Everything is an API call

---

## Control Plane Components

* **API Server**: REST API frontend, validation, persistence
* **etcd**: Distributed storage for all cluster data
* **Scheduler**: Decides where to place pods
* **Controller Manager**: Background control loops 
* **Cloud Controller Manager**: Cloud-specific control logic

---

## Worker Node Components

* **Kubelet**: Node agent that ensures containers run
* **Container Runtime**: (Docker, containerd, CRI-O)
* **Kube-proxy**: Network proxy and load balancer
* **CNI Plugin**: Container Network Interface implementation

---

# 2. The Kubernetes Object Model

---

## Key Resources and Abstractions

* **Pods**: Smallest deployable units
* **ReplicaSets**: Ensures specified pod count
* **Deployments**: Declarative updates for Pods/ReplicaSets
* **StatefulSets**: Ordered deployment/scaling
* **DaemonSets**: Runs a pod on each node
* **Services**: Stable networking for pods

---

## How API Objects Work

* Every object has **spec** (desired state)
* Every object has **status** (current state)
* Controllers continuously reconcile spec vs. status
* API server validates and persists all objects
* etcd provides distributed consensus

---

## Kubernetes API Design Principles

* Declarative vs imperative
* Desired state vs current state
* Control loops and reconciliation
* Level-triggered vs edge-triggered logic
* Extensibility through CRDs

---

# 3. Kubernetes Networking

---

## Network Model Fundamentals

* Every Pod gets its own IP address
* Pods on a node can communicate with all pods
* No NAT needed for pod-to-pod communication
* Agents can communicate with all pods
* Container Network Interface (CNI) implementation

---

## Service Networking

* **ClusterIP**: Internal-only IP
* **NodePort**: Exposes service on static port on nodes
* **LoadBalancer**: External load balancer
* **ExternalName**: DNS CNAME redirection
* **Ingress**: HTTP/HTTPS routing to services

---

## Network Policies

* Pod-level firewall rules
* Namespace isolation
* Fine-grained ingress/egress control
* Label-based selection
* Implementation varies by CNI plugin

---

# 4. Storage Architecture

---

## Storage Model

* **PersistentVolume**: Cluster storage resource
* **PersistentVolumeClaim**: Request by a pod
* **StorageClass**: Dynamic provisioning
* **CSI**: Container Storage Interface
* Volume plugins for cloud and on-prem storage types

---

## Storage Implementation Details

* **Node-Local Storage**: emptyDir, hostPath
* **Network Storage**: NFS, iSCSI, cloud volumes
* **Ephemeral Storage**: configMap, secret
* **Volume Snapshots**: Point-in-time copies
* **Volume Expansion**: Dynamic resize capability

---

# 5. Kubernetes Scheduler

---

## Scheduling Process

1. **Filtering**: Eliminate invalid nodes
2. **Scoring**: Rank remaining nodes
3. **Binding**: Assign pod to highest-scoring node
4. **Post-binding**: Persistent volume binding, etc.

---

## Advanced Scheduling

* **Node Affinity/Anti-Affinity**: Node selection rules
* **Pod Affinity/Anti-Affinity**: Co-location rules
* **Taints and Tolerations**: Node avoidance
* **Custom Schedulers**: Domain-specific scheduling
* **Priority and Preemption**: Resource allocation hierarchy

---

# 6. Cluster Security Architecture

---

## Authentication and Authorization

* **Authentication**: X.509 certs, tokens, OIDC
* **Authorization**: RBAC, ABAC, Node, Webhook
* **Admission Control**: Validate/mutate requests
* **Service Accounts**: In-cluster identity
* **Pod Security Policies/Standards**: Pod-level constraints

---

## Secrets Management

* **Secret Objects**: Base64-encoded (not encrypted at rest by default)
* **Secret Mounting**: As files or environment variables
* **Secret Rotation**: Manual or automated
* **Integration**: External secret stores (Vault, CSI)

---

# 7. Advanced Architecture Patterns

---

## Control Loop Pattern

```
for {
  desired := getDesiredState()
  current := getCurrentState()
  makeChanges(desired, current)
}
```

* All controllers follow this pattern
* Level-triggered, not edge-triggered
* Idempotent operations
* Reconciliation logic

---

## Operator Pattern

* **Custom Resources**: Application-specific schemas
* **Custom Controllers**: Application-specific logic
* Brings human operator knowledge into software
* Examples: databases, message queues, monitoring systems
* Kubernetes-native applications

---

## Service Mesh Architecture

* **Data Plane**: Proxies alongside each service (Envoy)
* **Control Plane**: Manages and configures proxies (Istio)
* Transparent to application code
* Features: Traffic management, security, observability
* Enables zero-trust networking model

---

# 8. OllamaKubeUI Demo Architecture

## Demo Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              GKE Cluster                                    │
│                                                                             │
│  ┌───────────────────────────────┐       ┌────────────────────────────┐     │
│  │      ollama namespace         │       │    open-webui namespace    │     │
│  │                               │       │                            │     │
│  │  ┌──────────┐   ┌──────────┐  │       │  ┌──────────┐  ┌─────────┐ │     │
│  │  │Ollama Pod│<->│PVC Models│  │       │  │WebUI Pod │->│ClusterIP│ │     │
│  │  └────┬─────┘   └──────────┘  │       │  └────┬─────┘  └────┬────┘ │     │
│  │       │                       │       │       │             │      │     │
│  │       v                       │       │       │             v      │     │
│  │  ┌────┴─────┐                 │       │       │        ┌────┴────┐ │     │
│  │  │ClusterIP │<────────────────┼───────┼───────┘        │External │ │     │
│  │  └──────────┘                 │       │                │   IP    │ │     │
│  └───────────────────────────────┘       └────────────────┴─────────┴─┘     │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Demo Components

* **ollama namespace**:
  * Ollama Pod: LLM server (phi3:mini, deepseek-r1:8b)
  * PVC: Model storage and cache
  * ClusterIP Service: Internal access point

* **open-webui namespace**:
  * WebUI Pod: Frontend interface 
  * ClusterIP Service: Internal routing
  * LoadBalancer: External browser access

---

-> # Thank You! <-

-> Questions? <-

