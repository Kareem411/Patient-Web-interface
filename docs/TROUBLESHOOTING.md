# 🚨 CI/CD Pipeline Troubleshooting Guide

## Current Status ✅

**Fixed Issues:**
- ✅ Switched from Docker Hub to GitHub Container Registry (GHCR)
- ✅ Updated Kubernetes deployment to use new registry
- ✅ Docker build tested successfully locally
- ✅ Added fallback local CI workflow

## 🔍 Root Cause Analysis

### Original Problems:
1. **Docker Hub Authentication**: Missing `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets
2. **Registry Access**: No access to external Docker registry
3. **Dependency Chain**: Kubernetes deployment skipped due to build failure

### Solutions Implemented:
1. **GitHub Container Registry**: Uses built-in `GITHUB_TOKEN` (no additional secrets needed)
2. **Updated Image References**: Changed all registry references to `ghcr.io`
3. **Alternative Workflow**: Created local CI for development branches

## 📊 Pipeline Status

### Current CI/CD Flow:
```
Push to main → Test → Security → Build (GHCR) → Deploy (K8s) → Notify
```

### Expected Results:
- **Tests**: ✅ Should pass (Flask app + pytest)
- **Security**: ✅ Should pass (pip-audit with warnings allowed)
- **Build**: ✅ Should work with GHCR
- **Kubernetes**: ✅ Should deploy with new image

## 🛠️ Next Steps

### If the pipeline still fails:

1. **Check GitHub Package Permissions**:
   ```bash
   # Ensure your GitHub token has package:write permissions
   # Go to: Settings → Developer settings → Personal access tokens
   ```

2. **Make Package Public**:
   - Go to your repository → Packages
   - Find the `patient-web-interface` package
   - Make it public if needed

3. **Alternative: Use Docker Hub**:
   ```bash
   # Create Docker Hub account and get access token
   # Add secrets: DOCKERHUB_USERNAME, DOCKERHUB_TOKEN
   # Revert to docker.io registry
   ```

4. **Test Locally**:
   ```bash
   # Test the complete flow locally
   cd project
   docker build -t patient-web-interface:test .
   docker run -p 8080:5000 patient-web-interface:test
   ```

## 🔧 Manual Deployment

If CI/CD continues to fail, deploy manually:

```bash
# 1. Build and push image manually
cd project
docker build -t ghcr.io/kareem411/patient-web-interface:manual .
docker push ghcr.io/kareem411/patient-web-interface:manual

# 2. Update Kubernetes deployment
cd ../k8s
sed -i 's/:latest/:manual/g' deployment.yaml
kubectl apply -f deployment.yaml

# 3. Verify deployment
kubectl get pods -n patient-web-interface
kubectl port-forward service/patient-web-interface-service 8080:80 -n patient-web-interface
```

## 📞 Support Commands

```bash
# Check pipeline status
git log --oneline -5

# View recent commits
git status

# Check Docker locally
docker images | grep patient-web

# Check Kubernetes status
kubectl get all -n patient-web-interface

# View pod logs
kubectl logs -l app=patient-web-interface -n patient-web-interface --tail=50
```

## 🎯 Success Indicators

The pipeline should show:
- ✅ Tests: success
- ✅ Security: success  
- ✅ Build: success
- ✅ Kubernetes Deploy: success

Access the app via:
```bash
kubectl port-forward service/patient-web-interface-service 8080:80 -n patient-web-interface
# Then visit: http://localhost:8080
```
