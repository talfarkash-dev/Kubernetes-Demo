# =============================================================================
# Kubernetes Demo - One-Time Setup
# Run this ONCE after: minikube delete
# Then use start-demo.ps1 for daily demos
# =============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$header = @'

==================================================
   Kubernetes Demo - Initial Setup
==================================================

'@

Write-Host $header -ForegroundColor Cyan

$intro = @'
This will:
  1. Start Minikube fresh
  2. Wait for Kubernetes to be fully ready
  3. Install metrics-server for auto-scaling
  4. Build Docker images

Estimated time: 3-5 minutes

'@

Write-Host $intro -ForegroundColor Yellow

$continue = Read-Host "Continue? (y/n)"
if ($continue -ne "y") {
    Write-Host "Setup cancelled" -ForegroundColor Yellow
    exit 0
}

# =============================================================================
# Step 1: Start Minikube
# =============================================================================
Write-Host ""
Write-Host "[1/5] Starting Minikube..." -ForegroundColor Cyan
Write-Host "      This will take 1-2 minutes..." -ForegroundColor Gray
Write-Host ""

minikube start --driver=docker

if ($LASTEXITCODE -ne 0) {
    $error_msg = @'

ERROR: Minikube failed to start!

Troubleshooting:
  1. Make sure Docker Desktop is running
  2. Try: minikube delete
  3. Run this script again

'@
    Write-Host $error_msg -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "      Minikube started (storage errors are normal and harmless)" -ForegroundColor Green

# =============================================================================
# Step 2: Wait for Kubernetes API to be fully ready
# =============================================================================
Write-Host ""
Write-Host "[2/5] Waiting for Kubernetes API..." -ForegroundColor Cyan
Write-Host "      Giving the API server time to fully initialize..." -ForegroundColor Gray

$max_wait = 60
$waited = 0
$api_ready = $false

while ($waited -lt $max_wait) {
    $api_test = kubectl get nodes 2>&1 | Out-String

    if ($api_test -match "Ready") {
        $api_ready = $true
        break
    }

    Start-Sleep -Seconds 5
    $waited += 5
    Write-Host "      Still waiting... ($waited/$max_wait seconds)" -ForegroundColor Gray
}

if (-not $api_ready) {
    Write-Host ""
    Write-Host "ERROR: Kubernetes API did not become ready in time" -ForegroundColor Red
    Write-Host "Run: minikube status" -ForegroundColor Yellow
    exit 1
}

Write-Host "      Kubernetes API is ready" -ForegroundColor Green

# =============================================================================
# Step 3: Install metrics-server
# =============================================================================
Write-Host ""
Write-Host "[3/5] Installing metrics-server..." -ForegroundColor Cyan
Write-Host "      Downloading from GitHub..." -ForegroundColor Gray

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    $warning_msg = @'

WARNING: Failed to download metrics-server
Auto-scaling will not work, but basic demo will

'@
    Write-Host $warning_msg -ForegroundColor Yellow
} else {
    Write-Host "      Metrics-server manifest applied" -ForegroundColor Green

    Write-Host "      Patching for Minikube..." -ForegroundColor Gray
    Start-Sleep -Seconds 5

    $patch = @'
[
  {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"},
  {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-preferred-address-types=InternalIP"}
]
'@

    kubectl patch deployment metrics-server -n kube-system --type='json' -p=$patch 2>&1 | Out-Null

    Write-Host "      Metrics-server configured" -ForegroundColor Green
    Write-Host "      Waiting for metrics-server to start..." -ForegroundColor Gray

    Start-Sleep -Seconds 20

    $metrics_status = kubectl get pods -n kube-system -l k8s-app=metrics-server -o jsonpath='{.items[0].status.phase}' 2>&1
    if ($metrics_status -eq "Running") {
        Write-Host "      Metrics-server is running" -ForegroundColor Green
    } else {
        Write-Host "      Metrics-server is starting (will be ready soon)" -ForegroundColor Yellow
    }
}

# =============================================================================
# Step 4: Configure Docker environment
# =============================================================================
Write-Host ""
Write-Host "[4/5] Configuring Docker environment..." -ForegroundColor Cyan

& minikube -p minikube docker-env --shell powershell | Invoke-Expression

Write-Host "      Docker configured to use Minikube" -ForegroundColor Green

# =============================================================================
# Step 5: Build Docker images
# =============================================================================
Write-Host ""
Write-Host "[5/5] Building Docker images..." -ForegroundColor Cyan

# Check if directories exist
if (-not (Test-Path "backend")) {
    $error_backend = @'

ERROR: backend folder not found!
Make sure you are running this from the project root

'@
    Write-Host $error_backend -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "frontend")) {
    $error_frontend = @'

ERROR: frontend folder not found!
Make sure you are running this from the project root

'@
    Write-Host $error_frontend -ForegroundColor Red
    exit 1
}

# Build backend
Write-Host "      Building backend image..." -ForegroundColor Gray
Push-Location backend
docker build -t flask-k8s-app:latest . 2>&1 | Out-Null
$backend_result = $LASTEXITCODE
Pop-Location

if ($backend_result -ne 0) {
    $error_build = @'

ERROR: Backend build failed!
Check if backend/Dockerfile and backend/requirements.txt exist

'@
    Write-Host $error_build -ForegroundColor Red
    exit 1
}
Write-Host "      Backend image built" -ForegroundColor Green

# Build frontend
Write-Host "      Building frontend image..." -ForegroundColor Gray
Push-Location frontend
docker build -t k8s-demo-frontend:latest . 2>&1 | Out-Null
$frontend_result = $LASTEXITCODE
Pop-Location

if ($frontend_result -ne 0) {
    $error_frontend_build = @'

ERROR: Frontend build failed!
Check if frontend/Dockerfile and frontend/index.html exist

'@
    Write-Host $error_frontend_build -ForegroundColor Red
    exit 1
}
Write-Host "      Frontend image built" -ForegroundColor Green

# =============================================================================
# Final verification
# =============================================================================
$success_header = @'

==================================================
   Setup Complete!
==================================================

'@
Write-Host $success_header -ForegroundColor Green

Write-Host "Verifying setup..." -ForegroundColor Cyan
Write-Host ""

# Check Minikube
Write-Host "Minikube status:" -ForegroundColor Yellow
minikube status
Write-Host ""

# Check images
Write-Host "Docker images:" -ForegroundColor Yellow
docker images | Select-String -Pattern "flask-k8s-app|k8s-demo-frontend"
Write-Host ""

# Check metrics-server
Write-Host "Metrics-server status:" -ForegroundColor Yellow
$metrics_pod = kubectl get pods -n kube-system -l k8s-app=metrics-server 2>&1 | Out-String
if ($metrics_pod -match "Running") {
    Write-Host "  Metrics-server is running" -ForegroundColor Green
} else {
    Write-Host "  Metrics-server is starting (may take 1-2 more minutes)" -ForegroundColor Yellow
}
Write-Host ""

$final_msg = @'
==================================================

You are ready to run the demo!

Next steps:
  1. Run: .\start-demo.ps1
  2. Wait 1-2 minutes for metrics to populate
  3. Check metrics: .\check-metrics.ps1
  4. Open browser and test auto-scaling!

==================================================

'@

Write-Host $final_msg -ForegroundColor Cyan