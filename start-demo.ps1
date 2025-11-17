# Set UTF-8 encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Kubernetes Demo - One-Click Launcher

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   Kubernetes Demo Launcher" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Check if Minikube is running
Write-Host "[1/7] Checking Minikube status..." -ForegroundColor Yellow
$status = minikube status 2>&1 | Out-String

if ($status -notmatch "Running") {
    Write-Host "      Minikube is not running. Starting..." -ForegroundColor Yellow
    minikube start --driver=docker

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "ERROR: Minikube failed to start!" -ForegroundColor Red
        Write-Host "Try running: minikube delete" -ForegroundColor Yellow
        Write-Host "Then run this script again" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "      Waiting for Kubernetes API..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10

    Write-Host "      Enabling metrics-server (for auto-scaling)..." -ForegroundColor Yellow
    minikube addons enable metrics-server 2>&1 | Out-Null
} else {
    Write-Host "      Minikube is running" -ForegroundColor Green
}

# Configure Docker environment
Write-Host ""
Write-Host "[2/7] Configuring Docker environment..." -ForegroundColor Yellow
& minikube -p minikube docker-env --shell powershell | Invoke-Expression
Write-Host "      Docker environment configured" -ForegroundColor Green

# Check and build images
Write-Host ""
Write-Host "[3/7] Checking Docker images..." -ForegroundColor Yellow
$backend_image = docker images flask-k8s-app:latest -q
$frontend_image = docker images k8s-demo-frontend:latest -q

if (-not $backend_image) {
    Write-Host "      Building backend image..." -ForegroundColor Yellow
    Push-Location backend
    docker build -t flask-k8s-app:latest . 2>&1 | Out-Null
    Pop-Location

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Backend build failed!" -ForegroundColor Red
        exit 1
    }
    Write-Host "      Backend image built" -ForegroundColor Green
} else {
    Write-Host "      Backend image exists" -ForegroundColor Green
}

if (-not $frontend_image) {
    Write-Host "      Building frontend image..." -ForegroundColor Yellow
    Push-Location frontend
    docker build -t k8s-demo-frontend:latest . 2>&1 | Out-Null
    Pop-Location

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Frontend build failed!" -ForegroundColor Red
        exit 1
    }
    Write-Host "      Frontend image built" -ForegroundColor Green
} else {
    Write-Host "      Frontend image exists" -ForegroundColor Green
}

# Deploy to Kubernetes
Write-Host ""
Write-Host "[4/7] Deploying to Kubernetes..." -ForegroundColor Yellow

kubectl apply -f backend/deployment.yaml 2>&1 | Out-Null
kubectl apply -f backend/service.yaml 2>&1 | Out-Null

# Only apply HPA if metrics-server is available
$metrics_server_ready = kubectl get deployment metrics-server -n kube-system 2>&1 | Out-String
if ($metrics_server_ready -match "metrics-server") {
    kubectl apply -f backend/hpa.yaml 2>&1 | Out-Null
    Write-Host "      Auto-scaling enabled" -ForegroundColor Green
} else {
    Write-Host "      Skipping auto-scaling (metrics-server not available)" -ForegroundColor Yellow
}

kubectl apply -f frontend/frontend-deployment.yaml 2>&1 | Out-Null
kubectl apply -f frontend/frontend-service.yaml 2>&1 | Out-Null

Write-Host "      Deployments created" -ForegroundColor Green

# Wait for pods to be ready
Write-Host ""
Write-Host "[5/7] Waiting for pods to start..." -ForegroundColor Yellow
Write-Host "      This may take 30-60 seconds..." -ForegroundColor Gray

$max_wait = 60
$waited = 0
while ($waited -lt $max_wait) {
    $backend_ready = kubectl get pods -l app=flask-app -o jsonpath='{.items[*].status.containerStatuses[0].ready}' 2>&1
    $frontend_ready = kubectl get pods -l app=frontend -o jsonpath='{.items[*].status.containerStatuses[0].ready}' 2>&1

    if ($backend_ready -match "true" -and $frontend_ready -match "true") {
        Write-Host "      Pods are ready!" -ForegroundColor Green
        break
    }

    Start-Sleep -Seconds 5
    $waited += 5
    Write-Host "      Still waiting... ($waited/$max_wait seconds)" -ForegroundColor Gray
}

# Show pod status
Write-Host ""
kubectl get pods
Write-Host ""

# Stop any existing port-forwards
Write-Host "[6/7] Setting up port forwarding..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -eq "kubectl"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Start port forwarding in background
Start-Process -WindowStyle Hidden powershell -ArgumentList "-Command", "kubectl port-forward service/flask-app-service 8080:5000"
Start-Process -WindowStyle Hidden powershell -ArgumentList "-Command", "kubectl port-forward service/frontend-service 8081:80"

Write-Host "      Waiting for port forwarding to initialize..." -ForegroundColor Gray
Start-Sleep -Seconds 5

# Test backend connectivity
Write-Host ""
Write-Host "[7/7] Testing backend connectivity..." -ForegroundColor Yellow
try {
    $test_response = Invoke-WebRequest -Uri "http://localhost:8080/health" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "      Backend is responding!" -ForegroundColor Green
} catch {
    Write-Host "      WARNING: Backend not responding yet" -ForegroundColor Yellow
    Write-Host "      Give it a few more seconds..." -ForegroundColor Yellow
}

# Success message
Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "   Demo is Ready!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Frontend:  http://localhost:8081" -ForegroundColor Cyan
Write-Host "Backend:   http://localhost:8080" -ForegroundColor Cyan
Write-Host ""
Write-Host "Opening browser in 3 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 3
Start-Process "http://localhost:8081"

Write-Host ""
Write-Host "Commands:" -ForegroundColor Yellow
Write-Host "  - Watch pods:  kubectl get pods -w" -ForegroundColor Gray
Write-Host "  - View logs:   kubectl logs -l app=flask-app --tail=50" -ForegroundColor Gray
Write-Host "  - Stop demo:   .\stop-demo.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Ctrl+C to stop port forwarding" -ForegroundColor Red
Write-Host ""

# Keep script running to maintain port forwarding
while ($true) {
    Start-Sleep -Seconds 10
}