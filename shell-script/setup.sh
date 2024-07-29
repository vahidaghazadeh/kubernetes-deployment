#!/bin/bash

set -e

# Update package list and install Docker
echo "Updating package list and installing Docker..."
sudo apt update
sudo apt install -y docker.io

# Remove unnecessary Docker packages
echo "Removing unnecessary Docker packages..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
  sudo apt-get remove -y $pkg
done

# Install required packages
echo "Installing required packages..."
sudo apt-get install -y ca-certificates curl gnupg

# Enable Docker service
echo "Enabling Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

# Add Kubernetes signing key
echo "Adding Kubernetes signing key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes repository
echo "Adding Kubernetes repository..."
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update package list after adding Kubernetes repository
echo "Updating package list after adding Kubernetes repository..."
sudo apt update

# Install Kubernetes tools
echo "Installing Kubernetes tools..."
sudo apt install -y kubeadm kubelet kubectl

# Hold Kubernetes packages to prevent automatic updates
echo "Holding Kubernetes packages..."
sudo apt-mark hold kubeadm kubelet kubectl

# Verify kubeadm installation
echo "Verifying kubeadm installation..."
kubeadm version

# Set hostname
if [ "$1" == "master" ]; then
  echo "Setting hostname for master node..."
  sudo hostnamectl set-hostname k8s-master
elif [[ "$1" =~ worker[0-9]+ ]]; then
  echo "Setting hostname for worker node..."
  sudo hostnamectl set-hostname "$1"
else
  echo "Invalid hostname. Please provide 'master' or 'worker[0-9]'."
  exit 1
fi

# Configure /etc/hosts on all nodes
echo "Configuring /etc/hosts..."
echo "192.168.1.10 k8s-master" | sudo tee -a /etc/hosts
echo "192.168.1.11 k8s-worker01" | sudo tee -a /etc/hosts
echo "192.168.1.12 k8s-worker02" | sudo tee -a /etc/hosts

if [ "$1" == "master" ]; then
  # Initialize Kubernetes on master node
  echo "Initializing Kubernetes on master node..."
  kubeadm init --control-plane-endpoint=k8s-master --upload-certs | tee kubeadm-init.log

  # Create .kube directory
  echo "Creating .kube directory..."
  mkdir -p $HOME/.kube

  # Copy Kubernetes admin config
  echo "Copying Kubernetes admin config..."
  sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  # Set KUBECONFIG environment variable
  echo "Setting KUBECONFIG environment variable..."
  echo "export KUBECONFIG=$HOME/.kube/config" >> ~/.bashrc
  source ~/.bashrc

  # Deploy pod network
  echo "Deploying pod network..."
  kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

  # Untaint master node
  echo "Untainting master node..."
  kubectl taint nodes --all node-role.kubernetes.io/control-plane-

else
  # Join worker nodes to the cluster
  echo "Joining worker node to the cluster..."
  JOIN_COMMAND=$(grep -oP 'kubeadm join .* --token \S+ --discovery-token-ca-cert-hash \S+' kubeadm-init.log)
  sudo $JOIN_COMMAND
fi

echo "Kubernetes setup complete."
