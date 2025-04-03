%title: The Path to Containers: A Hardware Evolution Story
%author: CU Boulder Computer Science
%date: April 2, 2025

-> # The Path to Containers <-
-> *A Hardware Evolution Story* <-

---

# ERA 1: The Client-Server Days (1995-1999)

* **Hardware**: Physical servers (souped-up PCs on racks)
  * **CPU**: Single-core Pentium II/III at 300-450 MHz
  * **RAM**: 128MB to 512MB
  * **Storage**: Single-digit gigabytes
  * **Network**: 10/100 Mbps Ethernet

* **Deployment Model**:
  * One application per physical server
  * Provisioning time: Days to weeks
  * Utilization: Mere 5-15%
  * Power usage: ~100-200W per server

-> *"This setup actually worked pretty well for the time!"* <-

---

# ERA 2: The Virtualization Revolution (2005-2010)

* **Hardware Leaps Forward**:
  * **CPU**: Dual/Quad-core Xeon processors at 2-3 GHz
  * **RAM**: 4GB to 32GB
  * **Storage**: Hundreds of gigabytes
  * **Network**: 1 Gbps Ethernet (10 Gbps in high-end datacenters)

* **The Utilization Problem**:
  * Powerful servers idling most of the time
  * Expensive machines running at 10-15% capacity
  * A massive waste of computing resources

* **Enter VMware**:
  * Multiple virtual machines on one physical server
  * Each VM thinks it has dedicated hardware
  * 5-15 VMs per physical server
  * Utilization improved to 15-30%

---

# ERA 3: The Container Era (2015 onwards)

* **Hardware Evolution (2015-2020)**:
  * **CPU**: 32-64 cores across multiple sockets
  * **RAM**: 256GB to 512GB configurations
  * **Storage**: Terabytes, with SSDs becoming the norm
  * **Network**: 10-40 Gbps standard

* **Current Era Hardware (2025)**:
  * **CPU**: AMD EPYC Genoa X / Intel Xeon 6 (192-256 cores)
  * **RAM**: 4-8 terabytes of DDR5 @ 6400 MT/s
  * **Storage**: Multiple NVMe drives, 100GB/s throughput
  * **Network**: 400 Gbps standard, 800 Gbps emerging

* **Specialized Hardware (2022-2025)**:
  * Multiple NVIDIA H200 / AMD MI300 GPUs
  * 150+ GB HBM3e memory per GPU
  * TPUs and custom ASICs
  * Significantly better performance/watt ratio

---

# ERA 3: The VM Limitation & Container Solution

* **VM Limitations**:
  * Each needs its own OS and dedicated memory
  * Startup time: Minutes
  * Still not maximizing utilization

* **Containers to the Rescue**:
  * Virtualize just the application environment
  * Share the same OS kernel
  * Hundreds of containers per server
  * Startup time: Seconds instead of minutes
  * Resource overhead: Dramatically reduced

---

# ERA 3: Modern K8s Deployments (Current)

* **Combining Technologies**:
  -> *"We didn't actually replace VMs with containers. We combined them."* <-
  * Layers: Physical hardware → VMs/K8s nodes → Containers

* **Multi-tenant Infrastructure**:
  * Multiple K8s clusters sharing physical infrastructure
  * One physical server runs VMs belonging to different clusters
  * Containers from different applications/teams/companies
  * All sharing underlying hardware
  * Utilization: 60-80%

---

# Computing Hardware Evolution - The Big Picture

* **1990s → 2000s Transformation**:
  * ~10x increase in processing power
  * ~50x increase in memory
  * ~50x increase in storage

* **2000s → 2025 Transformation**:
  * ~30x increase in cores
  * ~250x increase in memory
  * ~1000x increase in storage throughput

* **Overall Evolution (1990s → 2025)**:
  * ~300x increase in cores
  * ~12,500x increase in memory
  * ~50,000x increase in storage throughput

---

# Deployment Model Evolution

| Era | Years | Model | Provisioning | Utilization |
|-----|-------|-------|-------------|-------------|
| ERA 1 | 1995-1999 | One app per server | Days/weeks | 5-15% |
| ERA 2 | 2005-2010 | 5-15 VMs per server | Hours/days | 15-30% |
| ERA 3 | 2015-2025 | Hundreds of containers | Seconds/minutes | 60-80% |

---

-> # The Full Journey <-

-> From physical servers @ 15% capacity <-
-> To VMs improving to 30% <-
-> To containers on VMs reaching 60-80% <-

---

-> # Thank You! <-

-> Questions? <-
