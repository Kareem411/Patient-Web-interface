# Patient Web Interface - Kubernetes Deployment Script (PowerShell)
# This script deploys the application to Minikube

param(
    [Parameter(Position=0)]
    [ValidateSet("deploy", "status", "port-forward", "logs", "scale", "update", "delete", "dashboard", "url", "help")]
    [string]$Command = "deploy",
    
    [Parameter(Position=1)]
    [string]$Parameter
)

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Header {
    param([string]$Message)
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host $Message -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
}

# Function to check if command exists
function Test-CommandExists {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-Status "Checking prerequisites..."
    
    if (-not (Test-CommandExists "kubectl")) {
        Write-Error "kubectl is not installed. Please install kubectl first."
        exit 1
    }
    
    if (-not (Test-CommandExists "minikube")) {
        Write-Error "Minikube is not installed. Please install Minikube first."
        exit 1
    }
    
    # Check if Minikube is running
    try {
        minikube status | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Minikube is not running. Starting Minikube..."
            minikube start --driver=docker --memory=2048 --cpus=2
        }
    }
    catch {
        Write-Warning "Minikube is not running. Starting Minikube..."
        minikube start --driver=docker --memory=2048 --cpus=2
    }
    
    Write-Success "Prerequisites check passed!"
}

# Function to deploy application
function Invoke-DeployApplication {
    Write-Header "DEPLOYING PATIENT WEB INTERFACE TO KUBERNETES"
    
    # Apply namespace first
    Write-Status "Creating namespace..."
    kubectl apply -f deployment.yaml --validate=false
    
    # Wait for namespace to be ready
    kubectl wait --for=condition=Ready namespace/patient-web-interface --timeout=60s
    
    # Apply all manifests
    Write-Status "Applying Kubernetes manifests..."
    kubectl apply -f deployment.yaml
    kubectl apply -f ingress.yaml
    kubectl apply -f monitoring.yaml
    
    # Wait for deployment to be ready
    Write-Status "Waiting for deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/patient-web-interface -n patient-web-interface
    
    Write-Success "Application deployed successfully!"
}

# Function to check deployment status
function Get-DeploymentStatus {
    Write-Header "CHECKING DEPLOYMENT STATUS"
    
    Write-Status "Pods status:"
    kubectl get pods -n patient-web-interface -o wide
    
    Write-Host ""
    Write-Status "Services status:"
    kubectl get services -n patient-web-interface
    
    Write-Host ""
    Write-Status "Ingress status:"
    kubectl get ingress -n patient-web-interface
    
    Write-Host ""
    Write-Status "HPA status:"
    kubectl get hpa -n patient-web-interface
}

# Function to setup port forwarding
function Start-PortForwarding {
    Write-Header "SETTING UP PORT FORWARDING"
    
    $ServiceName = "patient-web-interface-service"
    $Namespace = "patient-web-interface"
    $LocalPort = "8080"
    $ServicePort = "80"
    
    Write-Status "Setting up port forwarding..."
    Write-Warning "This will run in the foreground. Press Ctrl+C to stop."
    
    # Kill any existing port-forward processes
    Get-Process | Where-Object {$_.ProcessName -eq "kubectl" -and $_.CommandLine -like "*port-forward*$ServiceName*"} | Stop-Process -Force -ErrorAction SilentlyContinue
    
    Write-Success "Port forwarding setup complete!"
    Write-Status "Application will be accessible at: http://localhost:$LocalPort"
    Write-Status "Starting port forwarding..."
    
    # Start port forwarding
    kubectl port-forward service/$ServiceName ${LocalPort}:$ServicePort -n $Namespace
}

# Function to show logs
function Show-Logs {
    Write-Header "APPLICATION LOGS"
    
    Write-Status "Showing logs from all pods..."
    kubectl logs -f -l app=patient-web-interface -n patient-web-interface --max-log-requests=10
}

# Function to scale application
function Set-ApplicationScale {
    param([int]$Replicas = 3)
    
    Write-Header "SCALING APPLICATION"
    
    Write-Status "Scaling to $Replicas replicas..."
    kubectl scale deployment patient-web-interface --replicas=$Replicas -n patient-web-interface
    
    Write-Status "Waiting for scaling to complete..."
    kubectl wait --for=condition=available --timeout=300s deployment/patient-web-interface -n patient-web-interface
    
    Write-Success "Application scaled to $Replicas replicas!"
    
    # Show updated status
    kubectl get pods -n patient-web-interface
}

# Function to update application
function Update-Application {
    param([string]$Image = "abdallahbagato/patient-web-interface:latest")
    
    Write-Header "UPDATING APPLICATION"
    
    Write-Status "Updating image to: $Image"
    kubectl set image deployment/patient-web-interface patient-web-interface=$Image -n patient-web-interface
    
    Write-Status "Waiting for rollout to complete..."
    kubectl rollout status deployment/patient-web-interface -n patient-web-interface --timeout=300s
    
    Write-Success "Application updated successfully!"
    
    # Show updated status
    kubectl get pods -n patient-web-interface
}

# Function to delete application
function Remove-Application {
    Write-Header "DELETING APPLICATION"
    
    Write-Warning "This will delete all application resources!"
    $confirmation = Read-Host "Are you sure? Type 'delete' to confirm"
    
    if ($confirmation -ne "delete") {
        Write-Error "Deletion cancelled."
        exit 1
    }
    
    Write-Status "Deleting application resources..."
    kubectl delete -f monitoring.yaml
    kubectl delete -f ingress.yaml
    kubectl delete -f deployment.yaml
    
    Write-Success "Application deleted successfully!"
}

# Function to open dashboard
function Open-Dashboard {
    Write-Header "OPENING KUBERNETES DASHBOARD"
    
    # Enable dashboard addon if not enabled
    minikube addons enable dashboard
    
    Write-Status "Opening Kubernetes dashboard..."
    Write-Warning "This will open in your default browser"
    
    Start-Process -NoNewWindow minikube -ArgumentList "dashboard"
    
    Write-Success "Dashboard is starting up..."
}

# Function to get application URL
function Get-ApplicationUrl {
    Write-Header "APPLICATION ACCESS INFORMATION"
    
    # Check if ingress addon is enabled
    $ingressEnabled = minikube addons list | Select-String "ingress.*enabled"
    if (-not $ingressEnabled) {
        Write-Warning "Ingress addon is not enabled. Enabling it..."
        minikube addons enable ingress
        Start-Sleep 10
    }
    
    # Get Minikube IP
    $MinikubeIP = minikube ip
    
    Write-Host ""
    Write-Status "Application Access Methods:"
    Write-Host ""
    Write-Host "1. Port Forwarding (Recommended for development):"
    Write-Host "   kubectl port-forward service/patient-web-interface-service 8080:80 -n patient-web-interface"
    Write-Host "   Access at: http://localhost:8080"
    Write-Host ""
    Write-Host "2. Minikube Service (opens in browser):"
    Write-Host "   minikube service patient-web-interface-service -n patient-web-interface"
    Write-Host ""
    Write-Host "3. Ingress (if configured):"
    Write-Host "   Add to C:\Windows\System32\drivers\etc\hosts: $MinikubeIP patient-web-interface.local"
    Write-Host "   Access at: http://patient-web-interface.local"
    Write-Host ""
    Write-Host "4. Direct service access:"
    Write-Host "   minikube service patient-web-interface-service -n patient-web-interface --url"
    Write-Host ""
}

# Function to show help
function Show-Help {
    Write-Host "Patient Web Interface - Kubernetes Deployment Script"
    Write-Host ""
    Write-Host "Usage: .\deploy.ps1 [COMMAND] [OPTIONS]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  deploy              Deploy the application (default)"
    Write-Host "  status              Check deployment status"
    Write-Host "  port-forward        Setup port forwarding to access the app"
    Write-Host "  logs                Show application logs"
    Write-Host "  scale [replicas]    Scale the application (default: 3)"
    Write-Host "  update [image]      Update application image"
    Write-Host "  delete              Delete the application"
    Write-Host "  dashboard           Open Kubernetes dashboard"
    Write-Host "  url                 Show application access URLs"
    Write-Host "  help                Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\deploy.ps1 deploy           # Deploy application"
    Write-Host "  .\deploy.ps1 port-forward     # Setup port forwarding"
    Write-Host "  .\deploy.ps1 scale 5          # Scale to 5 replicas"
    Write-Host "  .\deploy.ps1 update myimg:v2  # Update to new image"
    Write-Host "  .\deploy.ps1 logs             # Show logs"
}

# Main script logic
try {
    switch ($Command) {
        "deploy" {
            Test-Prerequisites
            Invoke-DeployApplication
            Get-DeploymentStatus
            Get-ApplicationUrl
        }
        "status" {
            Get-DeploymentStatus
        }
        "port-forward" {
            Start-PortForwarding
        }
        "logs" {
            Show-Logs
        }
        "scale" {
            $replicas = if ($Parameter) { [int]$Parameter } else { 3 }
            Set-ApplicationScale -Replicas $replicas
        }
        "update" {
            $image = if ($Parameter) { $Parameter } else { "abdallahbagato/patient-web-interface:latest" }
            Update-Application -Image $image
        }
        "delete" {
            Remove-Application
        }
        "dashboard" {
            Open-Dashboard
        }
        "url" {
            Get-ApplicationUrl
        }
        "help" {
            Show-Help
        }
        default {
            Write-Error "Unknown command: $Command"
            Show-Help
            exit 1
        }
    }
}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}
