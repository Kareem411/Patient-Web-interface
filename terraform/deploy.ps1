# Patient Web Interface - Infrastructure Deployment Script (PowerShell)
# This script helps deploy the Terraform infrastructure for the Patient Web Interface

param(
    [Parameter(Position=0)]
    [ValidateSet("deploy", "destroy", "status", "plan", "output", "help")]
    [string]$Command = "deploy"
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
    
    if (-not (Test-CommandExists "terraform")) {
        Write-Error "Terraform is not installed. Please install Terraform first."
        exit 1
    }
    
    if (-not (Test-CommandExists "aws")) {
        Write-Error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    }
    
    # Check AWS credentials
    try {
        aws sts get-caller-identity | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "AWS credentials check failed"
        }
    }
    catch {
        Write-Error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    }
    
    Write-Success "Prerequisites check passed!"
}

# Function to create terraform.tfvars if it doesn't exist
function New-TfVars {
    if (-not (Test-Path "terraform.tfvars")) {
        Write-Warning "terraform.tfvars not found. Creating from example..."
        Copy-Item "terraform.tfvars.example" "terraform.tfvars"
        
        Write-Warning "Please edit terraform.tfvars and update the following:"
        Write-Host "  - public_key: Your SSH public key"
        Write-Host "  - aws_region: Your preferred AWS region"
        Write-Host "  - docker_image: Your DockerHub image name"
        Write-Host "  - Other configuration as needed"
        Write-Host ""
        Read-Host "Press Enter to continue after editing terraform.tfvars"
    }
}

# Function to initialize Terraform
function Initialize-Terraform {
    Write-Status "Initializing Terraform..."
    terraform init
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform initialization failed!"
        exit 1
    }
    Write-Success "Terraform initialized successfully!"
}

# Function to validate Terraform configuration
function Test-TerraformConfig {
    Write-Status "Validating Terraform configuration..."
    terraform validate
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform configuration validation failed!"
        exit 1
    }
    Write-Success "Terraform configuration is valid!"
}

# Function to plan Terraform deployment
function New-TerraformPlan {
    Write-Status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform planning failed!"
        exit 1
    }
    
    Write-Host ""
    $response = Read-Host "Review the plan above. Do you want to proceed with deployment? (y/N)"
    if ($response -notmatch '^[Yy]$') {
        Write-Error "Deployment cancelled by user."
        exit 1
    }
}

# Function to apply Terraform configuration
function Invoke-TerraformApply {
    Write-Status "Applying Terraform configuration..."
    terraform apply tfplan
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform apply failed!"
        exit 1
    }
    Write-Success "Infrastructure deployed successfully!"
}

# Function to show outputs
function Show-Outputs {
    Write-Status "Deployment outputs:"
    terraform output
    
    Write-Host ""
    Write-Success "Application URL:"
    terraform output -raw application_url
    Write-Host ""
}

# Function to clean up plan file
function Remove-PlanFile {
    if (Test-Path "tfplan") {
        Remove-Item "tfplan" -Force
    }
}

# Function to deploy infrastructure
function Invoke-Deploy {
    Write-Status "Starting Patient Web Interface infrastructure deployment..."
    
    Test-Prerequisites
    New-TfVars
    Initialize-Terraform
    Test-TerraformConfig
    New-TerraformPlan
    Invoke-TerraformApply
    Show-Outputs
    Remove-PlanFile
    
    Write-Success "Deployment completed successfully!"
    Write-Status "You can now access your application at the URL shown above."
}

# Function to destroy infrastructure
function Invoke-Destroy {
    Write-Warning "This will destroy ALL infrastructure resources!"
    $confirmation = Read-Host "Are you sure you want to proceed? Type 'destroy' to confirm"
    
    if ($confirmation -ne "destroy") {
        Write-Error "Destruction cancelled."
        exit 1
    }
    
    Write-Status "Destroying infrastructure..."
    terraform destroy -auto-approve
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Terraform destroy failed!"
        exit 1
    }
    Write-Success "Infrastructure destroyed successfully!"
}

# Function to show status
function Show-Status {
    Write-Status "Current infrastructure status:"
    terraform show
}

# Function to show plan
function Show-Plan {
    Test-Prerequisites
    New-TfVars
    Initialize-Terraform
    Test-TerraformConfig
    terraform plan
}

# Function to show help
function Show-Help {
    Write-Host "Patient Web Interface - Infrastructure Deployment Script"
    Write-Host ""
    Write-Host "Usage: .\deploy.ps1 [COMMAND]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  deploy    Deploy the infrastructure (default)"
    Write-Host "  destroy   Destroy the infrastructure"
    Write-Host "  status    Show current infrastructure status"
    Write-Host "  plan      Show what changes would be made"
    Write-Host "  output    Show current outputs"
    Write-Host "  help      Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\deploy.ps1 deploy     # Deploy infrastructure"
    Write-Host "  .\deploy.ps1 destroy    # Destroy infrastructure"
    Write-Host "  .\deploy.ps1 status     # Show current status"
}

# Main script logic
try {
    switch ($Command) {
        "deploy" {
            Invoke-Deploy
        }
        "destroy" {
            Invoke-Destroy
        }
        "status" {
            Show-Status
        }
        "plan" {
            Show-Plan
        }
        "output" {
            terraform output
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
