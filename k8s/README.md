# Kubernetes Deployment Guide

This directory contains Kubernetes manifests and deployment scripts for the Patient Web Interface application running on Minikube.

## 📋 Prerequisites

### Required Software
- **Minikube** (v1.25+)
- **kubectl** (compatible with your Kubernetes version)
- **Docker** (for Minikube driver)

### Installation

#### Install kubectl
```bash
# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Windows (using Chocolatey)
choco install kubernetes-cli

# macOS (using Homebrew)
brew install kubectl
```

#### Install Minikube
```bash
# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Windows (using Chocolatey)
choco install minikube

# macOS (using Homebrew)
brew install minikube
```

## 🚀 Quick Start

### 1. Start Minikube
```bash
minikube start --driver=docker --memory=2048 --cpus=2
```

### 2. Enable Required Addons
```bash
minikube addons enable ingress
minikube addons enable dashboard
minikube addons enable metrics-server
```

### 3. Deploy Application

**Linux/Mac:**
```bash
cd k8s
chmod +x deploy.sh
./deploy.sh deploy
```

**Windows:**
```powershell
cd k8s
.\deploy.ps1 deploy
```

### 4. Access Application

**Port Forwarding (Recommended):**
```bash
./deploy.sh port-forward
# Application available at: http://localhost:8080
```

**Or using kubectl directly:**
```bash
kubectl port-forward service/patient-web-interface-service 8080:80 -n patient-web-interface
```

## 📁 File Structure

```
k8s/
├── deployment.yaml      # Main application deployment and services
├── ingress.yaml        # Ingress configuration and network policies
├── monitoring.yaml     # Monitoring and autoscaling resources
├── deploy.sh          # Deployment script (Linux/Mac)
├── deploy.ps1         # Deployment script (Windows)
└── README.md          # This file
```

## 🔧 Kubernetes Resources

### Core Resources

#### Namespace
- **patient-web-interface**: Isolated namespace for all application resources

#### ConfigMap
- **patient-app-config**: Application configuration (environment variables)

#### Secret
- **patient-app-secrets**: Sensitive data (SECRET_KEY)

#### PersistentVolume & PersistentVolumeClaim
- **patient-db-pv/pvc**: Persistent storage for SQLite database

#### Deployment
- **patient-web-interface**: Main application deployment with 2 replicas
- Rolling update strategy with health checks
- Resource limits and requests
- Security context with non-root user

#### Service
- **patient-web-interface-service**: ClusterIP service exposing port 80
- **patient-web-interface-headless**: Headless service for future StatefulSet use

### Scaling & High Availability

#### HorizontalPodAutoscaler
- Auto-scales between 2-10 replicas based on CPU (70%) and memory (80%) usage
- Smart scaling policies for controlled scale-up/down

#### PodDisruptionBudget
- Ensures at least 1 pod is always available during voluntary disruptions

### Networking & Security

#### Ingress
- **patient-web-interface-ingress**: Routes external traffic to the service
- Supports both domain-based and path-based routing

#### NetworkPolicy
- **patient-web-interface-netpol**: Restricts network traffic for security

### Monitoring

#### ServiceMonitor
- **patient-web-interface-monitor**: Prometheus monitoring configuration

## 🛠️ Management Commands

### Deployment Management

```bash
# Deploy application
./deploy.sh deploy

# Check deployment status
./deploy.sh status

# View application logs
./deploy.sh logs

# Scale application
./deploy.sh scale 5

# Update application image
./deploy.sh update abdallahbagato/patient-web-interface:v2.0.0

# Delete application
./deploy.sh delete
```

### Access Methods

```bash
# Setup port forwarding
./deploy.sh port-forward

# Get access URLs and methods
./deploy.sh url

# Open Kubernetes dashboard
./deploy.sh dashboard
```

### Direct kubectl Commands

```bash
# View all resources
kubectl get all -n patient-web-interface

# View pods with details
kubectl get pods -n patient-web-interface -o wide

# Describe deployment
kubectl describe deployment patient-web-interface -n patient-web-interface

# View logs from all pods
kubectl logs -l app=patient-web-interface -n patient-web-interface

# Execute shell in pod
kubectl exec -it deployment/patient-web-interface -n patient-web-interface -- /bin/bash

# Port forward to service
kubectl port-forward service/patient-web-interface-service 8080:80 -n patient-web-interface
```

## 🌐 Application Access

### Method 1: Port Forwarding (Recommended)
```bash
kubectl port-forward service/patient-web-interface-service 8080:80 -n patient-web-interface
```
Access at: http://localhost:8080

### Method 2: Minikube Service
```bash
minikube service patient-web-interface-service -n patient-web-interface
```
This will open the application in your default browser.

### Method 3: Ingress (Local Development)
```bash
# Get Minikube IP
minikube ip

# Add to /etc/hosts (Linux/Mac) or C:\Windows\System32\drivers\etc\hosts (Windows)
<MINIKUBE_IP> patient-web-interface.local

# Access at: http://patient-web-interface.local
```

### Method 4: NodePort Service
```bash
# Get service URL
minikube service patient-web-interface-service -n patient-web-interface --url
```

## 📊 Monitoring & Debugging

### View Resource Usage
```bash
# Pod resource usage
kubectl top pods -n patient-web-interface

# Node resource usage
kubectl top nodes

# HPA status
kubectl get hpa -n patient-web-interface
```

### Debug Issues
```bash
# Check pod events
kubectl describe pod <pod-name> -n patient-web-interface

# View deployment events
kubectl describe deployment patient-web-interface -n patient-web-interface

# Check service endpoints
kubectl get endpoints -n patient-web-interface

# View ingress details
kubectl describe ingress patient-web-interface-ingress -n patient-web-interface
```

### Application Logs
```bash
# Real-time logs from all pods
kubectl logs -f -l app=patient-web-interface -n patient-web-interface

# Logs from specific pod
kubectl logs <pod-name> -n patient-web-interface

# Previous container logs (if pod restarted)
kubectl logs <pod-name> -n patient-web-interface --previous
```

## 🔄 CI/CD Integration

The Kubernetes deployment can be integrated with the existing CI/CD pipeline by adding deployment steps:

```yaml
# Example GitHub Actions step
- name: Deploy to Minikube
  run: |
    kubectl apply -f k8s/deployment.yaml
    kubectl apply -f k8s/ingress.yaml
    kubectl apply -f k8s/monitoring.yaml
    kubectl rollout status deployment/patient-web-interface -n patient-web-interface
```

## 🔧 Configuration

### Environment Variables
Modify the ConfigMap in `deployment.yaml`:
```yaml
data:
  FLASK_ENV: "production"
  DATABASE_URL: "sqlite:///instance/patient.db"
  APP_PORT: "5000"
```

### Resource Limits
Adjust resource requests and limits:
```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Scaling Configuration
Modify HPA settings:
```yaml
minReplicas: 2
maxReplicas: 10
metrics:
- type: Resource
  resource:
    name: cpu
    target:
      type: Utilization
      averageUtilization: 70
```

## 🛡️ Security

### Pod Security
- Runs as non-root user (UID 1000)
- Read-only root filesystem where possible
- No privilege escalation allowed

### Network Security
- NetworkPolicy restricts ingress/egress traffic
- Service communication within namespace

### Secrets Management
- Sensitive data stored in Kubernetes Secrets
- Base64 encoded (consider external secret management for production)

## 📈 Production Considerations

### For Production Deployment:
1. **Use external database** instead of SQLite with persistent volume
2. **Implement proper secret management** (e.g., HashiCorp Vault)
3. **Set up monitoring** with Prometheus and Grafana
4. **Configure backup strategies** for persistent data
5. **Implement proper ingress** with TLS certificates
6. **Use resource quotas** and limit ranges
7. **Set up log aggregation** (e.g., ELK stack)
8. **Implement security scanning** in CI/CD pipeline

### Performance Tuning:
- Adjust resource requests/limits based on actual usage
- Configure appropriate HPA metrics and thresholds
- Use node affinity/anti-affinity for pod placement
- Implement readiness and liveness probe tuning

## 🆘 Troubleshooting

### Common Issues

**Pods not starting:**
```bash
kubectl describe pod <pod-name> -n patient-web-interface
kubectl logs <pod-name> -n patient-web-interface
```

**Service not accessible:**
```bash
kubectl get endpoints -n patient-web-interface
kubectl describe service patient-web-interface-service -n patient-web-interface
```

**Ingress not working:**
```bash
kubectl describe ingress patient-web-interface-ingress -n patient-web-interface
minikube addons list | grep ingress
```

**HPA not scaling:**
```bash
kubectl describe hpa patient-web-interface-hpa -n patient-web-interface
kubectl top pods -n patient-web-interface
```

### Reset Everything
```bash
# Delete all resources
kubectl delete namespace patient-web-interface

# Or stop and restart Minikube
minikube stop
minikube delete
minikube start --driver=docker --memory=2048 --cpus=2
```

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

---

For support or questions, please refer to the main project documentation or open an issue in the repository.
