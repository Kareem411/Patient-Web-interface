# CI/CD Pipeline Documentation

This repository includes a comprehensive CI/CD pipeline using GitHub Actions that automates testing, building, and deployment of the Patient Management System.

## Overview

The CI/CD pipeline consists of four main workflows:

1. **Main CI/CD Pipeline** (`ci-cd.yml`) - Runs on every push and pull request
2. **Code Quality & Dependency Updates** (`code-quality.yml`) - Runs weekly and can be triggered manually
3. **Release Pipeline** (`release.yml`) - Runs when a release is published
4. **Kubernetes Deployment** - Integrated into the main CI/CD pipeline for container orchestration

## Infrastructure as Code

The application infrastructure is managed using **Terraform** and is located in the `/terraform` directory. The infrastructure includes:

- **AWS VPC** with public and private subnets across multiple Availability Zones
- **Application Load Balancer** for high availability and traffic distribution
- **Auto Scaling Group** with EC2 instances running the containerized application
- **Security Groups** for network access control
- **CloudWatch** monitoring and auto-scaling triggers
- **NAT Gateway** for secure outbound internet access from private subnets
- **Minikube** installation on EC2 instances for Kubernetes deployment

### Infrastructure Deployment

The infrastructure can be deployed using the provided scripts:

**Windows (PowerShell):**
```powershell
cd terraform
.\deploy.ps1 deploy
```

**Linux/Mac (Bash):**
```bash
cd terraform
./deploy.sh deploy
```

**Manual Terraform:**
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Kubernetes Deployment

The application also supports **Kubernetes deployment using Minikube** for container orchestration. The Kubernetes manifests are located in the `/k8s` directory.

### Kubernetes Features

- **Container Orchestration**: Minikube cluster running on EC2 instances
- **Auto Scaling**: Horizontal Pod Autoscaler (HPA) based on CPU and memory metrics
- **Service Discovery**: Kubernetes services and ingress controllers
- **Persistent Storage**: PersistentVolumes for SQLite database persistence
- **Health Checks**: Readiness and liveness probes for application health
- **Rolling Updates**: Zero-downtime deployments with rolling update strategy
- **Resource Management**: CPU and memory limits and requests
- **Network Policies**: Secure pod-to-pod communication
- **Load Balancing**: ClusterIP services for internal load balancing

### Kubernetes Deployment Methods

**Complete Setup (includes Minikube installation):**
```bash
./k8s-setup.sh full
```

**Kubernetes Only Deployment:**
```bash
cd k8s
./deploy.sh deploy
```

**Windows PowerShell:**
```powershell
cd k8s
.\deploy.ps1 deploy
```

### Application Access via Kubernetes

**Port Forwarding (Recommended):**
```bash
kubectl port-forward service/patient-web-interface-service 8080:80 -n patient-web-interface
# Access at: http://localhost:8080
```

**Minikube Service:**
```bash
minikube service patient-web-interface-service -n patient-web-interface
```

**Ingress (with host configuration):**
```bash
# Add to /etc/hosts: <MINIKUBE_IP> patient-web-interface.local
# Access at: http://patient-web-interface.local
```

## Workflows

### 1. Main CI/CD Pipeline (`ci-cd.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` branch

**Jobs:**

#### Test and Lint
- Sets up Python 3.11 environment
- Installs dependencies with caching
- Runs flake8 linting checks
- Executes pytest with coverage reporting
- Uploads coverage to Codecov (optional)

#### Security Scan
- Runs safety check on dependencies
- Identifies known security vulnerabilities

#### Build Docker Image
- Builds Docker image using multi-platform support
- Pushes to Docker Hub (only on main/develop, not PRs)
- Uses Docker layer caching for faster builds
- Tags images based on branch and commit SHA

#### Deploy to Staging
- Runs only on `develop` branch
- Deploys to staging environment

#### Deploy to Production
- Runs only on `main` branch
- Deploys to production environment

#### Deploy to Kubernetes (Minikube)
- Runs only on `main` branch after successful build
- Sets up Minikube cluster with required addons
- Deploys application using Kubernetes manifests
- Performs health checks and accessibility tests
- Uses port forwarding to verify application deployment
- Provides access information and deployment status

#### Notifications
- Sends status notifications
- Reports success/failure of all jobs

### 2. Code Quality & Dependency Updates (`code-quality.yml`)

**Triggers:**
- Weekly schedule (Mondays at 9 AM UTC)
- Manual trigger via workflow_dispatch

**Jobs:**

#### Code Quality Analysis
- Checks code formatting with Black
- Validates import sorting with isort
- Runs security analysis with Bandit
- Performs type checking with MyPy

#### Dependency Audit
- Scans for security vulnerabilities in dependencies
- Generates audit reports

#### Automated PR Creation
- Creates PR with automatic code formatting fixes
- Only runs if code quality checks fail

### 3. Release Pipeline (`release.yml`)

**Triggers:**
- GitHub release publication
- Manual trigger with version input

**Jobs:**

#### Build and Release
- Runs full test suite
- Builds and pushes versioned Docker images
- Creates GitHub release (if manually triggered)

#### Production Deployment
- Deploys to production environment
- Runs health checks
- Sends notifications

## Setup Instructions

### 1. Repository Secrets

Add the following secrets to your GitHub repository:

```
DOCKER_USERNAME - Your Docker Hub username
DOCKER_PASSWORD - Your Docker Hub password or access token
AWS_ACCESS_KEY_ID - AWS access key for Terraform deployments
AWS_SECRET_ACCESS_KEY - AWS secret key for Terraform deployments
TF_VAR_public_key - SSH public key for EC2 instances
```

**To add secrets:**
1. Go to your repository on GitHub
2. Click Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add each secret with the exact names above

### 2. Kubernetes Setup

For Kubernetes deployments, the CI/CD pipeline automatically:

1. **Sets up Minikube** with Docker driver and 2GB memory
2. **Enables required addons**: ingress, metrics-server, dashboard
3. **Deploys application** using manifests in `/k8s` directory
4. **Verifies deployment** with health checks and port forwarding tests
5. **Provides access methods** for the deployed application

**Local Kubernetes Setup:**
```bash
# Install Minikube and kubectl
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube
minikube start --driver=docker --memory=2048 --cpus=2

# Deploy application
cd k8s
kubectl apply -f deployment.yaml
kubectl apply -f ingress.yaml
kubectl apply -f monitoring.yaml
```
1. Go to your repository on GitHub
2. Click Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add each secret with the exact names above

### 3. Docker Hub Setup

1. Create a Docker Hub account at https://hub.docker.com
2. Create a repository named `patient-management-system`
3. Generate an access token:
   - Go to Account Settings → Security
   - Click "New Access Token"
   - Copy the token and use it as `DOCKER_PASSWORD` secret

### 4. Environment Configuration

The pipeline uses GitHub environments for deployment:

1. Go to Settings → Environments
2. Create environments named:
   - `staging`
   - `production`
3. Configure protection rules as needed (e.g., required reviewers for production)

### 5. Branch Protection

Set up branch protection for `main`:

1. Go to Settings → Branches
2. Add rule for `main` branch
3. Enable:
   - Require status checks to pass
   - Require branches to be up to date
   - Require review from code owners

## Customization

### Adding Deployment Steps

To customize deployment, edit the deployment jobs in `ci-cd.yml` and `release.yml`:

```yaml
- name: Deploy to production
  run: |
    # Add your deployment commands here
    # Examples:
    # kubectl apply -f k8s/
    # docker-compose up -d
    # ssh user@server 'docker pull image && docker restart container'
```

### Adding Notifications

You can add Slack, Teams, or email notifications:

```yaml
- name: Notify team
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Custom Test Commands

Modify the test job to add more test types:

```yaml
- name: Run integration tests
  run: |
    cd project
    pytest tests/integration/ -v

- name: Run end-to-end tests
  run: |
    cd project
    python -m pytest tests/e2e/ -v
```

## Monitoring and Troubleshooting

### Viewing Workflow Results

1. Go to the "Actions" tab in your repository
2. Click on any workflow run to see details
3. Click on individual jobs to see logs

### Common Issues

#### Docker Build Fails
- Check Dockerfile syntax
- Ensure all required files are copied
- Verify base image availability

#### Tests Fail
- Check test dependencies in requirements.txt
- Ensure database setup in tests
- Verify test isolation

#### Deployment Fails
- Check environment secrets
- Verify deployment target accessibility
- Review deployment scripts

### Best Practices

1. **Keep secrets secure** - Never commit secrets to code
2. **Test locally first** - Run tests and builds locally before pushing
3. **Use feature branches** - Create PRs for all changes
4. **Monitor builds** - Check failed builds promptly
5. **Update dependencies** - Review weekly dependency reports

## Badges

Add these badges to your README.md:

```markdown
![CI/CD](https://github.com/yourusername/patient-management-system/workflows/CI/CD%20Pipeline/badge.svg)
![Code Quality](https://github.com/yourusername/patient-management-system/workflows/Code%20Quality%20&%20Dependency%20Updates/badge.svg)
[![codecov](https://codecov.io/gh/yourusername/patient-management-system/branch/main/graph/badge.svg)](https://codecov.io/gh/yourusername/patient-management-system)
```

## Support

For issues with the CI/CD pipeline:

1. Check the workflow logs in the Actions tab
2. Review this documentation
3. Create an issue in the repository
4. Contact the development team
