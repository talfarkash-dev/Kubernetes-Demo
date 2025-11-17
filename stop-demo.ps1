# ==============================================================================
# Kubernetes Demo - Stop Script
# ==============================================================================
# Cleanly stops all demo components
# ==============================================================================

Write-Host ""
Write-Host "🛑 Stopping Kubernetes Demo" -ForegroundColor Red
Write-Host "=============================" -ForegroundColor Red
Write-Host ""

# Kill port-forward processes
Write-Host "🔌 Stopping port forwarding..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -eq "kubectl"} | Stop-Process -Force 2>$null
Write-Host "✅ Port forwarding stopped" -ForegroundColor Green

# Option to delete Kubernetes resources
Write-Host ""
$delete = Read-Host "Do you want to delete Kubernetes resources? (y/N)"

if ($delete -eq "y" -or $delete -eq "Y") {
    Write-Host ""
    Write-Host "🗑️  Deleting Kubernetes resources..." -ForegroundColor Yellow

    kubectl delete -f backend/deployment.yaml 2>$null
    kubectl delete -f backend/service.yaml 2>$null
    kubectl delete -f backend/hpa.yaml 2>$null
    kubectl delete -f frontend/frontend-deployment.yaml 2>$null
    kubectl delete -f frontend/frontend-service.yaml 2>$null

    Write-Host "✅ Resources deleted" -ForegroundColor Green
}

# Option to stop Minikube
Write-Host ""
$stop_minikube = Read-Host "Do you want to stop Minikube? (y/N)"

if ($stop_minikube -eq "y" -or $stop_minikube -eq "Y") {
    Write-Host ""
    Write-Host "⏹️  Stopping Minikube..." -ForegroundColor Yellow
    minikube stop
    Write-Host "✅ Minikube stopped" -ForegroundColor Green
}

Write-Host ""
Write-Host "✅ Demo stopped!" -ForegroundColor Green
Write-Host ""