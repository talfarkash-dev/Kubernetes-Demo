# Set UTF-8 encoding for this script
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Kubernetes Demo - Rebuild Script

Write-Host ""
Write-Host "Rebuild Images" -ForegroundColor Cyan
Write-Host "==============" -ForegroundColor Cyan
Write-Host ""

# Check if Minikube is running
$status = minikube status 2>&1 | Out-String
if ($status -notmatch "Running") {
    Write-Host "Error: Minikube is not running!" -ForegroundColor Red
    Write-Host "Please run: minikube start --driver=docker" -ForegroundColor Yellow
    exit
}

Write-Host "What do you want to rebuild?" -ForegroundColor Yellow
Write-Host "1. Backend only" -ForegroundColor White
Write-Host "2. Frontend only" -ForegroundColor White
Write-Host "3. Both (backend + frontend)" -ForegroundColor White
Write-Host "4. Force clean rebuild (delete images first)" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter choice (1-4)"

Write-Host ""
Write-Host "Configuring Docker environment..." -ForegroundColor Yellow
& minikube -p minikube docker-env --shell powershell | Invoke-Expression

switch ($choice) {
    "1" {
        Write-Host "Rebuilding backend..." -ForegroundColor Cyan
        Push-Location backend
        docker build -t flask-k8s-app:latest .
        Pop-Location

        Write-Host "Restarting backend pods..." -ForegroundColor Yellow
        kubectl rollout restart deployment/flask-app-deployment
        kubectl rollout status deployment/flask-app-deployment

        Write-Host "Backend rebuilt!" -ForegroundColor Green
    }
    "2" {
        Write-Host "Rebuilding frontend..." -ForegroundColor Cyan
        Push-Location frontend
        docker build -t k8s-demo-frontend:latest .
        Pop-Location

        Write-Host "Restarting frontend pods..." -ForegroundColor Yellow
        kubectl rollout restart deployment/frontend-deployment
        kubectl rollout status deployment/frontend-deployment

        Write-Host "Frontend rebuilt!" -ForegroundColor Green
    }
    "3" {
        Write-Host "Rebuilding backend..." -ForegroundColor Cyan
        Push-Location backend
        docker build -t flask-k8s-app:latest .
        Pop-Location

        Write-Host "Rebuilding frontend..." -ForegroundColor Cyan
        Push-Location frontend
        docker build -t k8s-demo-frontend:latest .
        Pop-Location

        Write-Host "Restarting all pods..." -ForegroundColor Yellow
        kubectl rollout restart deployment/flask-app-deployment
        kubectl rollout restart deployment/frontend-deployment

        Write-Host "All images rebuilt!" -ForegroundColor Green
    }
    "4" {
        Write-Host "Deleting old images..." -ForegroundColor Red
        docker rmi flask-k8s-app:latest -ErrorAction SilentlyContinue
        docker rmi k8s-demo-frontend:latest -ErrorAction SilentlyContinue

        Write-Host "Rebuilding backend..." -ForegroundColor Cyan
        Push-Location backend
        docker build -t flask-k8s-app:latest --no-cache .
        Pop-Location

        Write-Host "Rebuilding frontend..." -ForegroundColor Cyan
        Push-Location frontend
        docker build -t k8s-demo-frontend:latest --no-cache .
        Pop-Location

        Write-Host "Restarting all pods..." -ForegroundColor Yellow
        kubectl rollout restart deployment/flask-app-deployment
        kubectl rollout restart deployment/frontend-deployment

        Write-Host "Clean rebuild complete!" -ForegroundColor Green
    }
    default {
        Write-Host "Invalid choice" -ForegroundColor Red
        exit
    }
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host ""