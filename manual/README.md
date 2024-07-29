# Installation and deployment of Kubernetes
Containers have become very popular with several advantages such as project execution independent of infrastructure. The Kubernetes platform was introduced by Google and has become one of the main tools for deploying and managing container applications. In this article, we explain how to install and deploy Kubernetes; So stay with us until the end.

## Installation
1. Update the package list:
```shell
sudo apt update
```
2. Install Docker with the following command:

```shell
sudo apt install docker.io -y
```
3. Set Docker to launch on boot by entering:
```shell
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
```
```shell
sudo apt-get install ca-certificates curl gnupg -y
```
```shell
sudo systemctl enable docker
```

4. Verify Docker is running:
```shell
sudo systemctl status docker
```
5. If Docker is not running, start it with the following command:
```shell
   sudo systemctl start docker
```

## Install Kubernetes
Setting up Kubernetes on an Ubuntu system involves adding the Kubernetes repository to the APT sources list and installing the relevant tools. Follow the steps below to install Kubernetes on all the nodes in your cluster.
### Step 1: Add Kubernetes Signing Key
Since Kubernetes comes from a non-standard repository, download the signing key to ensure the software is authentic.
```shell
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```
### Step 2: Add Software Repositories
Kubernetes is not included in the default Ubuntu repositories. To add the Kubernetes repository to your list, enter this command on each node:
```shell
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```
Ensure all packages are up to date:
```shell
sudo apt update
```

> [!NOTE]
> 
> If you have limited access to the [pkgs.k8s](https://www.pkgs.k8s.io) repository, you can use dns services, and if the dns service does not remove the access limitation, you can use dl.k8s.io to get the binary file.
> ### Install kubectl binary with curl on Linux
> 1. **Download the latest release with the command:**
> ```shell
> curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
> ```
>
> [!NOTE]
> To download a specific version, replace the 
> ```shell 
> $(curl -L -s https://dl.k8s.io/release/stable.txt)
> ```
> portion of the command with the specific version.
> 
> For example, to download version 1.30.0 on Linux x86-64, type:
> ```shell
> curl -LO https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl
> ```
> 2. **Validate the binary (optional)**
> Download the kubectl checksum file:
> ```shell
> curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
> ```
> Validate the kubectl binary against the checksum file:
> ```shell
> echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
> ```
> If valid, the output is:
> > kubectl: OK
> 
> If the check fails, sha256 exits with nonzero status and prints output similar to:
> 
> > kubectl: FAILED
> > sha256sum: WARNING: 1 computed checksum did NOT match
> 
> 3. **Install kubectl**
> ```shell
> sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
> ```
> > [!NOTE]
> >
> > If you do not have root access on the target system, you can still install kubectl to the ~/.local/bin directory:
> > ```shell
> > chmod +x kubectl
> > mkdir -p ~/.local/bin
> > mv ./kubectl ~/.local/bin/kubectl
> > # and then append (or prepend) ~/.local/bin to $PATH
> > ```
> 
> 4 **Test to ensure the version you installed is up-to-date:**
> ```shell
> kubectl version --client
> ```
> Or use this for detailed view of version:
> ```shell
> kubectl version --client --output=yaml
> ```

### Step 3: Install Kubernetes Tools
***Each Kubernetes deployment consists of three separate tools:***

- ***Kubeadm***. A tool that initializes a Kubernetes cluster by fast-tracking the setup using community-sourced best practices.
- ***Kubelet***. The work package that runs on every node and starts containers. The tool gives you command-line access to clusters.
- ***Kubectl***. The command-line interface for interacting with clusters.

Execute the following commands on each server node to install the Kubernetes tools:
1. Run the install command:
```shell
sudo apt install kubeadm kubelet kubectl
```
2. Mark the packages as held back to prevent automatic installation, upgrade, or removal:
```shell 
sudo apt-mark hold kubeadm kubelet kubectl
```
> [!NOTE]
> 
> The process presented in this tutorial prevents APT from automatically updating Kubernetes. For instructions on how to update, please see the official
> 
> [developers' instructions](https://kubernetes.io/docs/tasks/).
> 
3. Verify the installation with:
```shell
kubeadm version
```

## Deploy Kubernetes
With the necessary tools installed, proceed to deploy the cluster. Follow the steps below to make the necessary system adjustments, initialize the cluster, and join worker nodes.

### Step 1: Prepare for Kubernetes Deployment

This section shows you how to prepare the servers for a Kubernetes deployment. Execute the steps below on each server node:

1. Disable all swap spaces with the swapoff command:
> Swap space in Linux is an extension of physical RAM, offering virtual memory that helps maintain system stability and performance. It allows processes to continue running when RAM is fully used and prevents memory errors.
> 
> Swap space also enables hibernation and safeguards critical processes by temporarily offloading data. However, it should only be a complement to RAM because a system that relies on swap would suffer significant performance degradation.
> Swap space (also known as swap memory or paging space) is space on a hard drive (HDD or SSD) that represents a substitute for physical (RAM) memory. This feature allows an operating system to temporarily move inactive or less frequently used memory pages from RAM to a designated area on the hard drive
>
> Swap frees up RAM for more important tasks that require more processing power by transferring data to and from a designated disk space. The data interchange is called swapping, while the designated space is called swap space. The swapping rate and assertiveness are determined by a parameter called swappiness.
>
> Operating systems like Windows or Linux provide a certain amount of swap space by default, which users can later change in accordance with their requirements. Users can also disable swap space, but that means that the kernel must kill some processes to create enough free RAM for new processes.
```shell
sudo swapoff -a
```
Then use the sed command below to make the necessary adjustments to the /etc/fstab file:
```shell
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```
Then use the sed command below to make the necessary adjustments to the /etc/fstab file:
```shell
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

2. Load the required containerd modules. Start by opening the containerd configuration file in a text editor, such as nano:
```shell
sudo nano /etc/modules-load.d/containerd.conf
```
3. Add the following two lines to the file:
```shell
overlay
br_netfilter
```
Save the file and exit.

4. Next, use the modprobe command to add the modules:
> The Linux kernel has a modular design. Functionality is extendible with modules or drivers. Use the modprobe command to add or remove modules on Linux. The command works intelligently and adds any dependent modules automatically.
>
> The kernel uses modprobe to request modules. The modprobe command searches through the standard installed module directories to find the necessary drivers.
>
```shell
sudo modprobe overlay
```
```shell
sudo modprobe br_netfilter
```
5. Open the kubernetes.conf file to configure Kubernetes networking:
```shell
sudo nano /etc/sysctl.d/kubernetes.conf
```

5. Open the kubernetes.conf file to configure Kubernetes networking:
```shell
sudo nano /etc/sysctl.d/kubernetes.conf
```
6. Add the following lines to the file:
```shell
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
```
Save the file and exit.

7. Reload the configuration by typing:
```shell
sudo sysctl --system
```
You should see the configuration in the output
> *Applying /etc/sysctl.d/99-sysctl.conf ...
> 
> *Applying /etc/sysctl.d/kubernetes.conf ...
> 
>net.bridge.bridge-nf-call-ip6tables = 1
> 
>net.bridge.bridge-nf-call-iptables = 1
> 
>net.ipv4.ip_forward = 1


### Step 2: Assign Unique Hostname for Each Server Node
1. Decide which server will be the master node. Then, enter the command on that node to name it accordingly:
```shell
sudo hostnamectl set-hostname k8s-master
```
2. Next, set the hostname on the first worker node by entering the following command:
```shell
sudo hostnamectl set-hostname k8s-worker01
```
If you have additional worker nodes, use this process to set a unique hostname on each.

Edit the hosts file on each node by adding the IP addresses and hostnames of the servers that will be part of the cluster.
> 192.168.1.10 k8s-master
> 
> 192.168.1.11 k8s-worker01
4. Restart the terminal application to apply the hostname change.


### Step 3: Initialize Kubernetes on Master Node
Once you finish setting up hostnames on cluster nodes, switch to the master node and follow the steps to initialize Kubernetes on it:

1. Open the kubelet file in a text editor.
```shell
sudo nano /etc/default/kubelet
```
2. Add the following line to the file:
```shell
KUBELET_EXTRA_ARGS="--cgroup-driver=cgroupfs"
```
Save and exit.

3. Reload the configuration and restart the kubelet:
```shell
sudo systemctl daemon-reload && sudo systemctl restart kubelet
```
4. Open the Docker daemon configuration file:
```shell
sudo nano /etc/docker/daemon.json
```
5. Append the following configuration block:
```json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  }, 
  "storage-driver": "overlay2"
}
```
Save the file and exit.
6. Reload the configuration and restart Docker:
```shell
sudo systemctl daemon-reload && sudo systemctl restart docker
```
7. Open the kubeadm configuration file:
```shell
sudo nano /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
```
8. Add the following line to the file:
```shell
sudo nano /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
```
8. Add the following line to the file:
```shell
sudo nano /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
```
```shell
Environment="KUBELET_EXTRA_ARGS=--fail-swap-on=false"
```
> [!NOTE]
> If the kubelet.service.d directory was not created, you can create the kubelet service directory and file.
> ```shell
> sudo mkdir /etc/systemd/system/kubelet.service.d
> ```
> ```shell
> sudo nano /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
> ```
> After creating the 10-kubeadm.conf file, put the following configuration in the file
> ``` 
> [Service]
> Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
> Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
> Environment="KUBELET_EXTRA_ARGS=--fail-swap-on=false"
> # This is a file that "kubeadm init" and "kubeadm join" generate at runtime, populating
> # the KUBELET_KUBEADM_ARGS variable dynamically
> EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env
> # This is a file that the user can use for overrides of the kubelet args as a last resort. Preferably,
> # the user should use the .NodeRegistration.KubeletExtraArgs object in the configuration files instead.
> # KUBELET_EXTRA_ARGS should be sourced from this file.
> EnvironmentFile=-/etc/default/kubelet
> ExecStart=
> ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS
> ```
Save the file and exit.

9. Reload the configuration and restart the kubelet:
```shell
sudo systemctl daemon-reload && sudo systemctl restart kubelet
```
10. Finally, initialize the cluster by typing:
```shell
sudo kubeadm init --control-plane-endpoint=k8s-master --upload-certs
```

***Once the operation finishes, the output displays a kubeadm join command at the bottom. Make a note of this command, as you will use it to join the worker nodes to the cluster.***
```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of the control-plane node running the following command on each as root:

  kubeadm join k8s-master:6443 --token v2e54c.928liszww0ocrfgi \
	--discovery-token-ca-cert-hash sha256:b82240e87495f1c4870bfba31210279c38e580ecd46793eb35855699decd1dc8 \
	--control-plane --certificate-key 9d18674d48476aa7246b799d6923ccdc7c3beffa1a060cb9c87f74fd93619681

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join k8s-master:6443 --token v2e54c.928liszww0ocrfgi \
	--discovery-token-ca-cert-hash sha256:b82240e87495f1c4870bfba31210279c38e580ecd46793eb35855699decd1dc8 
```
11. Create a directory for the Kubernetes cluster:
```shell
mkdir -p $HOME/.kube

```
12. Copy the configuration file to the directory:
```shell
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
```
> [!NOTE]
> If the admin.conf file does not exist in the path, copy the ***kubelet.conf*** file from the ***etc/kubernetes*** path
> ```shell
> mv /etc/kubernetes/kubelet.conf /etc/kubernetes/admin.conf
> ```
>  ```shell
> sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
> ```
>

## Step 4: Deploy Pod Network to Cluster
A pod network is a way to allow communication between different nodes in the cluster. This tutorial uses the Flannel node network manager to create a pod network.

Apply the Flannel manager to the master node by executing the steps below:

1. Use kubectl to install Flannel:
```shell
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```
2. Untaint the node:
```shell
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```
## Step 5: Join Worker Node to Cluster
Repeat the following steps on each worker node to create a cluster:

1. Stop and disable AppArmor:
```shell
sudo systemctl stop apparmor && sudo systemctl disable apparmor
```
2. Restart containerd:
```shell
sudo systemctl restart containerd.service
```
> [!NOTE]
> If you encounter an error while restarting containerd, delete the config.toml file from /etc/containerd
> ```shell
> sudo rm -rf /etc/containerd/config.toml
> ```
> By restarting containerd, the configuration file config.toml will be created again
> 
> Or edit the /etc/containerd/config.toml file and copy the following config to config.toml
> ```shell
> vi /etc/containerd/config.toml
> ```
>
> ```
> # disabled_plugins = ["cri"]
> disabled_plugins = []
> root = "/var/lib/containerd"
> state = "/run/containerd"
> #subreaper = true
> #oom_score = 0
>
> [grpc]
> address = "/run/containerd/containerd.sock"
> #  uid = 0
> #  gid = 0
> #[debug]
> #  address = "/run/containerd/debug.sock"
> #  uid = 0
> #  gid = 0
> #  level = "info"
> ```

3. Apply the kubeadm join command from Step 3 on worker nodes to connect them to the master node. Prefix the command with sudo:
```shell
sudo kubeadm join [master-node-ip]:6443 --token [token] --discovery-token-ca-cert-hash sha256:[hash]
```
> [!NOTE]
> Replace ***[master-node-ip]***, ***[token]***, and ***[hash]*** with the values from the kubeadm join command output.
4. After a few minutes, switch to the master server and enter the following command to check the status of the nodes:
```shell
kubectl get nodes
```
The system displays the master node and the worker nodes in the cluster.

> [!NOTE]
> If you encounter the following error while running kubectl get nodes
>
> ``` 
> kubernetes couldn't get current server API group list: Get "http://localhost:{API_PORT}/api?timeout=32s": dial tcp 127.0.0.1::{API_PORT}: connect: connection refused
> ```
> 
> Use this command
> 
> sudo kubectl get nodes --kubeconfig /etc/kubernetes/admin.conf

Conclusion

After following the steps presented in this article, you should have Kubernetes installed on Ubuntu. The article included instructions on installing the necessary packages and deploying Kubernetes on all your nodes.

If you are a beginner with no experience in Kubernetes deployment, Minikube is a great place to start.
