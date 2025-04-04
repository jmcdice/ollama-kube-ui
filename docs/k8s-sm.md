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

-> **Challenge**: How do you manage thousands of containers across dozens of machines? <-
-> **Solution**: A system that treats your entire datacenter as one logical computer <-

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

-> **Traditional Parallel**: Control Plane = Data center management team, Worker Nodes = Rack servers <-

-> [kubectl get nodes] <-

---

# 3. Key Concepts

* **Pods**: Smallest deployable units
  * One or more containers
  * Shared network namespace
  * Ephemeral by design

```yaml
# Simple Pod Example
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.14.2
    ports:
    - containerPort: 80
```

* **Deployments**: How you run applications
  * Declarative updates
  * Self-healing through ReplicaSets
  * Rolling updates and rollbacks

-> **Challenge**: How do you ensure applications stay running even when containers or nodes fail? <-
-> **Solution**: Kubernetes automatically restarts failed containers and reschedules pods from failed nodes <-

-> [kubectl get pods] <-

---

# 4. Service Discovery & Networking

* **Services**: Stable networking for pods
  * ClusterIP: Internal access
  * LoadBalancer: External access
  * Persistent IP regardless of pod changes

```yaml
# Simple Service Example
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: MyApp
  ports:
  - port: 80
    targetPort: 9376
  type: ClusterIP
```

* **Ingress**: HTTP routing to services
  * Path-based routing
  * TLS termination

-> **Traditional Parallel**: Services = Load balancer + DNS combined <-

-> **Challenge**: How do you find and connect to services when pods are ephemeral? <-
-> **Solution**: Services provide stable endpoints that automatically route to the right pods <-

-> [kubectl get svc] <-

---

# 5. Common Kubernetes Pitfalls

* **Resource Management**:
  * Not setting CPU/memory limits (leading to node resource starvation)
  * Setting limits too low (causing throttling/OOM kills)

* **Persistence Misconceptions**:
  * Assuming pod storage is persistent (it's not!)
  * Not understanding PersistentVolume lifecycle

* **Networking Issues**:
  * Misunderstanding service discovery
  * Security policies blocking required traffic

* **Deployment Strategies**:
  * Rolling out changes without health checks
  * Not having proper rollback strategy

-> **Key Advice**: Always start with good defaults and iteratively optimize <-

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

-> [kubectl get ns] <-

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

-> **Challenge**: How do you deploy AI models with GPU acceleration in containers? <-
-> **Solution**: Kubernetes GPU resource allocation and namespace isolation <-

---

-> # Thank You! <-

-> Questions? <-

