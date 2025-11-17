# =============================================================================
# Kubernetes Demo - Quick Start
# Run this daily to start your demo
# First time? Run setup.ps1 first!
# =============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   Kubernetes Demo - Quick Start" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# =============================================================================
# Step 1: Check Minikube
# =============================================================================
Write-Host "[1/6] Checking Minikube..." -ForegroundColor Yellow

$status = minikube status 2>&1 | Out-String

if ($status -notmatch "Running") {
    Write-Host ""
    Write-Host "ERROR: Minikube is not running!" -ForegroundColor Red
    Write-Host ""
    Write-Host "First time setup? Run: .\setup.ps1" -ForegroundColor Yellow
    Write-Host "Just stopped? Run: minikube start" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "      Minikube is running" -ForegroundColor Green

# =============================================================================
# Step 2: Configure Docker
# =============================================================================
Write-Host ""
Write-Host "[2/6] Configuring Docker..." -ForegroundColor Yellow

& minikube -p minikube docker-env --shell powershell | Invoke-Expression
Write-Host "      Docker configured" -ForegroundColor Green

# =============================================================================
# Step 3: Check images (rebuild if missing)
# =============================================================================
Write-Host ""
Write-Host "[3/6] Checking images..." -ForegroundColor Yellow

$backend_image = docker images flask-k8s-app:latest -q
$frontend_image = docker images k8s-demo-frontend:latest -q

$rebuild_needed = $false

if (-not $backend_image) {
    Write-Host "      Backend image missing, rebuilding..." -ForegroundColor Yellow
    Push-Location backend
    docker build -t flask-k8s-app:latest . 2>&1 | Out-Null
    Pop-Location
    $rebuild_needed = $true
}

if (-not $frontend_image) {
    Write-Host "      Frontend image missing, rebuilding..." -ForegroundColor Yellow
    Push-Location frontend
    docker build -t k8s-demo-frontend:latest . 2>&1 | Out-Null
    Pop-Location
    $rebuild_needed = $true
}

if ($rebuild_needed) {
    Write-Host "      Images rebuilt" -ForegroundColor Green
} else {
    Write-Host "      Images ready" -ForegroundColor Green
}

# =============================================================================
# Step 4: Deploy to Kubernetes
# =============================================================================
Write-Host ""
Write-Host "[4/6] Deploying..." -ForegroundColor Yellow

kubectl apply -f backend/deployment.yaml 2>&1 | Out-Null
kubectl apply -f backend/service.yaml 2>&1 | Out-Null
kubectl apply -f backend/hpa.yaml 2>&1 | Out-Null
kubectl apply -f frontend/frontend-deployment.yaml 2>&1 | Out-Null
kubectl apply -f frontend/frontend-service.yaml 2>&1 | Out-Null

Write-Host "      Deployed" -ForegroundColor Green

# =============================================================================
# Step 5: Wait for pods
# =============================================================================
Write-Host ""
Write-Host "[5/6] Waiting for pods..." -ForegroundColor Yellow

$max_wait = 60
$waited = 0

while ($waited -lt $max_wait) {
    $backend_ready = kubectl get pods -l app=flask-app -o jsonpath='{.items[*].status.containerStatuses[0].ready}' 2>&1
    $frontend_ready = kubectl get pods -l app=frontend -o jsonpath='{.items[*].status.containerStatuses[0].ready}' 2>&1

    if ($backend_ready -match "true" -and $frontend_ready -match "true") {
        Write-Host "      Pods ready" -ForegroundColor Green
        break
    }

    Start-Sleep -Seconds 5
    $waited += 5
    Write-Host "      Still waiting... ($waited/$max_wait seconds)" -ForegroundColor Gray
}

Write-Host ""
kubectl get pods

# =============================================================================
# Step 6: Port forwarding
# =============================================================================
Write-Host ""
Write-Host "[6/6] Setting up port forwarding..." -ForegroundColor Yellow

# Stop any existing port-forwards
Get-Process | Where-Object {$_.ProcessName -eq "kubectl"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Start new port-forwards
Start-Process -WindowStyle Hidden powershell -ArgumentList "-Command", "kubectl port-forward service/flask-app-service 8080:5000"
Start-Process -WindowStyle Hidden powershell -ArgumentList "-Command", "kubectl port-forward service/frontend-service 8081:80"

Write-Host "      Port forwarding active" -ForegroundColor Green
Start-Sleep -Seconds 3

# Test backend
try {
    Invoke-WebRequest -Uri "http://localhost:8080/health" -TimeoutSec 5 -ErrorAction Stop | Out-Null
    Write-Host "      Backend responding" -ForegroundColor Green
} catch {
    Write-Host "      Backend starting (give it 5 more seconds)..." -ForegroundColor Yellow
}

# =============================================================================
# Success
# =============================================================================
Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "   Demo Ready!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Frontend:  http://localhost:8081" -ForegroundColor Cyan
Write-Host "Backend:   http://localhost:8080" -ForegroundColor Cyan
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Yellow
Write-Host "  kubectl get pods -w         # Watch pods" -ForegroundColor Gray
Write-Host "  kubectl get hpa -w          # Watch auto-scaling" -ForegroundColor Gray
Write-Host "  kubectl top pods            # Check CPU usage" -ForegroundColor Gray
Write-Host "  .\check-metrics.ps1         # Verify metrics" -ForegroundColor Gray
Write-Host "  .\stop-demo.ps1             # Stop demo" -ForegroundColor Gray
Write-Host ""

Start-Sleep -Seconds 2
Start-Process "http://localhost:8081"

Write-Host "Opening browser..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Ctrl+C to stop port forwarding" -ForegroundColor Red
Write-Host ""

# Keep running to maintain port forwarding
while ($true) {
    Start-Sleep -Seconds 10
}