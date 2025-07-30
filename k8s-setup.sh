#!/bin/bash

# Patient Web Interface - Complete Kubernetes Setup Script
# This script sets up Minikube and deploys the application on EC2

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

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

# Function to check if running on EC2
check_ec2_environment() {
    print_status "Checking if running on EC2..."
    
    if curl -s --connect-timeout 5 http://169.254.169.254/latest/meta-data/ >/dev/null 2>&1; then
        print_success "Running on EC2 instance"
        return 0
    else
        print_warning "Not running on EC2, continuing with local setup"
        return 1
    fi
}

# Function to setup EC2 for Kubernetes
setup_ec2_kubernetes() {
    print_header "SETTING UP KUBERNETES ON EC2"
    
    print_status "Installing required packages..."
    sudo apt-get update
    sudo apt-get install -y curl wget git
    
    # Install Docker if not present
    if ! command -v docker >/dev/null 2>&1; then
        print_status "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        sudo systemctl start docker
        sudo systemctl enable docker
    fi
    
    # Install kubectl
    if ! command -v kubectl >/dev/null 2>&1; then
        print_status "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    fi
    
    # Install Minikube
    if ! command -v minikube >/dev/null 2>&1; then
        print_status "Installing Minikube..."
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        sudo install minikube-linux-amd64 /usr/local/bin/minikube
        rm minikube-linux-amd64
    fi
    
    # Install conntrack (required for Minikube)
    sudo apt-get install -y conntrack
    
    print_success "Kubernetes tools installation completed!"
}

# Function to start Minikube
start_minikube() {
    print_header "STARTING MINIKUBE"
    
    # Check if Minikube is already running
    if minikube status >/dev/null 2>&1; then
        print_warning "Minikube is already running"
        return 0
    fi
    
    print_status "Starting Minikube with Docker driver..."
    minikube start --driver=docker --memory=2048 --cpus=2 --wait=all
    
    print_status "Enabling necessary addons..."
    minikube addons enable ingress
    minikube addons enable dashboard
    minikube addons enable metrics-server
    
    print_status "Configuring kubectl context..."
    kubectl config use-context minikube
    
    print_status "Verifying Minikube installation..."
    minikube status
    kubectl get nodes
    
    print_success "Minikube started successfully!"
}

# Function to deploy application to Kubernetes
deploy_to_kubernetes() {
    print_header "DEPLOYING PATIENT WEB INTERFACE TO KUBERNETES"
    
    # Check if k8s directory exists
    if [ ! -d "k8s" ]; then
        print_error "Kubernetes manifests directory (k8s) not found!"
        print_status "Please ensure you're in the project root directory"
        exit 1
    fi
    
    cd k8s
    
    print_status "Applying Kubernetes manifests..."
    kubectl apply -f deployment.yaml
    kubectl apply -f ingress.yaml
    kubectl apply -f monitoring.yaml
    
    print_status "Waiting for deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/patient-web-interface -n patient-web-interface
    
    print_success "Application deployed to Kubernetes!"
    
    # Show deployment status
    print_status "Deployment status:"
    kubectl get all -n patient-web-interface
    
    cd ..
}

# Function to setup port forwarding
setup_port_forwarding() {
    print_header "SETTING UP APPLICATION ACCESS"
    
    SERVICE_NAME="patient-web-interface-service"
    NAMESPACE="patient-web-interface"
    LOCAL_PORT="8080"
    SERVICE_PORT="80"
    
    print_status "Application Access Methods:"
    echo ""
    echo "1. Port Forwarding (Recommended):"
    echo "   kubectl port-forward service/$SERVICE_NAME $LOCAL_PORT:$SERVICE_PORT -n $NAMESPACE"
    echo "   Then access: http://localhost:$LOCAL_PORT"
    echo ""
    echo "2. Minikube Service (Opens in browser):"
    echo "   minikube service $SERVICE_NAME -n $NAMESPACE"
    echo ""
    echo "3. Get service URL:"
    echo "   minikube service $SERVICE_NAME -n $NAMESPACE --url"
    echo ""
    
    # Get Minikube IP for ingress
    MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "N/A")
    if [ "$MINIKUBE_IP" != "N/A" ]; then
        echo "4. Ingress Access:"
        echo "   Add to /etc/hosts: $MINIKUBE_IP patient-web-interface.local"
        echo "   Then access: http://patient-web-interface.local"
        echo ""
    fi
    
    # Ask if user wants to start port forwarding
    read -p "Would you like to start port forwarding now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Starting port forwarding..."
        print_warning "Press Ctrl+C to stop port forwarding"
        kubectl port-forward service/$SERVICE_NAME $LOCAL_PORT:$SERVICE_PORT -n $NAMESPACE
    fi
}

# Function to show application status
show_application_status() {
    print_header "APPLICATION STATUS"
    
    print_status "Namespace resources:"
    kubectl get all -n patient-web-interface
    
    echo ""
    print_status "Pod details:"
    kubectl get pods -n patient-web-interface -o wide
    
    echo ""
    print_status "Service details:"
    kubectl describe service patient-web-interface-service -n patient-web-interface
    
    echo ""
    print_status "Ingress details:"
    kubectl get ingress -n patient-web-interface
    
    echo ""
    print_status "HPA status:"
    kubectl get hpa -n patient-web-interface
    
    echo ""
    print_status "Recent events:"
    kubectl get events -n patient-web-interface --sort-by='.lastTimestamp' | tail -10
}

# Function to show logs
show_application_logs() {
    print_header "APPLICATION LOGS"
    
    print_status "Showing logs from all Patient Web Interface pods..."
    kubectl logs -l app=patient-web-interface -n patient-web-interface --tail=50
    
    echo ""
    read -p "Would you like to follow logs in real-time? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Press Ctrl+C to stop following logs"
        kubectl logs -f -l app=patient-web-interface -n patient-web-interface
    fi
}

# Function to scale application
scale_application() {
    local replicas=${1:-3}
    
    print_header "SCALING APPLICATION"
    
    print_status "Current deployment scale:"
    kubectl get deployment patient-web-interface -n patient-web-interface
    
    print_status "Scaling to $replicas replicas..."
    kubectl scale deployment patient-web-interface --replicas=$replicas -n patient-web-interface
    
    print_status "Waiting for scaling to complete..."
    kubectl wait --for=condition=available --timeout=300s deployment/patient-web-interface -n patient-web-interface
    
    print_success "Application scaled to $replicas replicas!"
    kubectl get pods -n patient-web-interface
}

# Function to update application
update_application() {
    local image=${1:-"abdallahbagato/patient-web-interface:latest"}
    
    print_header "UPDATING APPLICATION"
    
    print_status "Current image:"
    kubectl get deployment patient-web-interface -n patient-web-interface -o jsonpath='{.spec.template.spec.containers[0].image}'
    echo ""
    
    print_status "Updating to image: $image"
    kubectl set image deployment/patient-web-interface patient-web-interface=$image -n patient-web-interface
    
    print_status "Waiting for rollout to complete..."
    kubectl rollout status deployment/patient-web-interface -n patient-web-interface --timeout=300s
    
    print_success "Application updated successfully!"
    kubectl get pods -n patient-web-interface
}

# Function to cleanup
cleanup_application() {
    print_header "CLEANING UP APPLICATION"
    
    print_warning "This will delete all application resources!"
    read -p "Are you sure? Type 'delete' to confirm: " confirmation
    
    if [ "$confirmation" != "delete" ]; then
        print_error "Cleanup cancelled."
        return
    fi
    
    print_status "Deleting application resources..."
    cd k8s
    kubectl delete -f monitoring.yaml || true
    kubectl delete -f ingress.yaml || true
    kubectl delete -f deployment.yaml || true
    cd ..
    
    print_success "Application resources deleted!"
}

# Function to show help
show_help() {
    echo "Patient Web Interface - Complete Kubernetes Setup Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  setup               Setup Kubernetes environment (EC2 or local)"
    echo "  start               Start Minikube"
    echo "  deploy              Deploy application to Kubernetes"
    echo "  access              Setup application access methods"
    echo "  status              Show application status"
    echo "  logs                Show application logs"
    echo "  scale [replicas]    Scale the application (default: 3)"
    echo "  update [image]      Update application image"
    echo "  cleanup             Delete application resources"
    echo "  full                Run complete setup and deployment"
    echo "  help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup            # Setup Kubernetes environment"
    echo "  $0 full             # Complete setup and deployment"
    echo "  $0 deploy           # Deploy application only"
    echo "  $0 access           # Show access methods and start port forwarding"
    echo "  $0 scale 5          # Scale to 5 replicas"
    echo "  $0 update myimg:v2  # Update to new image"
}

# Function to run complete setup
run_complete_setup() {
    print_header "PATIENT WEB INTERFACE - COMPLETE KUBERNETES SETUP"
    
    echo "This script will:"
    echo "  ✓ Setup Kubernetes environment (EC2 or local)"
    echo "  ✓ Start Minikube"
    echo "  ✓ Deploy Patient Web Interface to Kubernetes"
    echo "  ✓ Setup application access"
    echo ""
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Setup cancelled by user"
        exit 1
    fi
    
    # Check environment and setup accordingly
    if check_ec2_environment; then
        setup_ec2_kubernetes
    fi
    
    start_minikube
    deploy_to_kubernetes
    show_application_status
    setup_port_forwarding
    
    print_success "Complete setup finished successfully!"
}

# Main script logic
case "${1:-help}" in
    setup)
        if check_ec2_environment; then
            setup_ec2_kubernetes
        else
            print_status "Local environment detected. Please ensure Docker, kubectl, and Minikube are installed."
        fi
        ;;
    start)
        start_minikube
        ;;
    deploy)
        deploy_to_kubernetes
        ;;
    access)
        setup_port_forwarding
        ;;
    status)
        show_application_status
        ;;
    logs)
        show_application_logs
        ;;
    scale)
        scale_application $2
        ;;
    update)
        update_application $2
        ;;
    cleanup)
        cleanup_application
        ;;
    full)
        run_complete_setup
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
