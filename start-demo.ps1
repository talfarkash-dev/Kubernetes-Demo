# =============================================================================
# Kubernetes Demo - Quick Start
# Run this daily to start your demo
# First time? Run setup.ps1 first!
# =============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$header = @'

==================================================
   Kubernetes Demo - Quick Start
==================================================

'@
Write-Host $header -ForegroundColor Cyan

# =============================================================================
# Step 1: Check Minikube
# =============================================================================
Write-Host "[1/6] Checking Minikube..." -ForegroundColor Yellow

$status = minikube status 2>&1 | Out-String

if ($status -notmatch "Running") {
    $error_msg = @'

ERROR: Minikube is not running!

First time setup? Run: .\setup.ps1
Just stopped? Run: minikube start

'@
    Write-Host $error_msg -ForegroundColor Red
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
# Step 6: Start service tunnels in separate windows
# =============================================================================
Write-Host ""
Write-Host "[6/6] Starting service tunnels..." -ForegroundColor Yellow

# Stop any existing tunnels
Get-Process | Where-Object {$_.ProcessName -eq "kubectl"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Start backend tunnel in new window
Write-Host "      Starting backend tunnel..." -ForegroundColor Gray
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'Backend Tunnel - Keep this window open!' -ForegroundColor Cyan; Write-Host ''; minikube service flask-app-service"

Start-Sleep -Seconds 3

# Start frontend tunnel in new window
Write-Host "      Starting frontend tunnel..." -ForegroundColor Gray
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host 'Frontend Tunnel - Keep this window open!' -ForegroundColor Cyan; Write-Host ''; minikube service frontend-service"

Start-Sleep -Seconds 5

# Get URLs
Write-Host ""
Write-Host "      Getting service URLs..." -ForegroundColor Gray
$backend_url = minikube service flask-app-service --url 2>&1 | Select-String -Pattern "http://" | ForEach-Object { $_.Line }
$frontend_url = minikube service frontend-service --url 2>&1 | Select-String -Pattern "http://" | ForEach-Object { $_.Line }

Write-Host "      Tunnels started" -ForegroundColor Green

# =============================================================================
# Success
# =============================================================================
$success_msg = @"

==================================================
   Demo Ready!
==================================================

Frontend:  $frontend_url
Backend:   $backend_url

Two tunnel windows opened - KEEP THEM OPEN during demo!

Useful commands:
  kubectl get pods -w         # Watch pods
  kubectl get hpa -w          # Watch auto-scaling
  kubectl top pods            # Check CPU usage
  .\check-metrics.ps1         # Verify metrics
  .\stop-demo.ps1             # Stop demo

"@

Write-Host $success_msg -ForegroundColor Green

Write-Host "Opening frontend in browser..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
Start-Process $frontend_url

Write-Host ""
Write-Host "IMPORTANT: Keep the two tunnel windows open!" -ForegroundColor Red
Write-Host "Close them to stop, or run: .\stop-demo.ps1" -ForegroundColor Yellow
Write-Host ""