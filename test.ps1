Write-Host ""
Write-Host "Checking Metrics Status..." -ForegroundColor Cyan
Write-Host ""

# Check if metrics-server pod exists
Write-Host "Metrics-server pod:" -ForegroundColor Yellow
kubectl get pods -n kube-system -l k8s-app=metrics-server

Write-Host ""
Write-Host "Node metrics:" -ForegroundColor Yellow
kubectl top nodes

Write-Host ""
Write-Host "Pod metrics:" -ForegroundColor Yellow
kubectl top pods

Write-Host ""
Write-Host "HPA status:" -ForegroundColor Yellow
kubectl get hpa

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
$metrics_working = kubectl top nodes 2>&1 | Out-String
if ($metrics_working -notmatch "error") {
    Write-Host "✓ Metrics are working!" -ForegroundColor Green
} else {
    Write-Host "✗ Metrics are NOT working" -ForegroundColor Red
    Write-Host ""
    Write-Host "Run: .\fix-metrics-server.ps1" -ForegroundColor Yellow
}
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""