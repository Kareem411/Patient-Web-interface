#!/bin/bash

# Patient Web Interface - Complete Setup Script
# This script sets up the entire project including development environment and infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${PURPLE}========================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}========================================${NC}"
}

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

# Function to install Docker (Ubuntu/Debian)
install_docker() {
    print_status "Installing Docker..."
    
    # Update package index
    sudo apt-get update
    
    # Install dependencies
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Set up repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    print_success "Docker installed successfully!"
    print_warning "Please log out and log back in for Docker group changes to take effect."
}

# Function to install Terraform
install_terraform() {
    print_status "Installing Terraform..."
    
    # Download and install Terraform
    TERRAFORM_VERSION="1.6.4"
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt-get update && sudo apt-get install -y terraform
    
    print_success "Terraform installed successfully!"
}

# Function to install AWS CLI
install_aws_cli() {
    print_status "Installing AWS CLI..."
    
    # Download and install AWS CLI
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
    
    print_success "AWS CLI installed successfully!"
}

# Function to install Python and pip
install_python() {
    print_status "Installing Python and pip..."
    
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip python3-venv
    
    print_success "Python and pip installed successfully!"
}

# Function to check and install prerequisites
check_and_install_prerequisites() {
    print_header "CHECKING AND INSTALLING PREREQUISITES"
    
    # Update system
    print_status "Updating system packages..."
    sudo apt-get update && sudo apt-get upgrade -y
    
    # Install basic tools
    sudo apt-get install -y curl wget unzip git vim nano
    
    # Check and install Python
    if ! command_exists python3; then
        install_python
    else
        print_success "Python3 is already installed"
    fi
    
    # Check and install Docker
    if ! command_exists docker; then
        install_docker
    else
        print_success "Docker is already installed"
    fi
    
    # Check and install Terraform
    if ! command_exists terraform; then
        install_terraform
    else
        print_success "Terraform is already installed"
    fi
    
    # Check and install AWS CLI
    if ! command_exists aws; then
        install_aws_cli
    else
        print_success "AWS CLI is already installed"
    fi
    
    print_success "All prerequisites are installed!"
}

# Function to setup development environment
setup_dev_environment() {
    print_header "SETTING UP DEVELOPMENT ENVIRONMENT"
    
    # Navigate to project directory
    cd project
    
    # Create virtual environment
    print_status "Creating Python virtual environment..."
    python3 -m venv venv
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Install Python dependencies
    print_status "Installing Python dependencies..."
    pip install --upgrade pip
    pip install -r requirements.txt
    
    print_success "Development environment setup complete!"
    
    # Return to parent directory
    cd ..
}

# Function to setup Docker environment
setup_docker_environment() {
    print_header "SETTING UP DOCKER ENVIRONMENT"
    
    # Navigate to project directory
    cd project
    
    # Build Docker image
    print_status "Building Docker image..."
    docker build -t patient-web-interface:local .
    
    print_success "Docker image built successfully!"
    
    # Return to parent directory
    cd ..
}

# Function to generate SSH key
generate_ssh_key() {
    print_header "GENERATING SSH KEY FOR AWS"
    
    if [ ! -f ~/.ssh/id_rsa ]; then
        print_status "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -C "patient-web-interface" -f ~/.ssh/id_rsa -N ""
        print_success "SSH key generated successfully!"
    else
        print_warning "SSH key already exists"
    fi
    
    # Display public key
    print_status "Your SSH public key (copy this for terraform.tfvars):"
    echo "----------------------------------------"
    cat ~/.ssh/id_rsa.pub
    echo "----------------------------------------"
}

# Function to configure AWS credentials
configure_aws() {
    print_header "CONFIGURING AWS CREDENTIALS"
    
    print_status "Please configure your AWS credentials..."
    print_warning "You'll need your AWS Access Key ID and Secret Access Key"
    
    aws configure
    
    # Test AWS connection
    print_status "Testing AWS connection..."
    if aws sts get-caller-identity >/dev/null 2>&1; then
        print_success "AWS credentials configured successfully!"
    else
        print_error "AWS credential configuration failed. Please check your credentials."
        exit 1
    fi
}

# Function to setup Terraform
setup_terraform() {
    print_header "SETTING UP TERRAFORM"
    
    # Navigate to terraform directory
    cd terraform
    
    # Create terraform.tfvars from example
    if [ ! -f terraform.tfvars ]; then
        print_status "Creating terraform.tfvars from example..."
        cp terraform.tfvars.example terraform.tfvars
        
        # Get public key content
        PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub)
        
        # Replace placeholder in terraform.tfvars
        sed -i "s|ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC.*|$PUBLIC_KEY|" terraform.tfvars
        
        print_warning "Please review and edit terraform.tfvars if needed"
        print_warning "Default values are set, but you may want to customize:"
        echo "  - aws_region (currently: us-east-1)"
        echo "  - instance_type (currently: t3.micro)"
        echo "  - docker_image (currently: abdallahbagato/patient-web-interface:latest)"
    else
        print_warning "terraform.tfvars already exists"
    fi
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    print_success "Terraform setup complete!"
    
    # Return to parent directory
    cd ..
}

# Function to setup GitHub Actions
setup_github_actions() {
    print_header "GITHUB ACTIONS SETUP INSTRUCTIONS"
    
    print_status "To complete the CI/CD setup, you need to:"
    echo ""
    echo "1. Push this code to a GitHub repository"
    echo "2. Go to your repository settings → Secrets and variables → Actions"
    echo "3. Add the following repository secrets:"
    echo ""
    echo "   DOCKER_USERNAME - Your Docker Hub username"
    echo "   DOCKER_PASSWORD - Your Docker Hub password/token"
    echo "   AWS_ACCESS_KEY_ID - Your AWS access key"
    echo "   AWS_SECRET_ACCESS_KEY - Your AWS secret key"
    echo "   TF_VAR_public_key - Your SSH public key (shown below)"
    echo ""
    echo "4. Your SSH public key for TF_VAR_public_key:"
    echo "----------------------------------------"
    cat ~/.ssh/id_rsa.pub
    echo "----------------------------------------"
    echo ""
}

# Function to display next steps
show_next_steps() {
    print_header "NEXT STEPS"
    
    echo "Your Patient Web Interface project is now set up! Here's what you can do:"
    echo ""
    echo "1. DEVELOPMENT:"
    echo "   cd project && source venv/bin/activate"
    echo "   python main.py  # Run the application locally"
    echo ""
    echo "2. DOCKER TESTING:"
    echo "   cd project"
    echo "   docker run -p 5000:5000 patient-web-interface:local"
    echo ""
    echo "3. INFRASTRUCTURE DEPLOYMENT:"
    echo "   cd terraform"
    echo "   ./deploy.sh deploy  # Deploy to AWS"
    echo ""
    echo "4. BUILD AND PUSH TO DOCKER HUB:"
    echo "   cd project"
    echo "   docker build -t yourusername/patient-web-interface:latest ."
    echo "   docker push yourusername/patient-web-interface:latest"
    echo ""
    echo "5. ACCESS POINTS:"
    echo "   - Local development: http://localhost:5000"
    echo "   - After AWS deployment: Check terraform output for Load Balancer URL"
    echo ""
    echo "6. MONITORING:"
    echo "   - AWS CloudWatch for infrastructure monitoring"
    echo "   - Application logs via Docker logs"
    echo ""
    
    print_success "Setup completed successfully!"
}

# Function to run all setup steps
run_full_setup() {
    print_header "PATIENT WEB INTERFACE - COMPLETE SETUP"
    print_status "This script will set up the complete development and deployment environment"
    
    echo "This script will:"
    echo "  ✓ Install prerequisites (Docker, Terraform, AWS CLI, Python)"
    echo "  ✓ Set up development environment"
    echo "  ✓ Build Docker image"
    echo "  ✓ Generate SSH keys"
    echo "  ✓ Configure AWS credentials"
    echo "  ✓ Setup Terraform"
    echo "  ✓ Provide GitHub Actions setup instructions"
    echo ""
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Setup cancelled by user"
        exit 1
    fi
    
    check_and_install_prerequisites
    setup_dev_environment
    setup_docker_environment
    generate_ssh_key
    configure_aws
    setup_terraform
    setup_github_actions
    show_next_steps
}

# Function to show help
show_help() {
    echo "Patient Web Interface - Complete Setup Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  full      Run complete setup (default)"
    echo "  prereq    Install prerequisites only"
    echo "  dev       Setup development environment only"
    echo "  docker    Setup Docker environment only"
    echo "  aws       Configure AWS credentials only"
    echo "  terraform Setup Terraform only"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0          # Run full setup"
    echo "  $0 prereq   # Install prerequisites only"
    echo "  $0 dev      # Setup development environment only"
}

# Main script logic
case "${1:-full}" in
    full)
        run_full_setup
        ;;
    prereq)
        check_and_install_prerequisites
        ;;
    dev)
        setup_dev_environment
        ;;
    docker)
        setup_docker_environment
        ;;
    aws)
        configure_aws
        ;;
    terraform)
        setup_terraform
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
