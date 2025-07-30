#!/bin/bash

# Patient Web Interface - Infrastructure Deployment Script
# This script helps deploy the Terraform infrastructure for the Patient Web Interface

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists terraform; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    if ! command_exists aws; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "Prerequisites check passed!"
}

# Function to create terraform.tfvars if it doesn't exist
create_tfvars() {
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Creating from example..."
        cp terraform.tfvars.example terraform.tfvars
        
        print_warning "Please edit terraform.tfvars and update the following:"
        echo "  - public_key: Your SSH public key"
        echo "  - aws_region: Your preferred AWS region"
        echo "  - docker_image: Your DockerHub image name"
        echo "  - Other configuration as needed"
        echo ""
        echo "Press Enter to continue after editing terraform.tfvars..."
        read -r
    fi
}

# Function to initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    terraform init
    print_success "Terraform initialized successfully!"
}

# Function to validate Terraform configuration
validate_terraform() {
    print_status "Validating Terraform configuration..."
    terraform validate
    print_success "Terraform configuration is valid!"
}

# Function to plan Terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    
    echo ""
    print_warning "Review the plan above. Do you want to proceed with deployment? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_error "Deployment cancelled by user."
        exit 1
    fi
}

# Function to apply Terraform configuration
apply_terraform() {
    print_status "Applying Terraform configuration..."
    terraform apply tfplan
    print_success "Infrastructure deployed successfully!"
}

# Function to show outputs
show_outputs() {
    print_status "Deployment outputs:"
    terraform output
    
    echo ""
    print_success "Application URL:"
    terraform output -raw application_url
    echo ""
}

# Function to clean up plan file
cleanup() {
    if [ -f "tfplan" ]; then
        rm tfplan
    fi
}

# Function to deploy infrastructure
deploy() {
    print_status "Starting Patient Web Interface infrastructure deployment..."
    
    check_prerequisites
    create_tfvars
    init_terraform
    validate_terraform
    plan_terraform
    apply_terraform
    show_outputs
    cleanup
    
    print_success "Deployment completed successfully!"
    print_status "You can now access your application at the URL shown above."
}

# Function to destroy infrastructure
destroy() {
    print_warning "This will destroy ALL infrastructure resources!"
    print_warning "Are you sure you want to proceed? Type 'destroy' to confirm:"
    read -r confirmation
    
    if [ "$confirmation" != "destroy" ]; then
        print_error "Destruction cancelled."
        exit 1
    fi
    
    print_status "Destroying infrastructure..."
    terraform destroy -auto-approve
    print_success "Infrastructure destroyed successfully!"
}

# Function to show status
status() {
    print_status "Current infrastructure status:"
    terraform show
}

# Function to show help
show_help() {
    echo "Patient Web Interface - Infrastructure Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy    Deploy the infrastructure (default)"
    echo "  destroy   Destroy the infrastructure"
    echo "  status    Show current infrastructure status"
    echo "  plan      Show what changes would be made"
    echo "  output    Show current outputs"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy     # Deploy infrastructure"
    echo "  $0 destroy    # Destroy infrastructure"
    echo "  $0 status     # Show current status"
}

# Main script logic
case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    destroy)
        destroy
        ;;
    status)
        status
        ;;
    plan)
        check_prerequisites
        create_tfvars
        init_terraform
        validate_terraform
        terraform plan
        ;;
    output)
        terraform output
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
