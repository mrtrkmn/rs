# Ansible Setup for Postgres, Docker Network, and Miniflux

This repository contains Ansible playbooks and roles to set up a Docker network, Postgres database, and Miniflux service.


https://github.com/user-attachments/assets/bb20ca15-1169-4a5a-93b6-4c5320f67c06



## Prior Quesions 

- Why we might want to use services inside a container instead of directly on the host. Are there benefits or issues with it?
     - Benefits
        - If there will be a vulnerability on Ansible version, it won't effect the host system ( depending on the vulnerability and workload of the system )
        - Provides extra security layer
        - Efficient compared to VM, easy to manage
        - Has lower overhead compared to VM 
        - Easy rollback, when there is a problem in a version
        - Rolling updates without downtime is possible
    
    - Possible Issues
        - Due to extra security layer, there might be performance overhead ( it might or might not be ignored depends on the situation) 
        - Not directly an issue but it will require centralized logging because logs inside containers are temporary.

- Why we might want to put Ansible in a Container Image? Are there benefits or issues with it?
    - Benefits
        - Decreases attack surface by installing only required libraries inside the container image
        - Same Ansible version and dependencies will be used across different environments ( MacOS, Linux , Windows)
        - "works on my local" problem will be removed
        - When temporary Ansible execution envrionment required such as in CI/CD pipelines, this will be beneficial. 
    - Possible Issues
        - There is no systemd, which might be required in some cases to manage host services. ( there might be some tricks to overcome however as built-in first approach,there is no easy management )

- What happens when you restart your host. Is the service online afterwards?
    - Yes, due to restart policy of services is defined as always, when the host is restarted, the services will be re-created again. 


## Prerequisites

- SSH authentication setup between nodes (preferred way of authentication for Linux environments).

### Copy SSH Key to Remote Host

To set up SSH key authentication, follow these steps:

1. Generate a new private/public key pair on each machine/user.
2. Add the new nodes' public key to the `authorized_keys` file in `.ssh`.

Alternatively, you can use the `ssh-copy-id` command (preferred):

```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub <remote-host-username>@<remote-host-ip>
```

If password login is not available for the nodes, use the first described steps. Once keys are exchanged between nodes, you can add the node's IP address/domain to the `hosts` file.

## Running Tasks over Ansible

### Docker Environment

A Dockerfile is provided to prepare an environment for running Ansible commands through a container. You can pull the image directly from Docker Hub:

```bash
docker pull techatgeek/ansible-env
```

Or build it locally using the following command:

```bash
docker build -t ansible-env .
```

### Running the Playbook

The playbook that includes all roles can be run with the following command: 
 (The following command needs to be executed in parent dir of the repository)

```bash
docker run --rm -it \
    -v $(pwd):/ansible \
    -v ~/.ssh:/root/.ssh:ro \
    ansible-env /bin/bash -c "ansible-playbook -i /ansible/inventory/hosts /ansible/main.yaml --ask-vault-pass"
```

### Ansible Vault

Ansible Vault is used to keep secret information such as remote host username and password, or any other sensitive data.

The vault file is generated from the following constructed file:

```yaml
ansible_user: <remote-host-username>
ansible_ssh_pass: <remote-host-password>
ansible_become_password: <remote-host-root-password>
```

To encrypt this file, use the following command:

```bash
ansible-vault encrypt /ansible/secrets/creds.yaml
```

You will be asked to generate a vault password, which you will need to enter when executing the playbook command.

## Repository Structure

```
.gitignore
ansible.cfg
Dockerfile
main.yaml
readme.md
group_vars/
    all.yaml
inventory/
    hosts
roles/
    docker_daemon/
        tasks/
            main.yaml
    docker_network/
        tasks/
            main.yaml
    miniflux/
        tasks/
            main.yaml
    postgres/
        tasks/
            main.yaml
secrets/
    creds.yaml
```

### Roles

- **docker_daemon**: Installs Docker CE to the host
- **docker_network**: Creates a Docker network named `backend`.
- **postgres**: Sets up and runs a Postgres container.
- **miniflux**: Sets up and runs a Miniflux container.

### Configuration Files

- **group_vars/all.yaml**: Contains variables used across roles.
- **inventory/hosts**: Lists the IP addresses of the nodes.
- **ansible.cfg**: Ansible configuration file.
- **secrets/creds.yaml**: Encrypted file containing sensitive information.

In case of customization of the setup, mentioned configuration files need to be updated according to your environment. 

### Playbook

- **main.yaml**: Main playbook that sets up Postgres, Docker network, and Miniflux.

```yaml
- name: Setup Postgres/Network/Miniflux
  hosts: all
  vars_files:
    - ./secrets/creds.yaml
  become: yes
  become_method: sudo
  roles:
    - docker_daemon
    - docker_network
    - postgres
    - miniflux
```
