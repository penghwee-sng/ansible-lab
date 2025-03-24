#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Preparing Ansible Lab for Offline Use ===${NC}"
mkdir -p offline_files

# Pull all required Docker images
echo -e "\n${YELLOW}Pulling Docker images...${NC}"
docker-compose pull

# Save Docker images
echo -e "\n${YELLOW}Saving Docker images to tar files...${NC}"
docker save ubuntu:22.04 centos:7 debian:11 -o offline_files/base_images.tar

# Create directory for package caching
mkdir -p offline_files/packages/{ubuntu,debian,centos}

# Function to run a container and extract package cache
cache_packages() {
    local image=$1
    local name=$2
    local dest=$3
    local pkg_cmd=$4
    
    echo -e "\n${YELLOW}Pre-caching packages for ${name}...${NC}"
    
    # Start a container, install packages, and save the package cache
    docker run --name ${name}_cache -d ${image} sleep 300
    docker exec ${name}_cache bash -c "${pkg_cmd}"
    docker cp ${name}_cache:/var/cache/apt/archives/ offline_files/packages/${dest}/ || true
    docker cp ${name}_cache:/var/cache/yum/ offline_files/packages/${dest}/ || true
    docker rm -f ${name}_cache
}

# Cache packages for each distribution
cache_packages "ubuntu:22.04" "ubuntu" "ubuntu" "apt-get update && apt-get install -y python3 python3-pip openssh-server openssh-client sshpass vim nano iputils-ping net-tools curl git sudo"
cache_packages "debian:11" "debian" "debian" "apt-get update && apt-get install -y python3 openssh-server sudo vim nano"
cache_packages "centos:7" "centos" "centos" "yum -y install python3 openssh-server sudo vim || true"

# Build the custom images
echo -e "\n${YELLOW}Building custom Docker images...${NC}"
docker-compose build

# Tag images with consistent names that match docker-compose.yml
echo -e "\n${YELLOW}Tagging custom Docker images...${NC}"
docker tag ansible-lab_ansible-control ansible-lab/ansible-control:latest
docker tag ansible-lab_target-ubuntu ansible-lab/target-ubuntu:latest
docker tag ansible-lab_target-centos ansible-lab/target-centos:latest
docker tag ansible-lab_target-debian ansible-lab/target-debian:latest

# Save the custom images
echo -e "\n${YELLOW}Saving custom Docker images...${NC}"
docker save ansible-lab/ansible-control:latest ansible-lab/target-ubuntu:latest ansible-lab/target-centos:latest ansible-lab/target-debian:latest -o offline_files/custom_images.tar

# Create a script to load the images in the offline environment
cat > offline_files/load_images.sh << 'EOF'
#!/bin/bash
echo "Loading base Docker images..."
docker load -i base_images.tar
echo "Loading custom Docker images..."
docker load -i custom_images.tar
echo "Images loaded successfully!"
EOF

chmod +x offline_files/load_images.sh

# Copy all necessary files
echo -e "\n${YELLOW}Copying necessary files...${NC}"
cp -r docker docker-compose.yml verify_lab.sh lab_guide.md README.md offline_files/

# Create a zip archive
echo -e "\n${YELLOW}Creating final archive...${NC}"
tar -czvf ansible-lab-offline.tar.gz offline_files/

# Create a simple instruction file for offline use
cat > ansible-lab-offline-instructions.txt << 'EOF'
===== ANSIBLE LAB OFFLINE SETUP INSTRUCTIONS =====

1. Extract the archive:
   tar -xzvf ansible-lab-offline.tar.gz

2. Navigate to the extracted directory:
   cd offline_files

3. Load the Docker images:
   ./load_images.sh

4. Start the lab environment:
   docker-compose up -d

5. Follow the lab guide (lab_guide.md) to complete the exercises

NOTE: The Docker images have been pre-built and will be loaded from the archive,
so no internet connection is required to build them.

If you experience any issues starting the containers, try the following:
- For CentOS: docker exec -it target-centos yum-config-manager --disable base
- For all containers: verify that the services are running with 'docker ps'
EOF

echo -e "\n${GREEN}Done!${NC}"
echo "The file ansible-lab-offline.tar.gz contains everything needed for the offline lab."
echo "Transfer this file along with ansible-lab-offline-instructions.txt to the offline environment."
echo "Follow the instructions in ansible-lab-offline-instructions.txt to get started."
