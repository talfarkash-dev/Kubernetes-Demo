# ==============================================================================
# Kubernetes Demo - Watch Script
# ==============================================================================
# Monitors pods and HPA in real-time
# ==============================================================================

Write-Host ""
Write-Host "👀 Kubernetes Demo Monitor" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Choose what to watch:" -ForegroundColor Yellow
Write-Host "1. Pods (see scaling in action)" -ForegroundColor White
Write-Host "2. HPA (see auto-scaler metrics)" -ForegroundColor White
Write-Host "3. Both (side by side)" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter choice (1-3)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "Watching pods... (Press Ctrl+C to exit)" -ForegroundColor Green
        Write-Host ""
        kubectl get pods -w
    }
    "2" {
        Write-Host ""
        Write-Host "Watching HPA... (Press Ctrl+C to exit)" -ForegroundColor Green
        Write-Host ""
        kubectl get hpa -w
    }
    "3" {
        Write-Host ""
        Write-Host "Opening two watch windows..." -ForegroundColor Green

        # Window 1 - Pods
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host '👀 Watching Pods' -ForegroundColor Cyan; kubectl get pods -w"

        # Window 2 - HPA
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host '📊 Watching HPA' -ForegroundColor Cyan; kubectl get hpa -w"

        Write-Host "✅ Watch windows opened!" -ForegroundColor Green
    }
    default {
        Write-Host "Invalid choice" -ForegroundColor Red
    }
}