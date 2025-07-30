#!/bin/bash

# Patient Web Interface - Kubernetes Deployment Script
# This script deploys the application to Minikube

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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists kubectl; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    if ! command_exists minikube; then
        print_error "Minikube is not installed. Please install Minikube first."
        exit 1
    fi
    
    # Check if Minikube is running
    if ! minikube status >/dev/null 2>&1; then
        print_warning "Minikube is not running. Starting Minikube..."
        minikube start --driver=docker --memory=2048 --cpus=2
    fi
    
    print_success "Prerequisites check passed!"
}

# Function to deploy application
deploy_application() {
    print_header "DEPLOYING PATIENT WEB INTERFACE TO KUBERNETES"
    
    # Apply namespace first
    print_status "Creating namespace..."
    kubectl apply -f deployment.yaml --validate=false || true
    
    # Wait for namespace to be ready
    kubectl wait --for=condition=Ready namespace/patient-web-interface --timeout=60s || true
    
    # Apply all manifests
    print_status "Applying Kubernetes manifests..."
    kubectl apply -f deployment.yaml
    kubectl apply -f ingress.yaml
    kubectl apply -f monitoring.yaml
    
    # Wait for deployment to be ready
    print_status "Waiting for deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/patient-web-interface -n patient-web-interface
    
    print_success "Application deployed successfully!"
}

# Function to check deployment status
check_deployment() {
    print_header "CHECKING DEPLOYMENT STATUS"
    
    print_status "Pods status:"
    kubectl get pods -n patient-web-interface -o wide
    
    echo ""
    print_status "Services status:"
    kubectl get services -n patient-web-interface
    
    echo ""
    print_status "Ingress status:"
    kubectl get ingress -n patient-web-interface
    
    echo ""
    print_status "HPA status:"
    kubectl get hpa -n patient-web-interface
}

# Function to setup port forwarding
setup_port_forwarding() {
    print_header "SETTING UP PORT FORWARDING"
    
    # Get service name
    SERVICE_NAME="patient-web-interface-service"
    NAMESPACE="patient-web-interface"
    LOCAL_PORT="8080"
    SERVICE_PORT="80"
    
    print_status "Setting up port forwarding..."
    print_warning "This will run in the background. Use 'pkill -f kubectl.*port-forward' to stop."
    
    # Kill any existing port-forward processes
    pkill -f "kubectl.*port-forward.*$SERVICE_NAME" || true
    
    # Start port forwarding in background
    kubectl port-forward service/$SERVICE_NAME $LOCAL_PORT:$SERVICE_PORT -n $NAMESPACE &
    
    # Give it a moment to start
    sleep 3
    
    print_success "Port forwarding setup complete!"
    print_status "Application is accessible at: http://localhost:$LOCAL_PORT"
    
    echo ""
    print_warning "To stop port forwarding, run:"
    echo "pkill -f 'kubectl.*port-forward.*$SERVICE_NAME'"
}

# Function to show logs
show_logs() {
    print_header "APPLICATION LOGS"
    
    print_status "Showing logs from all pods..."
    kubectl logs -f -l app=patient-web-interface -n patient-web-interface --max-log-requests=10
}

# Function to scale application
scale_application() {
    local replicas=${1:-3}
    
    print_header "SCALING APPLICATION"
    
    print_status "Scaling to $replicas replicas..."
    kubectl scale deployment patient-web-interface --replicas=$replicas -n patient-web-interface
    
    print_status "Waiting for scaling to complete..."
    kubectl wait --for=condition=available --timeout=300s deployment/patient-web-interface -n patient-web-interface
    
    print_success "Application scaled to $replicas replicas!"
    
    # Show updated status
    kubectl get pods -n patient-web-interface
}

# Function to update application
update_application() {
    local image=${1:-"abdallahbagato/patient-web-interface:latest"}
    
    print_header "UPDATING APPLICATION"
    
    print_status "Updating image to: $image"
    kubectl set image deployment/patient-web-interface patient-web-interface=$image -n patient-web-interface
    
    print_status "Waiting for rollout to complete..."
    kubectl rollout status deployment/patient-web-interface -n patient-web-interface --timeout=300s
    
    print_success "Application updated successfully!"
    
    # Show updated status
    kubectl get pods -n patient-web-interface
}

# Function to delete application
delete_application() {
    print_header "DELETING APPLICATION"
    
    print_warning "This will delete all application resources!"
    read -p "Are you sure? Type 'delete' to confirm: " confirmation
    
    if [ "$confirmation" != "delete" ]; then
        print_error "Deletion cancelled."
        exit 1
    fi
    
    print_status "Deleting application resources..."
    kubectl delete -f monitoring.yaml || true
    kubectl delete -f ingress.yaml || true
    kubectl delete -f deployment.yaml || true
    
    print_success "Application deleted successfully!"
}

# Function to open dashboard
open_dashboard() {
    print_header "OPENING KUBERNETES DASHBOARD"
    
    # Enable dashboard addon if not enabled
    minikube addons enable dashboard
    
    print_status "Opening Kubernetes dashboard..."
    print_warning "This will open in your default browser"
    
    minikube dashboard &
    
    print_success "Dashboard is starting up..."
}

# Function to get application URL
get_app_url() {
    print_header "APPLICATION ACCESS INFORMATION"
    
    # Check if ingress addon is enabled
    if ! minikube addons list | grep -q "ingress.*enabled"; then
        print_warning "Ingress addon is not enabled. Enabling it..."
        minikube addons enable ingress
        sleep 10
    fi
    
    # Get Minikube IP
    MINIKUBE_IP=$(minikube ip)
    
    echo ""
    print_status "Application Access Methods:"
    echo ""
    echo "1. Port Forwarding (Recommended for development):"
    echo "   kubectl port-forward service/patient-web-interface-service 8080:80 -n patient-web-interface"
    echo "   Access at: http://localhost:8080"
    echo ""
    echo "2. Minikube Service (opens in browser):"
    echo "   minikube service patient-web-interface-service -n patient-web-interface"
    echo ""
    echo "3. Ingress (if configured):"
    echo "   Add to /etc/hosts: $MINIKUBE_IP patient-web-interface.local"
    echo "   Access at: http://patient-web-interface.local"
    echo ""
    echo "4. Direct service access:"
    echo "   minikube service patient-web-interface-service -n patient-web-interface --url"
    echo ""
}

# Function to show help
show_help() {
    echo "Patient Web Interface - Kubernetes Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  deploy              Deploy the application (default)"
    echo "  status              Check deployment status"
    echo "  port-forward        Setup port forwarding to access the app"
    echo "  logs                Show application logs"
    echo "  scale [replicas]    Scale the application (default: 3)"
    echo "  update [image]      Update application image"
    echo "  delete              Delete the application"
    echo "  dashboard           Open Kubernetes dashboard"
    echo "  url                 Show application access URLs"
    echo "  help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy           # Deploy application"
    echo "  $0 port-forward     # Setup port forwarding"
    echo "  $0 scale 5          # Scale to 5 replicas"
    echo "  $0 update myimg:v2  # Update to new image"
    echo "  $0 logs             # Show logs"
}

# Main script logic
case "${1:-deploy}" in
    deploy)
        check_prerequisites
        deploy_application
        check_deployment
        get_app_url
        ;;
    status)
        check_deployment
        ;;
    port-forward)
        setup_port_forwarding
        ;;
    logs)
        show_logs
        ;;
    scale)
        scale_application $2
        ;;
    update)
        update_application $2
        ;;
    delete)
        delete_application
        ;;
    dashboard)
        open_dashboard
        ;;
    url)
        get_app_url
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
