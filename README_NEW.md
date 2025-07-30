# Patient Web Interface

A comprehensive web-based patient management system built with Flask, featuring secure patient data management, search functionality, and modern CI/CD deployment practices.

![CI/CD](https://github.com/AbdallahBagato/Patient-Web-interface/workflows/CI%2FCD%20Pipeline/badge.svg)
![Infrastructure](https://img.shields.io/badge/Infrastructure-Terraform-7B68EE)
![Deployment](https://img.shields.io/badge/Deployment-AWS-FF9900)
![Containerization](https://img.shields.io/badge/Container-Docker-2496ED)

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   GitHub        │    │   Docker Hub     │    │      AWS        │
│   Repository    │    │   Registry       │    │   Infrastructure │
│                 │    │                  │    │                 │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │ ┌─────────────┐ │
│ │   Source    │ │    │ │    Image     │ │    │ │     ALB     │ │
│ │    Code     │ │───▶│ │  Repository  │ │───▶│ │             │ │
│ └─────────────┘ │    │ └──────────────┘ │    │ └─────────────┘ │
│ ┌─────────────┐ │    │                  │    │ ┌─────────────┐ │
│ │   CI/CD     │ │    │                  │    │ │  Auto       │ │
│ │  Workflows  │ │    │                  │    │ │ Scaling     │ │
│ └─────────────┘ │    │                  │    │ │   Group     │ │
└─────────────────┘    └──────────────────┘    │ └─────────────┘ │
                                               │ ┌─────────────┐ │
                                               │ │   EC2       │ │
                                               │ │ Instances   │ │
                                               │ └─────────────┘ │
                                               └─────────────────┘
```

## 🚀 Features

### Application Features
- **Patient Registration**: Secure patient data registration with validation
- **Patient Search**: Advanced search functionality by name, ID, or phone
- **Data Management**: View, edit, and manage patient information
- **Responsive Design**: Mobile-friendly user interface
- **SQLite Database**: Lightweight, file-based database for data persistence

### Infrastructure Features
- **High Availability**: Multi-AZ deployment with Auto Scaling
- **Load Balancing**: Application Load Balancer for traffic distribution
- **Security**: Security groups, VPC isolation, and encrypted communication
- **Monitoring**: CloudWatch integration for metrics and logging
- **Infrastructure as Code**: Complete Terraform automation
- **CI/CD Pipeline**: Automated testing, building, and deployment

### Kubernetes Features
- **Container Orchestration**: Minikube for local Kubernetes deployment
- **Auto Scaling**: Horizontal Pod Autoscaler based on CPU and memory
- **Service Discovery**: Kubernetes services and ingress controllers
- **Persistent Storage**: PersistentVolumes for database persistence
- **Health Checks**: Readiness and liveness probes
- **Rolling Updates**: Zero-downtime deployments
- **Resource Management**: CPU and memory limits/requests
- **Network Policies**: Secure pod-to-pod communication

## 📁 Project Structure

```
Patient-Web-interface/
├── project/                    # Main application code
│   ├── main.py                # Flask application entry point
│   ├── signup.py              # Patient registration logic
│   ├── test_app.py            # Application tests
│   ├── requirements.txt       # Python dependencies
│   ├── Dockerfile            # Container configuration
│   ├── templates/            # HTML templates
│   │   ├── main.html
│   │   ├── signup.html
│   │   ├── search.html
│   │   └── out.html
│   └── instance/
│       └── patient.db        # SQLite database
├── terraform/                 # Infrastructure as Code
│   ├── main.tf               # Main Terraform configuration
│   ├── variables.tf          # Variable definitions
│   ├── outputs.tf            # Output definitions
│   ├── user-data.sh          # EC2 bootstrap script
│   ├── deploy.sh             # Deployment script (Linux/Mac)
│   ├── deploy.ps1            # Deployment script (Windows)
│   └── README.md             # Terraform documentation
├── .github/workflows/         # CI/CD pipelines
│   ├── ci-cd.yml             # Main CI/CD workflow
│   ├── code-quality.yml      # Code quality checks
│   └── release.yml           # Release automation
├── docs/                      # Documentation
│   └── CICD.md               # CI/CD documentation
├── docker-compose.yml         # Local development setup
├── setup.sh                  # Complete project setup script
└── README.md                 # This file
```

## 🛠️ Quick Start

### Prerequisites
- **Git** for version control
- **Docker** for containerization
- **AWS Account** for cloud deployment
- **Terraform** for infrastructure management
- **Python 3.11+** for local development

### Option 1: Automated Setup (Recommended)

**Linux/Mac:**
```bash
git clone https://github.com/AbdallahBagato/Patient-Web-interface.git
cd Patient-Web-interface
chmod +x setup.sh
./setup.sh
```

**Windows:**
```powershell
git clone https://github.com/AbdallahBagato/Patient-Web-interface.git
cd Patient-Web-interface
# Follow manual setup steps below
```

### Option 2: Manual Setup

#### 1. Clone Repository
```bash
git clone https://github.com/AbdallahBagato/Patient-Web-interface.git
cd Patient-Web-interface
```

#### 2. Local Development Setup
```bash
cd project
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

#### 3. Docker Setup
```bash
cd project
docker build -t patient-web-interface .
docker run -p 5000:5000 patient-web-interface
```

#### 4. Infrastructure Deployment
```bash
cd terraform
# Configure terraform.tfvars with your settings
terraform init
terraform plan
terraform apply
```

## 🌐 Deployment

### Local Development
```bash
cd project
python main.py
# Access at: http://localhost:5000
```

### Docker Deployment
```bash
docker-compose up -d
# Access at: http://localhost:5000
```

### Kubernetes Deployment
```bash
# Start Minikube
minikube start --driver=docker --memory=2048 --cpus=2

# Deploy application
cd k8s
./deploy.sh deploy

# Access application
kubectl port-forward service/patient-web-interface-service 8080:80 -n patient-web-interface
# Access at: http://localhost:8080
```

### AWS Production Deployment
```bash
cd terraform
./deploy.sh deploy  # Linux/Mac
# or
.\deploy.ps1 deploy  # Windows

# Access at: [Load Balancer DNS from terraform output]
```

### Kubernetes Deployment (Minikube)
```bash
# Complete setup (includes Minikube installation on EC2)
./k8s-setup.sh full

# Or step by step:
cd k8s
./deploy.sh deploy

# Access via port forwarding
kubectl port-forward service/patient-web-interface-service 8080:80 -n patient-web-interface
# Access at: http://localhost:8080
```

## 🧪 Testing

### Run Tests Locally
```bash
cd project
source venv/bin/activate
pytest test_app.py -v
```

### Run Tests with Coverage
```bash
cd project
pytest --cov=. --cov-report=html test_app.py
```

## 🔄 CI/CD Pipeline

The project includes comprehensive CI/CD workflows:

### Automated Testing
- Code quality checks (flake8, black, isort)
- Security scanning (safety, bandit)
- Unit and integration tests
- Coverage reporting

### Docker Build & Push
- Multi-platform Docker builds
- Automated tagging and versioning
- Push to Docker Hub registry
- Vulnerability scanning

### Infrastructure Deployment
- Terraform plan and apply
- Auto-scaling group updates
- Health checks and rollback
- Monitoring setup

### Manual Triggers
```bash
# Trigger deployment manually
gh workflow run "CI/CD Pipeline" --ref main

# Trigger release
gh workflow run "Release Pipeline" --ref main -f version=v1.0.0
```

## 📊 Monitoring

### Application Monitoring
- **Health Check Endpoint**: `/health`
- **Metrics**: Response times, error rates
- **Logs**: Application and access logs

### Infrastructure Monitoring
- **CloudWatch Metrics**: CPU, memory, network
- **Auto Scaling**: Based on CPU utilization
- **Alarms**: Automated scaling triggers
- **Dashboard**: Custom CloudWatch dashboard

### Access Monitoring
```bash
# View application logs
docker logs patient-app

# View infrastructure metrics
aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB

# Access AWS Console for detailed monitoring
```

## 🔧 Configuration

### Environment Variables
```bash
# Application configuration
FLASK_ENV=production
DATABASE_URL=sqlite:///instance/patient.db
SECRET_KEY=your-secret-key

# AWS configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
```

### Terraform Variables
Key variables in `terraform/terraform.tfvars`:
```hcl
aws_region        = "us-east-1"
instance_type     = "t3.micro"
min_instances     = 1
max_instances     = 3
desired_instances = 2
docker_image      = "abdallahbagato/patient-web-interface:latest"
```

## 🛡️ Security

### Application Security
- Input validation and sanitization
- SQL injection prevention
- CSRF protection
- Secure headers

### Infrastructure Security
- VPC with private/public subnets
- Security groups with minimal access
- IAM roles with least privilege
- Encrypted data in transit

### Best Practices
- Regular dependency updates
- Security scanning in CI/CD
- Access logging and monitoring
- Backup and disaster recovery

## 🤝 Contributing

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes**
4. **Run tests**: `pytest`
5. **Commit changes**: `git commit -m 'Add amazing feature'`
6. **Push to branch**: `git push origin feature/amazing-feature`
7. **Open a Pull Request**

### Development Guidelines
- Follow PEP 8 style guidelines
- Write tests for new features
- Update documentation
- Use conventional commit messages

## 📚 Documentation

- **[CI/CD Documentation](docs/CICD.md)**: Detailed CI/CD pipeline information
- **[Infrastructure Guide](terraform/README.md)**: Terraform deployment guide

## 🆘 Troubleshooting

### Common Issues

**Application won't start:**
```bash
# Check Python dependencies
pip install -r requirements.txt

# Check database permissions
ls -la instance/patient.db
```

**Docker build fails:**
```bash
# Clear Docker cache
docker system prune -a

# Rebuild with no cache
docker build --no-cache -t patient-web-interface .
```

**Terraform deployment fails:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Validate Terraform configuration
terraform validate

# Check Terraform state
terraform show
```

### Support
- **Issues**: [GitHub Issues](https://github.com/AbdallahBagato/Patient-Web-interface/issues)
- **Discussions**: [GitHub Discussions](https://github.com/AbdallahBagato/Patient-Web-interface/discussions)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flask community for the excellent web framework
- AWS for reliable cloud infrastructure
- Terraform for infrastructure as code
- Docker for containerization platform
- GitHub Actions for CI/CD automation

## 📈 Roadmap

- [ ] **Database Migration**: PostgreSQL/MySQL support
- [ ] **Authentication**: User login and role-based access
- [ ] **API Development**: RESTful API endpoints
- [ ] **Mobile App**: React Native mobile application
- [ ] **Advanced Search**: Elasticsearch integration
- [ ] **Reporting**: PDF generation and analytics
- [ ] **Internationalization**: Multi-language support
- [ ] **Kubernetes**: Container orchestration support

---

**Built with ❤️ by [Abdallah Bagato](https://github.com/AbdallahBagato)**
