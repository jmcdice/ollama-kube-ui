%title: Kubernetes Architecture: The Essentials
%author: CU Boulder
%date: April 2, 2025

-> # Kubernetes Architecture: The Essentials <-

---

# 1. What is Kubernetes?

* Container orchestration platform
* Automates deployment, scaling, and management
* Originally developed by Google (based on Borg)
* Now the industry standard for container orchestration

---

# 2. Core Architecture

* **Control Plane**: The "brain" 
  * API Server: Central communication hub
  * Scheduler: Decides where to run workloads
  * Controllers: Maintain desired state

* **Worker Nodes**: Where applications run
  * Kubelet: Node agent
  * Container Runtime: (Docker/containerd)
  * Kube-proxy: Network routing

---

# 3. Key Concepts

* **Pods**: Smallest deployable units
  * One or more containers
  * Shared network namespace
  * Ephemeral by design

* **Deployments**: How you run applications
  * Declarative updates
  * Self-healing through ReplicaSets
  * Rolling updates and rollbacks

---

# 4. Service Discovery & Networking

* **Services**: Stable networking for pods
  * ClusterIP: Internal access
  * LoadBalancer: External access
  * Persistent IP regardless of pod changes

* **Ingress**: HTTP routing to services
  * Path-based routing
  * TLS termination

---

# 5. OllamaKubeUI Demo Architecture

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
