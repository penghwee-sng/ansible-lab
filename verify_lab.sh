#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Ansible Lab Verification Tool ===${NC}"
echo "Checking your lab environment and progress..."

# Check if containers are running
echo -e "\n${YELLOW}Checking Docker containers:${NC}"
CONTAINERS=("ansible-control" "target-ubuntu" "target-centos" "target-debian")
ALL_RUNNING=true

for container in "${CONTAINERS[@]}"; do
  if docker ps | grep -q "$container"; then
    echo -e "  ${GREEN}✓${NC} $container is running"
  else
    echo -e "  ${RED}✗${NC} $container is not running"
    ALL_RUNNING=false
  fi
done

if [ "$ALL_RUNNING" = false ]; then
  echo -e "\n${RED}Error:${NC} Not all containers are running."
  echo "Try running: docker-compose up -d"
  exit 1
fi

# Function to check exercises on the control node
check_exercise() {
  exercise_num=$1
  check_command=$2
  expected_output=$3
  description=$4
  
  echo -e "\n${YELLOW}Exercise $exercise_num: $description${NC}"
  result=$(docker exec ansible-control bash -c "$check_command")
  
  if [[ $result == *"$expected_output"* ]]; then
    echo -e "  ${GREEN}✓${NC} Completed successfully!"
  else
    echo -e "  ${RED}✗${NC} Not completed correctly"
    echo -e "  ${YELLOW}Hint:${NC} Make sure you followed the steps in the lab guide for Exercise $exercise_num"
  fi
}

# Check basic connectivity
check_exercise 1 "ansible -m ping all -i ~/ansible/inventory/hosts --connection=local" "SUCCESS" "Basic Inventory Setup"

# Check if inventory file exists and has correct content
check_exercise 2 "cat ~/ansible/inventory/hosts | grep -E 'webservers|dbservers'" "webservers" "Inventory Organization"

# Check if ad-hoc commands were run (checking for the test.txt file created in Exercise 3)
check_exercise 3 "cd ~/ansible && ansible all -m stat -a 'path=/tmp/test.txt' | grep -c 'exists\": true'" "3" "Ad-Hoc Commands"

# Check if a basic playbook exists
check_exercise 4 "find ~/ansible/playbooks -name 'webserver.yml' | wc -l" "1" "Creating a Basic Playbook"

# Check SSH connectivity to target nodes
check_exercise 4 "ssh -o BatchMode=yes -o ConnectTimeout=5 ansible@target-ubuntu echo SSH_OK 2>/dev/null || echo SSH_FAIL" "SSH_OK" "SSH Connectivity"

# Check if loop playbook exists and was run
check_exercise 5 "cd ~/ansible && ansible webservers -m shell -a \"ls -la /tmp | grep test_dir\" | grep -E 'test_dir[123]'" "test_dir" "Working with Loops"

# Check if tags playbook exists
check_exercise 6 "test -f ~/ansible/playbooks/tags_demo.yml && echo 'FOUND' || echo 'NOT_FOUND'" "FOUND" "Using Tags"

# Check if variables and templates are configured
check_exercise 7 "test -f ~/ansible/templates/index.html.j2 && grep '{{ server_' ~/ansible/templates/index.html.j2 && echo 'FOUND' || echo 'NOT_FOUND'" "FOUND" "Variables and Templates"

# Check if roles are set up
check_exercise 8 "test -d ~/ansible/playbooks/roles/webserver && test -f ~/ansible/playbooks/roles/webserver/tasks/main.yml && echo 'FOUND' || echo 'NOT_FOUND'" "FOUND" "Ansible Roles"

echo -e "\n${YELLOW}Verification complete!${NC}"
echo "Continue working through the lab guide for any unfinished exercises."
exit 0
