# Stop Kubernetes Demo

$header = @'

Stopping Kubernetes Demo...

'@
Write-Host $header -ForegroundColor Yellow

# Stop port forwarding
Write-Host "Stopping port forwarding..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -eq "kubectl"} | Stop-Process -Force -ErrorAction SilentlyContinue
Write-Host "  Port forwarding stopped" -ForegroundColor Green

# Delete deployments
Write-Host ""
Write-Host "Deleting deployments..." -ForegroundColor Yellow
kubectl delete -f backend/deployment.yaml --ignore-not-found=true | Out-Null
kubectl delete -f backend/service.yaml --ignore-not-found=true | Out-Null
kubectl delete -f backend/hpa.yaml --ignore-not-found=true 2>&1 | Out-Null
kubectl delete -f frontend/frontend-deployment.yaml --ignore-not-found=true | Out-Null
kubectl delete -f frontend/frontend-service.yaml --ignore-not-found=true | Out-Null
Write-Host "  Deployments deleted" -ForegroundColor Green

$success_msg = @'

Demo stopped!

Minikube is still running. To stop it completely:
  minikube stop

'@
Write-Host $success_msg -ForegroundColor Green