FROM ubuntu:22.04

# Configure APT to be more resilient to temporary network issues
RUN echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries && \
    echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/90-no-recommends

# Install packages with retry logic
RUN apt-get update || (sleep 10 && apt-get update) || (sleep 30 && apt-get update) && \
    apt-get install -y python3 openssh-server sudo vim nano nginx && \
    apt-get clean

RUN useradd -m ansible && \
    echo "ansible:ansible" | chpasswd && \
    adduser ansible sudo && \
    echo "ansible ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ansible

RUN mkdir -p /var/run/sshd
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
RUN echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
