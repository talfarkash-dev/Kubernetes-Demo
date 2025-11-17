# ⚡ Quick Start Guide

Run the demo in 3 simple steps!

## 🎯 Prerequisites

1. **Docker Desktop** - Must be running
2. **Minikube** - Installed
3. **kubectl** - Installed

---

## 🚀 Step 1: Update Files

Update these 2 files with the latest versions:

1. **frontend/index.html** - Copy updated version (uses localhost:8080)
2. **start-demo.ps1** - Create this new file in project root
3. **stop-demo.ps1** - Create this new file in project root
4. **watch-demo.ps1** - Create this new file in project root (optional)

---

## 🎮 Step 2: Run the Demo

**Just double-click or run:**

```powershell
.\start-demo.ps1
```

That's it! The script will:
- ✅ Start Minikube (if needed)
- ✅ Build Docker images
- ✅ Deploy everything to Kubernetes
- ✅ Set up port forwarding with fixed ports
- ✅ Open your browser automatically

**Fixed URLs:**
- Frontend: `http://localhost:8081`
- Backend: `http://localhost:8080`

---

## 📊 Step 3: Watch Auto-Scaling (Optional)

In a new PowerShell window:

```powershell
.\watch-demo.ps1
```

Choose option 3 to watch both pods and HPA.

Then click "🔥 Trigger CPU Load" in the browser!

---

## 🎉 That's It!

**To use the demo:**
1. Click **"📡 Simple Request"** → See load balancing
2. Click **"🔥 Trigger CPU Load"** → See auto-scaling

**To stop the demo:**
```powershell
.\stop-demo.ps1
```

---

## 📋 Complete File Checklist

Make sure you have:
- ✅ backend/ folder (6 files)
- ✅ frontend/ folder (5 files)
- ✅ start-demo.ps1 (in root)
- ✅ stop-demo.ps1 (in root)
- ✅ watch-demo.ps1 (in root - optional)

---

## 🐛 Troubleshooting

**"Minikube won't start"**
```powershell
minikube delete
minikube start --driver=docker
```

**"Port already in use"**
```powershell
.\stop-demo.ps1
# Then try again
```

**"Can't connect to backend"**
```powershell
# Check port forwarding is running
Get-Process | Where-Object {$_.ProcessName -eq "kubectl"}
```

---

**That's it! One script to rule them all!** 🎉