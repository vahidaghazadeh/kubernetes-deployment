# Kubernetes Cluster Deployment with Ansible

## Introduction
This document provides a comprehensive guide to setting up a Kubernetes cluster using Ansible. The guide includes creating an Ansible inventory file, preparing the servers, and deploying Kubernetes on the cluster. This setup ensures consistency and reduces the risk of manual errors during installation and configuration.

## Prerequisites
- Ansible installed on the control node.
- SSH access to all nodes in the cluster (master and workers).
- Nodes running a compatible Linux distribution (e.g., Ubuntu).
- Public and private SSH key pair on your local machine.

## Inventory File
The inventory file lists all the hosts in your cluster and groups them into categories. This allows Ansible to run tasks on specific groups of hosts.

### Creating the Inventory File

1. **Open a text editor**: You can use `nano`, `vim`, or any other text editor.
2. **Define the hosts and groups**: List the master and worker nodes with their IP addresses.
3. **Save the file**: Save the file with a suitable name, such as `hosts` or `inventory`.

### Example Inventory File
Create a file named `hosts` with the following content:

```ini
[all]
k8s-master ansible_host=192.168.1.10
k8s-worker01 ansible_host=192.168.1.11
k8s-worker02 ansible_host=192.168.1.12

[k8s-master]
k8s-master

[k8s-workers]
k8s-worker01
k8s-worker02

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

### Server Preparation Playbook
Create a playbook named prepare-servers.yml to set up the required users and configure SSH access.

### Preparing the Servers
Create a file named prepare-servers.yml with the following content:

```yaml
---
- hosts: all
  become: true

  tasks:
    - name: Create a non-root user named kuberunner
      user:
        name: kuberunner
        state: present
        shell: /bin/bash

    - name: Set sudoers for kuberunner
      copy:
        dest: /etc/sudoers.d/kuberunner
        content: |
          kuberunner ALL=(ALL) NOPASSWD:ALL
      mode: '0440'

    - name: Add local machine's public key to kuberunner's authorized_keys
      authorized_key:
        user: kuberunner
        state: present
        key: "{{ lookup('file', lookup('env','HOME') + '/.ssh/id_rsa.pub') }}"

```
### Running the Server Preparation Playbook
Execute the playbook using the following command:
```shell
ansible-playbook -i hosts prepare-servers.yml

```
# Kubernetes Setup Playbook
> - Create the main playbook named kubernetes-setup.yml to install and configure Kubernetes.
> - Creating the Kubernetes Setup Playbook
> - Create a file named kubernetes-setup.yml with the following content:

```yaml
---
- name: Kubernetes Cluster Setup
  hosts: all
  become: yes

  tasks:
    - name: Update package list
      apt:
        update_cache: yes

    - name: Install Docker
      apt:
        name: docker.io
        state: present

    - name: Remove unnecessary Docker packages
      apt:
        name:
          - docker.io
          - docker-doc
          - docker-compose
          - podman-docker
          - containerd
          - runc
        state: absent

    - name: Install required packages
      apt:
        name:
          - ca-certificates
          - curl
          - gnupg
        state: present

    - name: Enable Docker service
      systemd:
        name: docker
        enabled: yes
        state: started

    - name: Add Kubernetes signing key
      command: curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
      args:
        creates: /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    - name: Add Kubernetes repository
      command: echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
      args:
        creates: /etc/apt/sources.list.d/kubernetes.list

    - name: Update package list after adding Kubernetes repository
      apt:
        update_cache: yes

    - name: Install Kubernetes tools
      apt:
        name:
          - kubeadm
          - kubelet
          - kubectl
        state: present

    - name: Hold Kubernetes packages to prevent automatic updates
      apt:
        name:
          - kubeadm
          - kubelet
          - kubectl
        state: present
        hold: yes

    - name: Verify kubeadm installation
      command: kubeadm version

- name: Set hostname for master node
  hosts: k8s-master
  become: yes
  tasks:
    - name: Set hostname
      command: hostnamectl set-hostname k8s-master

- name: Set hostname for worker nodes
  hosts: k8s-workers
  become: yes
  tasks:
    - name: Set hostname
      command: hostnamectl set-hostname {{ inventory_hostname }}

- name: Configure /etc/hosts on all nodes
  hosts: all
  become: yes
  tasks:
    - name: Add master and worker IPs to /etc/hosts
      lineinfile:
        path: /etc/hosts
        line: "{{ item }}"
      with_items:
        - "192.168.1.10 k8s-master"
        - "192.168.1.11 k8s-worker01"
        - "192.168.1.12 k8s-worker02"

- name: Initialize Kubernetes on master node
  hosts: k8s-master
  become: yes
  tasks:
    - name: Initialize Kubernetes
      command: kubeadm init --control-plane-endpoint=k8s-master --upload-certs
      register: kubeadm_init

    - name: Create .kube directory
      file:
        path: $HOME/.kube
        state: directory
        mode: '0755'
        owner: kuberunner
        group: kuberunner

    - name: Copy Kubernetes admin config
      copy:
        src: /etc/kubernetes/admin.conf
        dest: $HOME/.kube/config
        remote_src: yes
        owner: kuberunner
        group: kuberunner

    - name: Set KUBECONFIG environment variable
      lineinfile:
        path: $HOME/.bashrc
        line: export KUBECONFIG=$HOME/.kube/config

    - name: Deploy pod network
      command: kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
      environment:
        KUBECONFIG: $HOME/.kube/config

    - name: Untaint master node
      command: kubectl taint nodes --all node-role.kubernetes.io/control-plane-
      environment:
        KUBECONFIG: $HOME/.kube/config

- name: Join worker nodes to the cluster
  hosts: k8s-workers
  become: yes
  tasks:
    - name: Join worker node to the cluster
      command: "{{ hostvars['k8s-master'].kubeadm_init.stdout_lines[-1] }}"
```

### Running the Kubernetes Setup Playbook
Execute the playbook using the following command:
```shell
ansible-playbook -i hosts kubernetes-setup.yml
```

### Conclusion
By following this document, you will be able to set up an Ansible inventory file and use it to automate the deployment of a Kubernetes cluster. This setup ensures consistency and reduces the risk of manual errors during the installation and configuration process.

This document provides a complete guide to setting up and deploying a Kubernetes cluster using Ansible, including all necessary configuration files and playbooks.