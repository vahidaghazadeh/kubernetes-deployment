# Kubernetes Cluster Setup with Vagrant
This document provides step-by-step instructions for setting up a Kubernetes cluster using Vagrant and shell scripts. The Vagrantfile automates the creation and configuration of virtual machines (VMs) for both master and worker nodes.

### Prerequisites
- Vagrant installed on your local machine
- VirtualBox or another Vagrant-compatible provider installed
- Internet connection for downloading Vagrant boxes and packages

### Step 1: Prepare the Vagrantfile
1. Create a new directory for your Vagrant project and navigate into it:
   ```shell
   mkdir kubernetes-vagrant
   cd kubernetes-vagrant
   ```
2. Create a Vagrantfile in the project directory:
   ```shell
   touch Vagrantfile
   ```

3. Open the Vagrantfile in a text editor and paste the following configuration:
   ```ruby
   VAGRANTFILE_API_VERSION = "2"
   
   Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
       # Define the base box
       config.vm.box = "ubuntu/bionic64"
       
       # Create a master node
       config.vm.define "k8s-master" do |master|
           master.vm.hostname = "k8s-master"
           master.vm.network "private_network", ip: "192.168.56.10"
           master.vm.provision "shell", path: "kubernetes-setup.sh", args: ["master"]
       end
       
       # Create worker nodes
       (1..2).each do |i|
           config.vm.define "k8s-worker#{i}" do |worker|
               worker.vm.hostname = "k8s-worker#{i}"
               worker.vm.network "private_network", ip: "192.168.56.1#{i}"
               worker.vm.provision "shell", path: "kubernetes-setup.sh", args: ["worker0#{i}"]
           end
       end
       
       # Customize the amount of memory on the VM
       config.vm.provider "virtualbox" do |vb|
           vb.memory = "2048"
           vb.cpus = 2
       end
   end
   ```
### Step 2: Prepare the Shell Script
1. In the same project directory, create the shell script kubernetes-setup.sh:

    ```shell
    touch kubernetes-setup.sh
    ```
2. Open the shell script in a text editor and paste the following content:

    ```shell
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
    echo "192.168.56.10 k8s-master" | sudo tee -a /etc/hosts
    echo "192.168.56.11 k8s-worker01" | sudo tee -a /etc/hosts
    echo "192.168.56.12 k8s-worker02" | sudo tee -a /etc/hosts
    
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
    ```

3. Make the script executable:
    ```shell
    chmod +x kubernetes-setup.sh
    ```

### Step 3: Start the Vagrant Environment
1. Run the following command to start the VMs defined in the Vagrantfile:
    ```shell
    vagrant up
    ```
    This command will create and provision the master and worker nodes as defined in the Vagrantfile and kubernetes-setup.sh script.

### Step 4: Verify the Cluster
1. SSH into the master node:
    ```shell
    vagrant ssh k8s-master
    ```
2. Verify the nodes are connected and ready:
    ```shell
    kubectl get nodes
    ```
    The output should list the master and worker nodes with a status of Ready.

> [!TIP]
> By following this guide, you can quickly set up a Kubernetes cluster using Vagrant and shell scripts, ensuring consistency and reducing the potential for errors during manual configuration.

> [!Troubleshooting]
> If the master node initialization fails, review the kubeadm-init.log file for errors.
> Ensure that all nodes can communicate over the network and that the hostnames and IP addresses are correctly configured in /etc/hosts.
> If a worker node fails to join the cluster, check the join command and ensure the master node IP, token, and hash are correct.

> [!NOTE]
> This script assumes a static IP address setup. Adjust the /etc/hosts configuration as needed for your network setup.
> The script disables swap, which is required for Kubernetes to function correctly.
> By following this guide, you can quickly set up a Kubernetes cluster using a shell script, ensuring consistency and reducing the potential for errors during manual configuration.
