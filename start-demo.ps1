# ==============================================================================
# Kubernetes Demo - One-Click Launcher
# ==============================================================================
# This script does EVERYTHING:
# 1. Checks/starts Minikube
# 2. Builds Docker images
# 3. Deploys to Kubernetes
# 4. Sets up port forwarding with FIXED ports
# 5. Opens browser
# ==============================================================================

Write-Host ""
Write-Host "🚀 Kubernetes Demo Launcher" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host ""

# Check if Minikube is running
Write-Host "📋 Checking Minikube status..." -ForegroundColor Yellow
$minikube_status = minikube status 2>&1
if ($minikube_status -notmatch "Running") {
    Write-Host "⚠️  Minikube not running. Starting..." -ForegroundColor Yellow
    minikube start --driver=docker

    # Enable metrics
    Write-Host "📊 Enabling metrics server..." -ForegroundColor Yellow
    minikube addons enable metrics-server
} else {
    Write-Host "✅ Minikube is running" -ForegroundColor Green
}

# Configure Docker environment
Write-Host ""
Write-Host "🐳 Configuring Docker environment..." -ForegroundColor Yellow
& minikube -p minikube docker-env --shell powershell | Invoke-Expression

# Check if images exist, if not build them
Write-Host ""
Write-Host "🔨 Checking Docker images..." -ForegroundColor Yellow

$backend_image_exists = docker images flask-k8s-app:latest -q
$frontend_image_exists = docker images k8s-demo-frontend:latest -q

if (-not $backend_image_exists) {
    Write-Host "📦 Building backend image..." -ForegroundColor Yellow
    Push-Location backend
    docker build -t flask-k8s-app:latest . | Out-Null
    Pop-Location
    Write-Host "✅ Backend image built" -ForegroundColor Green
} else {
    Write-Host "✅ Backend image exists" -ForegroundColor Green
}

if (-not $frontend_image_exists) {
    Write-Host "📦 Building frontend image..." -ForegroundColor Yellow
    Push-Location frontend
    docker build -t k8s-demo-frontend:latest . | Out-Null
    Pop-Location
    Write-Host "✅ Frontend image built" -ForegroundColor Green
} else {
    Write-Host "✅ Frontend image exists" -ForegroundColor Green
}

# Deploy to Kubernetes
Write-Host ""
Write-Host "☸️  Deploying to Kubernetes..." -ForegroundColor Yellow

kubectl apply -f backend/deployment.yaml | Out-Null
kubectl apply -f backend/service.yaml | Out-Null
kubectl apply -f backend/hpa.yaml | Out-Null
kubectl apply -f frontend/frontend-deployment.yaml | Out-Null
kubectl apply -f frontend/frontend-service.yaml | Out-Null

Write-Host "✅ All resources deployed" -ForegroundColor Green

# Wait for pods to be ready
Write-Host ""
Write-Host "⏳ Waiting for pods to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

$ready = $false
$attempts = 0
while (-not $ready -and $attempts -lt 12) {
    $pods = kubectl get pods --no-headers 2>&1
    $all_running = $true

    foreach ($line in $pods) {
        if ($line -match "Running.*1/1") {
            # Pod is ready
        } else {
            $all_running = $false
            break
        }
    }

    if ($all_running) {
        $ready = $true
    } else {
        Start-Sleep -Seconds 5
        $attempts++
    }
}

if ($ready) {
    Write-Host "✅ All pods are ready!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some pods may still be starting..." -ForegroundColor Yellow
}

# Kill any existing port-forward processes
Write-Host ""
Write-Host "🔌 Setting up port forwarding..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -eq "kubectl" -and $_.CommandLine -like "*port-forward*"} | Stop-Process -Force 2>$null

# Start port forwarding in background with FIXED ports
# Backend on port 8080
Start-Process -WindowStyle Hidden powershell -ArgumentList "-Command", "kubectl port-forward service/flask-app-service 8080:80"

# Frontend on port 8081
Start-Process -WindowStyle Hidden powershell -ArgumentList "-Command", "kubectl port-forward service/frontend-service 8081:80"

# Wait a moment for port forwarding to establish
Start-Sleep -Seconds 3

Write-Host "✅ Port forwarding established" -ForegroundColor Green

# Display URLs
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "🎉 Demo is Ready!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Frontend: http://localhost:8081" -ForegroundColor Yellow
Write-Host "Backend:  http://localhost:8080" -ForegroundColor Yellow
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Open browser
Write-Host "🌐 Opening browser..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
Start-Process "http://localhost:8081"

Write-Host ""
Write-Host "💡 Tips:" -ForegroundColor Cyan
Write-Host "   - Click 'Simple Request' to see load balancing" -ForegroundColor White
Write-Host "   - Click 'Trigger CPU Load' to see auto-scaling" -ForegroundColor White
Write-Host "   - Run 'kubectl get hpa -w' to watch scaling" -ForegroundColor White
Write-Host "   - Run 'kubectl get pods -w' to watch pods" -ForegroundColor White
Write-Host ""
Write-Host "🛑 To stop the demo, run: .\stop-demo.ps1" -ForegroundColor Red
Write-Host ""