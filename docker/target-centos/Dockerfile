FROM centos:7

# Add local repository configuration
RUN echo "keepcache=1" >> /etc/yum.conf && \
    # Disable mirrorlist and use a specific baseurl
    sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Base.repo && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Base.repo

# Try to update, but don't fail if it doesn't work
RUN yum -y update || echo "Update failed, continuing with build"

# Install packages with fallback for failures
RUN yum -y install python3 || yum -y --disablerepo=* --enablerepo=base install python3
RUN yum -y install openssh-server || yum -y --disablerepo=* --enablerepo=base install openssh-server
RUN yum -y install sudo vim || yum -y --disablerepo=* --enablerepo=base install sudo vim
RUN yum clean all

# Create ansible user with password and sudo access
RUN useradd -m ansible && \
    echo "ansible:ansible" | chpasswd && \
    usermod -aG wheel ansible && \
    echo "ansible ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ansible

# Configure SSH for the lab
RUN mkdir -p /var/run/sshd
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
RUN echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

# Generate SSH host keys
RUN ssh-keygen -A || echo "SSH key generation failed, may need to be done at runtime"

EXPOSE 22

# Start SSH daemon
CMD ["/usr/sbin/sshd", "-D"]
