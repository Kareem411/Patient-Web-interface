#!/bin/bash

# Update system packages
apt-get update
apt-get upgrade -y

# Install Docker
apt-get install -y ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

# Create CloudWatch agent config
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "metrics": {
        "namespace": "CWAgent",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60,
                "totalcpu": false
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time",
                    "read_bytes",
                    "write_bytes",
                    "reads",
                    "writes"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            },
            "netstat": {
                "measurement": [
                    "tcp_established",
                    "tcp_time_wait"
                ],
                "metrics_collection_interval": 60
            },
            "swap": {
                "measurement": [
                    "swap_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Pull and run the Docker image
docker pull ${docker_image}

# Create a systemd service for the application
cat > /etc/systemd/system/patient-app.service << 'EOF'
[Unit]
Description=Patient Web Interface
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker run -d --name patient-app -p ${app_port}:${app_port} --restart unless-stopped ${docker_image}
ExecStop=/usr/bin/docker stop patient-app
ExecStopPost=/usr/bin/docker rm patient-app

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable patient-app.service
systemctl start patient-app.service

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube

# Install conntrack (required for Minikube)
apt-get install -y conntrack

# Start Minikube as ubuntu user (not root)
sudo -u ubuntu bash << 'EOF'
cd /home/ubuntu

# Set up environment variables
export MINIKUBE_HOME=/home/ubuntu/.minikube
export KUBECONFIG=/home/ubuntu/.kube/config

# Create necessary directories
mkdir -p /home/ubuntu/.minikube
mkdir -p /home/ubuntu/.kube

# Start Minikube with Docker driver
echo "Starting Minikube..."
minikube start --driver=docker --memory=2048 --cpus=2 --wait=all

# Enable necessary addons
echo "Enabling Minikube addons..."
minikube addons enable ingress
minikube addons enable dashboard
minikube addons enable metrics-server

# Configure kubectl context
kubectl config use-context minikube

# Verify installation
echo "Verifying Minikube installation..."
minikube status
kubectl get nodes
kubectl get pods -A

# Create kubernetes deployment directory and copy manifests
mkdir -p /home/ubuntu/k8s

# Test deployment - create a simple pod to verify everything works
echo "Testing Kubernetes functionality..."
kubectl run test-pod --image=nginx --restart=Never
kubectl wait --for=condition=Ready pod/test-pod --timeout=120s
kubectl get pod test-pod
kubectl delete pod test-pod

echo "Minikube setup completed successfully!"
echo "To deploy the Patient Web Interface:"
echo "1. Copy k8s manifests to /home/ubuntu/k8s/"
echo "2. Run: kubectl apply -f /home/ubuntu/k8s/"
echo "3. Access via: kubectl port-forward service/patient-web-interface-service 8080:80 -n patient-web-interface"
EOF

# Set proper ownership for ubuntu user directories
chown -R ubuntu:ubuntu /home/ubuntu/.minikube
chown -R ubuntu:ubuntu /home/ubuntu/.kube
chown -R ubuntu:ubuntu /home/ubuntu/k8s

# Install monitoring tools
apt-get install -y htop iotop nethogs

# Create log directory
mkdir -p /var/log/patient-app

# Setup log rotation
cat > /etc/logrotate.d/patient-app << 'EOF'
/var/log/patient-app/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 ubuntu ubuntu
}
EOF

echo "User data script completed successfully" > /var/log/user-data.log
