FROM ubuntu:22.04

# Configure APT to be more resilient to temporary network issues
RUN echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries && \
    echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/90-no-recommends

# Install packages with retry logic
RUN apt-get update || (sleep 10 && apt-get update) || (sleep 30 && apt-get update) && \
    apt-get install -y python3 python3-pip openssh-client sshpass vim nano iputils-ping \
    net-tools curl git sudo procps && \
    apt-get clean

# Install Ansible with pip, with retry logic
RUN pip3 install --no-cache-dir "ansible<2.17" ansible-lint || \
    (sleep 30 && pip3 install --no-cache-dir ansible ansible-lint)

# Create ansible user
RUN useradd -m ansible && \
    echo "ansible:ansible" | chpasswd && \
    adduser ansible sudo && \
    echo "ansible ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ansible

USER ansible
WORKDIR /home/ansible

# Configure SSH for easier connections to target machines
RUN mkdir -p ~/.ssh && \
    echo "Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null" > ~/.ssh/config

# Set up basic ansible directory structure
RUN mkdir -p ~/ansible/inventory ~/ansible/playbooks

# Create basic inventory file 
RUN echo "[webservers]\ntarget-ubuntu\ntarget-debian\n\n[dbservers]\ntarget-centos" > ~/ansible/inventory/hosts

# Create a simple healthcheck script
USER root
RUN echo '#!/bin/bash\nps aux | grep -v grep | grep -q "tail -f /dev/null" && exit 0 || exit 1' > /usr/local/bin/healthcheck.sh && \
    chmod +x /usr/local/bin/healthcheck.sh

# Configure healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 CMD ["/usr/local/bin/healthcheck.sh"]

# Switch back to ansible user
USER ansible

# Use tail to keep the container running instead of just bash which exits when not interactive
CMD ["tail", "-f", "/dev/null"]

# Example docker run command to use:
# docker run -d --name ansible-control -h ansible-control ansible-control:latest
