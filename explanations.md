# Kubernetes Demo - Complete Documentation

**Version:** 1.0
**Date:** November 2024
**Author:** Technical Documentation

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Architecture Overview](#architecture-overview)
3. [Component Breakdown](#component-breakdown)
4. [Network Flow](#network-flow)
5. [Key Kubernetes Concepts](#key-kubernetes-concepts)
6. [Demo Features](#demo-features)
7. [Technical Specifications](#technical-specifications)
8. [Setup and Usage](#setup-and-usage)

---

## Executive Summary

This Kubernetes demo demonstrates core container orchestration concepts including:
- **Load Balancing** - Traffic distribution across multiple backend instances
- **Auto-Scaling** - Automatic scaling based on CPU usage
- **Service Discovery** - Service-to-service communication
- **Self-Healing** - Automatic pod recovery

**Technology Stack:**
- Frontend: HTML/CSS/JavaScript (Nginx)
- Backend: Python Flask API
- Container Runtime: Docker
- Orchestration: Kubernetes (Minikube)
- Operating System: Windows 11

---

## Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Windows Host Machine                      │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Docker Desktop (Container Runtime)             │ │
│  │                                                              │ │
│  │  ┌────────────────────────────────────────────────────┐    │ │
│  │  │          Minikube Container                        │    │ │
│  │  │          (Single-Node Kubernetes Cluster)          │    │ │
│  │  │                                                     │    │ │
│  │  │  ┌──────────────────────────────────────────────┐ │    │ │
│  │  │  │      Kubernetes Control Plane                │ │    │ │
│  │  │  │  - API Server                                │ │    │ │
│  │  │  │  - Scheduler                                 │ │    │ │
│  │  │  │  - Controller Manager                        │ │    │ │
│  │  │  │  - etcd (State Storage)                      │ │    │ │
│  │  │  └──────────────────────────────────────────────┘ │    │ │
│  │  │                                                     │    │ │
│  │  │  ┌──────────────────────────────────────────────┐ │    │ │
│  │  │  │      Application Pods (Worker Node)         │ │    │ │
│  │  │  │                                              │ │    │ │
│  │  │  │  Backend Pods (Flask API):                  │ │    │ │
│  │  │  │  ┌─────────────┐  ┌─────────────┐          │ │    │ │
│  │  │  │  │ Backend     │  │ Backend     │          │ │    │ │
│  │  │  │  │ Pod 1       │  │ Pod 2       │          │ │    │ │
│  │  │  │  │ Port: 5000  │  │ Port: 5000  │ ...      │ │    │ │
│  │  │  │  └─────────────┘  └─────────────┘          │ │    │ │
│  │  │  │         ▲                 ▲                  │ │    │ │
│  │  │  │         └────────┬────────┘                 │ │    │ │
│  │  │  │                  │                           │ │    │ │
│  │  │  │  ┌───────────────▼──────────────┐           │ │    │ │
│  │  │  │  │  flask-app-service           │           │ │    │ │
│  │  │  │  │  Type: ClusterIP             │           │ │    │ │
│  │  │  │  │  Port: 80 → Target: 5000     │           │ │    │ │
│  │  │  │  │  (Internal Load Balancer)    │           │ │    │ │
│  │  │  │  └──────────────────────────────┘           │ │    │ │
│  │  │  │                                              │ │    │ │
│  │  │  │  Frontend Pod (Nginx):                      │ │    │ │
│  │  │  │  ┌─────────────────────────────┐            │ │    │ │
│  │  │  │  │ Frontend Pod                │            │ │    │ │
│  │  │  │  │ Port: 80                    │            │ │    │ │
│  │  │  │  │ Nginx + Static HTML/JS      │            │ │    │ │
│  │  │  │  └─────────────────────────────┘            │ │    │ │
│  │  │  │         ▲                                    │ │    │ │
│  │  │  │         │                                    │ │    │ │
│  │  │  │  ┌──────▼───────────────────┐               │ │    │ │
│  │  │  │  │  frontend-service        │               │ │    │ │
│  │  │  │  │  Type: NodePort          │               │ │    │ │
│  │  │  │  │  Port: 80                │               │ │    │ │
│  │  │  │  │  NodePort: 30081         │               │ │    │ │
│  │  │  │  └──────────────────────────┘               │ │    │ │
│  │  │  │                                              │ │    │ │
│  │  │  │  ┌──────────────────────────────────────┐   │ │    │ │
│  │  │  │  │  Horizontal Pod Autoscaler (HPA)    │   │ │    │ │
│  │  │  │  │  Monitors: CPU/Memory Usage         │   │ │    │ │
│  │  │  │  │  Min Replicas: 2                    │   │ │    │ │
│  │  │  │  │  Max Replicas: 10                   │   │ │    │ │
│  │  │  │  │  Target: 70% CPU                    │   │ │    │ │
│  │  │  │  └──────────────────────────────────────┘   │ │    │ │
│  │  │  └──────────────────────────────────────────────┘ │    │ │
│  │  └─────────────────────────────────────────────────────┘    │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              Port Forwarding Layer                       │   │
│  │  localhost:8080 ────► flask-app-service:80              │   │
│  │  localhost:8081 ────► frontend-service:80               │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              User's Web Browser                          │   │
│  │  http://localhost:8081 (Frontend UI)                    │   │
│  │  http://localhost:8080 (Backend API)                    │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component Breakdown

### 1. Docker Desktop Layer

```
┌─────────────────────────────────────┐
│       Docker Desktop                │
│  - Container Runtime Engine         │
│  - Manages Container Lifecycle      │
│  - Provides Networking              │
│  - Shows: 1 Container (Minikube)    │
└─────────────────────────────────────┘
```

**Purpose:** Provides the container runtime environment where Minikube runs.

**What You See:** Only the Minikube container is visible in Docker Desktop.

**Why:** Kubernetes manages its own containers internally; they don't appear in Docker Desktop's container list.

---

### 2. Minikube Container Layer

```
┌─────────────────────────────────────────┐
│         Minikube Container              │
│  - Single-Node Kubernetes Cluster      │
│  - Contains Control Plane + Worker     │
│  - Runs as a Docker Container          │
│  - IP: 192.168.49.2 (typical)          │
└─────────────────────────────────────────┘
```

**Purpose:** Provides a complete Kubernetes cluster for local development.

**Components:**
- Kubernetes API Server
- Scheduler
- Controller Manager
- etcd (cluster state database)
- Container Runtime (containerd)

---

### 3. Backend Pods

```
┌─────────────────────────────────────────┐
│        Backend Pod Architecture         │
│                                         │
│  Pod 1:                                 │
│  ┌─────────────────────────────────┐   │
│  │ Container: flask-k8s-app        │   │
│  │ Image: flask-k8s-app:latest     │   │
│  │ Port: 5000                       │   │
│  │ Resources:                       │   │
│  │   CPU: 100m-250m                │   │
│  │   Memory: 64Mi-128Mi            │   │
│  │ Environment:                     │   │
│  │   APP_VERSION=1.0               │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Replicas: 2-10 (dynamic via HPA)      │
│  Each pod is identical but isolated    │
└─────────────────────────────────────────┘
```

**Endpoints:**
- `GET /` - Home endpoint with pod info
- `GET /health` - Health check endpoint
- `GET /info` - Pod information endpoint
- `GET /cpu-load` - CPU-intensive endpoint (for demo)

**Container Details:**
- Base Image: `python:3.11-slim`
- Runtime: Gunicorn with 2 workers
- Language: Python 3.11
- Framework: Flask 3.0.0

---

### 4. Frontend Pod

```
┌─────────────────────────────────────────┐
│        Frontend Pod Architecture        │
│                                         │
│  Pod:                                   │
│  ┌─────────────────────────────────┐   │
│  │ Container: k8s-demo-frontend    │   │
│  │ Image: k8s-demo-frontend:latest │   │
│  │ Port: 80                         │   │
│  │ Resources:                       │   │
│  │   CPU: 100m-250m                │   │
│  │   Memory: 64Mi-128Mi            │   │
│  │ Web Server: Nginx Alpine        │   │
│  │ Content: Single HTML file       │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Replicas: 1 (static)                  │
└─────────────────────────────────────────┘
```

**Content:**
- Single HTML file with embedded CSS and JavaScript
- Interactive UI with buttons
- Real-time statistics display
- Response history tracking

**Container Details:**
- Base Image: `nginx:alpine`
- Web Server: Nginx
- Content Type: Static HTML/CSS/JavaScript

---

### 5. Services

#### Backend Service (ClusterIP)

```
┌─────────────────────────────────────────────┐
│      flask-app-service (ClusterIP)         │
│                                             │
│  Type: ClusterIP (Internal Only)           │
│  Cluster IP: 10.96.x.x (auto-assigned)     │
│  Port: 80                                   │
│  Target Port: 5000 (container port)        │
│  Selector: app=flask-app                   │
│                                             │
│  Function: Load Balancer                   │
│  ┌─────────────────────────────────────┐   │
│  │  Incoming Request                   │   │
│  │         ▼                            │   │
│  │  ┌─────────────┐                    │   │
│  │  │   Service   │                    │   │
│  │  │ (Selects    │                    │   │
│  │  │  Pod)       │                    │   │
│  │  └──────┬──────┘                    │   │
│  │         │                            │   │
│  │    ┌────┴─────┬──────┬──────┐       │   │
│  │    ▼          ▼      ▼      ▼       │   │
│  │  Pod 1     Pod 2  Pod 3  Pod 4      │   │
│  │  (25%)     (25%)  (25%)  (25%)      │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  Load Balancing Algorithm: Round-robin     │
└─────────────────────────────────────────────┘
```

**Purpose:**
- Provides stable endpoint for backend pods
- Load balances traffic across all backend pods
- Service discovery (accessible by name: `flask-app-service`)

#### Frontend Service (NodePort)

```
┌─────────────────────────────────────────────┐
│     frontend-service (NodePort)            │
│                                             │
│  Type: NodePort (External Access)          │
│  Cluster IP: 10.96.x.x                     │
│  Port: 80                                   │
│  Target Port: 80 (container port)          │
│  NodePort: 30081 (external port)           │
│  Selector: app=frontend                    │
│                                             │
│  Access Methods:                            │
│  1. Via Port Forward: localhost:8081       │
│  2. Via Minikube IP: 192.168.49.2:30081    │
│  3. Via Minikube Service: Auto URL         │
└─────────────────────────────────────────────┘
```

**Purpose:**
- Exposes frontend to external access
- Routes traffic to frontend pod
- Provides stable endpoint for users

---

### 6. Horizontal Pod Autoscaler (HPA)

```
┌──────────────────────────────────────────────────────────────┐
│              Horizontal Pod Autoscaler (HPA)                 │
│                                                              │
│  Target: flask-app-deployment                               │
│  Min Replicas: 2                                            │
│  Max Replicas: 10                                           │
│                                                              │
│  Metrics:                                                    │
│  ┌────────────────────────────────────────────────────┐     │
│  │ CPU Utilization Target: 70%                       │     │
│  │ Memory Utilization Target: 80%                    │     │
│  └────────────────────────────────────────────────────┘     │
│                                                              │
│  Scaling Behavior:                                          │
│  ┌────────────────────────────────────────────────────┐     │
│  │ Scale Up:                                         │     │
│  │   - Immediate (0s stabilization)                  │     │
│  │   - Can double pods at once (100%)                │     │
│  │   - Or add 2 pods at once                         │     │
│  │   - Uses more aggressive policy                   │     │
│  │                                                    │     │
│  │ Scale Down:                                        │     │
│  │   - Wait 60s before scaling down                  │     │
│  │   - Remove max 50% of pods at once                │     │
│  │   - Prevents flapping                             │     │
│  └────────────────────────────────────────────────────┘     │
│                                                              │
│  Monitoring Interval: Every 15 seconds                      │
│  Data Source: metrics-server                                │
└──────────────────────────────────────────────────────────────┘
```

**How It Works:**

```
Step 1: Monitor
   HPA checks CPU/Memory every 15s
   ↓
Step 2: Calculate
   Current Usage > Target? → Scale Up
   Current Usage < Target? → Scale Down
   ↓
Step 3: Scale
   Create/Delete pods as needed
   ↓
Step 4: Wait
   Scale up: Immediate
   Scale down: Wait 60s
```

**Example Scenario:**

```
Time 0:00  - 2 pods running, 20% CPU each
Time 0:30  - Load spike! 90% CPU each
Time 0:45  - HPA detects high CPU (>70%)
Time 0:46  - HPA creates 2 new pods (doubled)
Time 1:00  - 4 pods running, 45% CPU each
Time 2:00  - Load decreases to 30% CPU
Time 2:00  - HPA detects low CPU (<70%)
Time 3:00  - Wait 60s stabilization period
Time 3:01  - HPA removes 2 pods (back to 2)
Time 3:05  - 2 pods running, 60% CPU each
```

---

## Network Flow

### User Request Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Complete Request Flow                     │
└─────────────────────────────────────────────────────────────┘

1. User clicks "Simple Request" button in browser
   ↓
2. JavaScript sends HTTP GET to localhost:8080/info
   ↓
3. Port Forward routes to Minikube → flask-app-service:80
   ↓
4. Service selects one backend pod (load balancing)
   ↓
5. Request reaches Flask container in selected pod
   ↓
6. Flask processes request, returns JSON:
   {
     "hostname": "flask-app-deployment-abc123",
     "version": "1.0",
     "pod_ip": "10.244.0.5"
   }
   ↓
7. Response travels back through:
   Pod → Service → Port Forward → Browser
   ↓
8. JavaScript updates UI with pod hostname
   ↓
9. User sees which pod responded (load balancing visible!)
```

---

### Load Balancing in Action

```
Scenario: User clicks "Simple Request" 10 times

Request 1 → Service → Pod 1 (hostname: abc123)
Request 2 → Service → Pod 2 (hostname: def456)
Request 3 → Service → Pod 3 (hostname: ghi789)
Request 4 → Service → Pod 1 (hostname: abc123)
Request 5 → Service → Pod 2 (hostname: def456)
Request 6 → Service → Pod 3 (hostname: ghi789)
Request 7 → Service → Pod 1 (hostname: abc123)
Request 8 → Service → Pod 2 (hostname: def456)
Request 9 → Service → Pod 3 (hostname: ghi789)
Request 10 → Service → Pod 1 (hostname: abc123)

Result: Traffic evenly distributed
Pod 1: 4 requests (40%)
Pod 2: 3 requests (30%)
Pod 3: 3 requests (30%)
```

---

### Auto-Scaling Flow

```
┌─────────────────────────────────────────────────────────────┐
│           Auto-Scaling Trigger Flow                         │
└─────────────────────────────────────────────────────────────┘

1. User clicks "Trigger CPU Load (10x)" button
   ↓
2. Frontend sends 10 simultaneous CPU-intensive requests
   ↓
3. Requests distributed across current pods (2 pods)
   Each pod receives ~5 requests
   ↓
4. Each request performs heavy computation:
   result = sum(i * i for i in range(10,000,000))
   ↓
5. CPU spikes to 85-95% on all pods
   ↓
6. HPA monitors metrics (every 15s)
   Detects: Current CPU (90%) > Target (70%)
   ↓
7. HPA calculates needed replicas:
   Desired = Current * (CurrentUsage / TargetUsage)
   Desired = 2 * (90 / 70) = 2.57 ≈ 3 pods
   But HPA can double, so creates 4 pods total
   ↓
8. Kubernetes creates 2 new pods
   ├─ Schedules pods on available nodes
   ├─ Pulls images (if needed)
   ├─ Starts containers
   └─ Waits for readiness probes
   ↓
9. New pods become ready (~10-20 seconds)
   ↓
10. Service automatically includes new pods
    Load is now distributed across 4 pods
    ↓
11. CPU per pod drops:
    Before: 90% on 2 pods
    After: 45% on 4 pods
    ↓
12. HPA is satisfied (45% < 70%)
    ↓
13. After load decreases (60s stabilization):
    HPA scales back down to 2 pods
```

---

## Key Kubernetes Concepts

### Pods

```
┌─────────────────────────────────────────┐
│            Pod Concept                  │
├─────────────────────────────────────────┤
│  - Smallest deployable unit             │
│  - Can contain 1+ containers            │
│  - Shares network namespace             │
│  - Shares storage volumes                │
│  - Has unique IP address                │
│  - Ephemeral (can be deleted/recreated) │
│                                         │
│  Example:                                │
│  ┌─────────────────────────────────┐   │
│  │ Pod: flask-app-deployment-abc   │   │
│  │ ┌─────────────────────────────┐ │   │
│  │ │ Container: flask-app        │ │   │
│  │ │ Image: flask-k8s-app:latest │ │   │
│  │ │ Port: 5000                   │ │   │
│  │ │ CPU: 5%                      │ │   │
│  │ │ Memory: 45Mi                 │ │   │
│  │ └─────────────────────────────┘ │   │
│  │ IP: 10.244.0.5                  │   │
│  │ Node: minikube                  │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

---

### Deployments

```
┌─────────────────────────────────────────────────────────┐
│              Deployment Concept                         │
├─────────────────────────────────────────────────────────┤
│  Purpose: Manages pod lifecycle                         │
│                                                          │
│  Desired State: 3 replicas                              │
│  Current State: 3 replicas                              │
│                                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │         Deployment Controller                   │   │
│  │                                                  │   │
│  │  Monitors: Desired State vs Current State       │   │
│  │                                                  │   │
│  │  Actions:                                        │   │
│  │  - Creates pods if < desired                    │   │
│  │  - Deletes pods if > desired                    │   │
│  │  - Replaces unhealthy pods                      │   │
│  │  - Manages rolling updates                      │   │
│  └─────────────────────────────────────────────────┘   │
│                                                          │
│  Self-Healing Example:                                  │
│  1. Pod crashes                                         │
│  2. Deployment detects: 2/3 pods running               │
│  3. Deployment creates new pod                         │
│  4. New pod starts                                      │
│  5. Back to 3/3 pods running                           │
│                                                          │
│  Total time: ~10-20 seconds                             │
└─────────────────────────────────────────────────────────┘
```

---

### Services

```
┌───────────────────────────────────────────────────────────┐
│                Service Concept                            │
├───────────────────────────────────────────────────────────┤
│  Problem: Pods have dynamic IPs (change on restart)      │
│  Solution: Service provides stable endpoint               │
│                                                            │
│  ┌────────────────────────────────────────────────────┐  │
│  │             Service                                │  │
│  │  Name: flask-app-service                          │  │
│  │  IP: 10.96.123.45 (never changes)                │  │
│  │  Port: 80                                          │  │
│  │                                                     │  │
│  │  Selector: app=flask-app                          │  │
│  │  ↓                                                  │  │
│  │  Finds all pods with label: app=flask-app         │  │
│  │  ↓                                                  │  │
│  │  Current Endpoints:                                │  │
│  │  - 10.244.0.5:5000 (Pod 1)                        │  │
│  │  - 10.244.0.6:5000 (Pod 2)                        │  │
│  │  - 10.244.0.7:5000 (Pod 3)                        │  │
│  │                                                     │  │
│  │  Load Balancing: Round-robin                       │  │
│  └────────────────────────────────────────────────────┘  │
│                                                            │
│  Benefits:                                                 │
│  - Stable DNS name (flask-app-service)                    │
│  - Automatic load balancing                               │
│  - Service discovery                                       │
│  - Health tracking (only routes to healthy pods)         │
└───────────────────────────────────────────────────────────┘
```

---

### ReplicaSets

```
┌─────────────────────────────────────────────────────────┐
│            ReplicaSet Concept                           │
├─────────────────────────────────────────────────────────┤
│  Created by: Deployment                                 │
│  Purpose: Maintains exact number of pod replicas        │
│                                                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │     ReplicaSet Controller                       │   │
│  │                                                  │   │
│  │  Desired Replicas: 3                            │   │
│  │  Current Replicas: 3                            │   │
│  │  Ready Replicas: 3                              │   │
│  │                                                  │   │
│  │  Managed Pods:                                   │   │
│  │  ├─ flask-app-deployment-abc123 (Running)       │   │
│  │  ├─ flask-app-deployment-def456 (Running)       │   │
│  │  └─ flask-app-deployment-ghi789 (Running)       │   │
│  └─────────────────────────────────────────────────┘   │
│                                                          │
│  Relationship:                                           │
│  Deployment → creates → ReplicaSet → creates → Pods     │
│                                                          │
│  You typically don't manage ReplicaSets directly        │
└─────────────────────────────────────────────────────────┘
```

---

## Demo Features

### Feature 1: Load Balancing

**What it demonstrates:**
- Service distributes traffic across multiple backend pods
- Each request may hit a different pod
- Load is balanced automatically

**How to see it:**
1. Click "Simple Request" button 10 times
2. Observe different pod hostnames in response history
3. Check "Unique Pods" counter increasing
4. Notice even distribution of requests

**Behind the scenes:**
```
User Request
   ↓
frontend-service (port 8081)
   ↓
Frontend Pod
   ↓
JavaScript makes API call
   ↓
localhost:8080 (port forward)
   ↓
flask-app-service
   ↓
[Load Balancer selects pod]
   ↓
Pod 1, 2, or 3 (round-robin)
   ↓
Response with unique hostname
   ↓
User sees which pod responded
```

---

### Feature 2: Horizontal Auto-Scaling

**What it demonstrates:**
- Kubernetes automatically scales pods based on CPU usage
- Pods are added when load increases
- Pods are removed when load decreases
- Scaling happens without manual intervention

**How to see it:**

1. **Before load:**
   ```bash
   kubectl get pods
   # Shows: 2-3 pods running

   kubectl get hpa
   # Shows: CPU at ~10-20%
   ```

2. **Trigger load:**
   - Click "Trigger CPU Load (10x)" button
   - This sends 10 CPU-intensive requests simultaneously

3. **During load:**
   ```bash
   kubectl get hpa -w
   # Watch CPU spike to 85-95%
   # Watch replicas increase: 2 → 4 → 6

   kubectl get pods -w
   # Watch new pods being created
   # Status: ContainerCreating → Running
   ```

4. **After load:**
   ```bash
   # Wait 1-2 minutes
   kubectl get hpa
   # Watch CPU drop back down
   # Watch replicas decrease back to 2-3
   ```

**Timeline:**
```
T+0s:   User clicks button
T+1s:   CPU spikes to 90%
T+15s:  HPA detects high CPU
T+16s:  HPA creates 2 new pods
T+25s:  New pods become ready
T+26s:  Service starts routing to 4 pods
T+30s:  CPU drops to 45%
T+90s:  After stabilization, HPA removes extra pods
T+95s:  Back to 2 pods
```

---

### Feature 3: Service Discovery

**What it demonstrates:**
- Services can be accessed by name, not IP
- Frontend finds backend using service name
- DNS-based service discovery

**Implementation:**
```javascript
// Frontend code
const BACKEND_URL = 'http://localhost:8080';

// This is port-forwarded to:
// flask-app-service:80 (inside cluster)

// Kubernetes DNS resolution:
// flask-app-service → 10.96.x.x (ClusterIP)
```

**Benefits:**
- No hardcoded IPs
- Services can move, pods can restart
- Frontend doesn't need to track backend locations

---

### Feature 4: Self-Healing

**What it demonstrates:**
- Kubernetes automatically restarts failed pods
- Maintains desired state without manual intervention
- System continues working during pod failures

**How to see it:**

1. **Get pod name:**
   ```bash
   kubectl get pods
   # Pick any backend pod name
   ```

2. **Delete a pod:**
   ```bash
   kubectl delete pod flask-app-deployment-abc123
   ```

3. **Watch self-healing:**
   ```bash
   kubectl get pods -w
   # Observe:
   # 1. Pod enters "Terminating" state
   # 2. New pod immediately created
   # 3. New pod: Pending → ContainerCreating → Running
   # 4. Total time: ~10-20 seconds
   ```

4. **Test during healing:**
   - Click "Simple Request" during pod recreation
   - Service continues working
   - Traffic routes to remaining healthy pods
   - No downtime!

**Self-Healing Process:**
```
Step 1: Pod Crash/Delete
   ↓
Step 2: ReplicaSet detects: 2/3 pods (desired: 3)
   ↓
Step 3: ReplicaSet creates new pod
   ↓
Step 4: Scheduler assigns pod to node
   ↓
Step 5: Container runtime pulls image (if needed)
   ↓
Step 6: Container starts
   ↓
Step 7: Readiness probe passes
   ↓
Step 8: Service adds pod to endpoint list
   ↓
Step 9: Back to 3/3 pods running
```

---

## Technical Specifications

### Resource Requirements

**Backend Pod:**
```yaml
resources:
  requests:
    memory: "64Mi"    # Minimum guaranteed
    cpu: "100m"       # 0.1 CPU cores
  limits:
    memory: "128Mi"   # Maximum allowed
    cpu: "250m"       # 0.25 CPU cores
```

**Frontend Pod:**
```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "100m"
  limits:
    memory: "128Mi"
    cpu: "250m"
```

**Total Cluster Resources (3 backend + 1 frontend):**
- CPU Request: 400m (0.4 cores)
- CPU Limit: 1000m (1 core)
- Memory Request: 256Mi
- Memory Limit: 512Mi

---

### Network Specifications

**Service Ports:**
```
Frontend Service:
  Type: NodePort
  ClusterIP Port: 80
  NodePort: 30081
  Target Port: 80 (container)

Backend Service:
  Type: ClusterIP
  ClusterIP Port: 80
  Target Port: 5000 (container)
```

**Port Forwarding:**
```
User Access:
  localhost:8081 → frontend-service:80 → Frontend Pod:80
  localhost:8080 → flask-app-service:80 → Backend Pod:5000
```

---

### Health Checks

**Backend Liveness Probe:**
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 5000
  initialDelaySeconds: 10  # Wait 10s after start
  periodSeconds: 10        # Check every 10s
  failureThreshold: 3      # Restart after 3 failures
```

**Backend Readiness Probe:**
```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 5000
  initialDelaySeconds: 5   # Wait 5s after start
  periodSeconds: 5         # Check every 5s
  failureThreshold: 2      # Remove from service after 2 failures
```

**Difference:**
- **Liveness**: Is the container alive? (If not, restart it)
- **Readiness**: Is the container ready for traffic? (If not, remove from service)

---

### Scaling Metrics

**HPA Configuration:**
```yaml
metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70%

  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80%
```

**Scaling Calculation:**
```
Desired Replicas = Current Replicas × (Current Metric / Target Metric)

Example:
  Current: 2 pods at 90% CPU
  Target: 70% CPU

  Desired = 2 × (90 / 70)
  Desired = 2 × 1.29
  Desired = 2.57 ≈ 3 pods

  HPA creates 1 new pod
```

---

## Setup and Usage

### Prerequisites

- Windows 11
- Docker Desktop (running)
- Minikube
- kubectl

### Quick Start

**One-command launch:**
```powershell
.\start-demo.ps1
```

This script automatically:
1. Checks/starts Minikube
2. Enables metrics server
3. Configures Docker environment
4. Builds Docker images (if needed)
5. Deploys all Kubernetes resources
6. Sets up port forwarding (localhost:8080, localhost:8081)
7. Opens browser to frontend

**Access URLs:**
- Frontend: http://localhost:8081
- Backend: http://localhost:8080

### Monitoring

**Watch auto-scaling:**
```powershell
.\watch-demo.ps1
# Choose option 3 for both pods and HPA
```

**Manual monitoring:**
```powershell
# Watch pods
kubectl get pods -w

# Watch HPA
kubectl get hpa -w

# View logs
kubectl logs <pod-name>

# Describe pod
kubectl describe pod <pod-name>
```

### Stopping

```powershell
.\stop-demo.ps1
```

This will:
1. Stop port forwarding
2. Optionally delete Kubernetes resources
3. Optionally stop Minikube

---

## Project Structure

```
kub-test/
├── start-demo.ps1              # One-click launcher
├── stop-demo.ps1               # Cleanup script
├── watch-demo.ps1              # Monitoring script
├── README.md                   # Full documentation
├── QUICK-START.md              # Quick setup guide
│
├── backend/
│   ├── app.py                  # Flask API application
│   ├── requirements.txt        # Python dependencies
│   ├── Dockerfile              # Backend container definition
│   ├── deployment.yaml         # Backend Kubernetes deployment
│   ├── service.yaml            # Backend service definition
│   └── hpa.yaml                # Horizontal Pod Autoscaler config
│
└── frontend/
    ├── index.html              # Single-file frontend app
    ├── Dockerfile              # Frontend container definition
    ├── nginx.conf              # Nginx configuration
    ├── frontend-deployment.yaml # Frontend Kubernetes deployment
    └── frontend-service.yaml   # Frontend service definition
```

**Total Files:** 16 (3 scripts + 2 docs + 6 backend + 5 frontend)

---

## Conclusion

This Kubernetes demo provides a hands-on, interactive way to understand core container orchestration concepts:

**✅ What You Learned:**
1. **Pods** - The basic unit of deployment in Kubernetes
2. **Deployments** - Managing pod lifecycle and desired state
3. **Services** - Stable networking and load balancing
4. **Auto-Scaling** - Automatic resource adjustment based on load
5. **Self-Healing** - Automatic recovery from failures

**✅ Key Takeaways:**
- Kubernetes manages containers inside Minikube (you see 1 Docker container, but 4+ pods inside)
- Services provide stable endpoints and load balancing
- HPA automatically scales based on resource usage
- Deployments ensure desired state is maintained
- All components work together to provide a resilient, scalable system

**✅ Production Considerations:**
- In production, you'd use a multi-node cluster (not single-node Minikube)
- You'd use LoadBalancer services (not NodePort)
- You'd add monitoring (Prometheus, Grafana)
- You'd add logging (ELK stack, Loki)
- You'd use namespaces for isolation
- You'd implement security policies
- You'd use CI/CD for automated deployments

---

**End of Documentation**

Version: 1.0
Last Updated: November 2024