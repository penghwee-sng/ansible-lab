# Ansible Fundamentals Lab Guide

This guide will walk you through a series of exercises to learn the fundamentals of Ansible in a hands-on environment.

## Lab Environment

Your lab consists of:
- 1 Ansible control node (`ansible-control`)
- 3 target nodes:
  - Ubuntu server (`target-ubuntu`)
  - CentOS server (`target-centos`)
  - Debian server (`target-debian`)

## Getting Started

1. Start the lab environment:
   ```bash
   docker-compose up -d
   ```

2. Connect to the Ansible control node:
   ```bash
   docker exec -it ansible-control bash
   ```

3. Verify that you can access the lab environment:
   ```bash
   ansible --version
   ```

## Exercise 1: Basic Inventory and Connection Test

### Understanding Inventory Files

1. Examine the pre-created inventory file:
   ```bash
   cat ~/ansible/inventory/hosts
   ```

2. Run your first Ansible command to ping all hosts locally:
   ```bash
   ansible all -i ~/ansible/inventory/hosts --connection=local -m ping
   ```

### Setting Up SSH Access

1. Generate an SSH key:
   ```bash
   ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
   ```

2. Copy your SSH key to each target node:
   ```bash
   sshpass -p "ansible" ssh-copy-id ansible@target-ubuntu
   sshpass -p "ansible" ssh-copy-id ansible@target-centos
   sshpass -p "ansible" ssh-copy-id ansible@target-debian
   ```

3. Test SSH connections:
   ```bash
   ssh ansible@target-ubuntu "hostname"
   ssh ansible@target-centos "hostname"
   ssh ansible@target-debian "hostname"
   ```

4. Test Ansible connectivity:
   ```bash
   ansible all -i ~/ansible/inventory/hosts -m ping
   ```

## Exercise 2: Ansible Configuration

1. Create an ansible.cfg file:
   ```bash
   cd ~/ansible
   nano ansible.cfg
   ```

2. Add the following content:
   ```ini
   [defaults]
   inventory = ./inventory/hosts
   host_key_checking = False
   remote_user = ansible
   ```

3. Test that you no longer need to specify inventory:
   ```bash
   ansible all -m ping
   ```

## Exercise 3: Ad-Hoc Commands

Run these commands to practice with ad-hoc commands:

1. Get system information:
   ```bash
   ansible all -m setup -a "filter=ansible_distribution*"
   ```

2. Check disk space:
   ```bash
   ansible all -m shell -a "df -h"
   ```

3. Create a file on all servers:
   ```bash
   ansible all -m file -a "path=/tmp/test.txt state=touch mode=0644" --become
   ```

4. Check if the file exists:
   ```bash
   ansible all -m stat -a "path=/tmp/test.txt"
   ```

5. Using limits to target specific hosts:
   ```bash
   # Target a single host
   ansible all -m ping --limit target-ubuntu
   
   # Target multiple hosts
   ansible all -m ping --limit 'target-ubuntu,target-centos'
   
   # Use pattern matching
   ansible all -m ping --limit '*ubuntu'
   
   # Exclude hosts
   ansible all -m ping --limit '!target-centos'
   ```

## Exercise 4: Creating and Running Playbooks

1. Create your first playbook:
   ```bash
   mkdir -p ~/ansible/playbooks
   nano ~/ansible/playbooks/webserver.yml
   ```

2. Add the following content:
   ```yaml
   ---
   - name: Web Server Setup
     hosts: webservers
     become: yes
     tasks:       
       - name: Start and enable Nginx
         service:
           name: nginx
           state: started
           enabled: yes
         when: ansible_distribution == 'Ubuntu' or ansible_distribution == 'Debian'
       
       - name: Create a custom index page
         copy:
           content: "<html><body><h1>Hello from {{ ansible_hostname }}</h1></body></html>"
           dest: /var/www/html/index.html
         when: ansible_distribution == 'Ubuntu' or ansible_distribution == 'Debian'
   ```

3. Run the playbook:
   ```bash
   ansible-playbook ~/ansible/playbooks/webserver.yml
   ```

4. Check if nginx is running:
   ```bash
   curl http://target-debian/
   curl http://target-ubuntu/
   ```

## Exercise 5: Working with Loops

1. Create a directory for the loop examples:
   ```bash
   mkdir -p ~/ansible/playbooks
   nano ~/ansible/playbooks/loops.yml
   ```

2. Add the following content:
   ```yaml
   ---
   - name: Loop Examples
     hosts: webservers
     become: yes
     tasks:
       - name: Create multiple directories
         file:
           path: "/tmp/{{ item }}"
           state: directory
           mode: '0755'
         loop:
           - test_dir1
           - test_dir2
           - test_dir3
       
       - name: Create users with nested loops
         user:
           name: "{{ item.name }}"
           groups: "{{ item.groups | default('') }}"
           state: present
         loop:
           - { name: 'testuser1', groups: 'sudo' }
           - { name: 'testuser2' }
           - { name: 'testuser3', groups: 'adm' }
   ```

3. Run the playbook:
   ```bash
   ansible-playbook ~/ansible/playbooks/loops.yml
   ```

4. Verify the loop results:
   ```bash
   ansible webservers -m shell -a "ls -la /tmp | grep test_dir"
   ansible webservers -m shell -a "cat /etc/passwd | grep testuser"
   ```

## Exercise 6: Using Tags

1. Create a playbook with tags:
   ```bash
   nano ~/ansible/playbooks/tags_demo.yml
   ```

2. Add the following content:
   ```yaml
   ---
   - name: Tags Demonstration
     hosts: all
     become: yes
     tasks:
       - name: Create web directories
         file:
           path: "/opt/webserver/{{ item }}"
           state: directory
           mode: '0755'
         loop:
           - html
           - logs
           - conf
         tags:
           - webserver
           - setup
       
       - name: Create database directories
         file:
           path: "/opt/database/{{ item }}"
           state: directory
           mode: '0755'
         loop:
           - data
           - logs
           - conf
         tags:
           - database
           - setup
       
       - name: Create web configuration file
         copy:
           content: "# Web server config"
           dest: /tmp/web.conf
         tags:
           - configuration
           - webserver
       
       - name: Create database configuration file
         copy:
           content: "# Database config"
           dest: /tmp/db.conf
         tags:
           - configuration
           - database
   ```

3. Run the playbook with different tag options:
   ```bash
   # Run only tasks with the 'webserver' tag
   ansible-playbook ~/ansible/playbooks/tags_demo.yml --tags webserver
   
   # Run only tasks with the 'configuration' tag
   ansible-playbook ~/ansible/playbooks/tags_demo.yml --tags configuration
   
   # Run all tasks except those with the 'database' tag
   ansible-playbook ~/ansible/playbooks/tags_demo.yml --skip-tags database
   
   # Run tasks with either 'webserver' OR 'database' tags
   ansible-playbook ~/ansible/playbooks/tags_demo.yml --tags "webserver,database"
   
   # List all tasks and their tags without executing
   ansible-playbook ~/ansible/playbooks/tags_demo.yml --list-tasks
   ```

4. Verify the results:
   ```bash
   # Check the configuration files
   ansible all -m shell -a "ls -la /tmp/web.conf /tmp/db.conf 2>/dev/null || echo 'Files not found'"
   
   # Check the created directories
   ansible all -m shell -a "ls -la /opt/webserver /opt/database 2>/dev/null || echo 'Directories not found'"
   ```

## Exercise 7: Variables and Templates

1. Create a variables file:
   ```bash
   mkdir -p ~/ansible/inventory/group_vars
   nano ~/ansible/inventory/group_vars/webservers.yml
   ```

2. Add the following content:
   ```yaml
   ---
   server_name: lab_webserver
   server_message: "Welcome to our Ansible Lab!"
   ```

3. Create a templates directory and a template file:
   ```bash
   mkdir -p ~/ansible/templates
   nano ~/ansible/templates/index.html.j2
   ```

4. Add the following content:
   ```html
   <html>
   <head>
     <title>{{ server_name }}</title>
   </head>
   <body>
     <h1>{{ server_message }}</h1>
     <p>This server is: {{ ansible_hostname }}</p>
     <p>Running: {{ ansible_distribution }} {{ ansible_distribution_version }}</p>
   </body>
   </html>
   ```

5. Create a new playbook that uses templates:
   ```bash
   nano ~/ansible/playbooks/template_demo.yml
   ```

6. Add the following content:
   ```yaml
   ---
   - name: Template Demo
     hosts: webservers
     become: yes
     tasks:
       - name: Deploy custom webpage from template
         template:
           src: ../templates/index.html.j2
           dest: /var/www/html/index.html
           owner: www-data
           group: www-data
           mode: '0644'
   ```

7. Run the playbook:
   ```bash
   ansible-playbook ~/ansible/playbooks/template_demo.yml
   ```

## Exercise 8: Roles

1. Create a basic role structure:
   ```bash
   mkdir -p ~/ansible/playbooks/roles/webserver/{tasks,templates,vars}
   ```

2. Create the main tasks file:
   ```bash
   nano ~/ansible/playbooks/roles/webserver/tasks/main.yml
   ```

3. Add the following content:
   ```yaml
   ---
   - name: Install web server package
     apt:
       name: "{{ webserver_package }}"
       state: present
       update_cache: yes
     when: ansible_distribution == 'Ubuntu' or ansible_distribution == 'Debian'
   
   - name: Start and enable service
     service:
       name: "{{ webserver_package }}"
       state: started
       enabled: yes
     when: ansible_distribution == 'Ubuntu' or ansible_distribution == 'Debian'
   
   - name: Create custom web page
     template:
       src: index.html.j2
       dest: /var/www/html/index.html
     when: ansible_distribution == 'Ubuntu' or ansible_distribution == 'Debian'
   ```

4. Create the variables file:
   ```bash
   nano ~/ansible/playbooks/roles/webserver/vars/main.yml
   ```

5. Add the following content:
   ```yaml
   ---
   webserver_package: nginx
   site_title: "Ansible Role Demo"
   site_description: "This page was created using an Ansible role"
   ```

6. Copy the template you created earlier:
   ```bash
   cp ~/ansible/templates/index.html.j2 ~/ansible/playbooks/roles/webserver/templates/
   ```

7. Edit the template to use the role variables:
   ```bash
   nano ~/ansible/playbooks/roles/webserver/templates/index.html.j2
   ```

8. Update the template:
   ```html
   <html>
   <head>
     <title>{{ site_title }}</title>
   </head>
   <body>
     <h1>{{ site_title }}</h1>
     <p>{{ site_description }}</p>
     <p>This server is: {{ ansible_hostname }}</p>
     <p>Running: {{ ansible_distribution }} {{ ansible_distribution_version }}</p>
   </body>
   </html>
   ```

9. Create a playbook to use the role:
   ```bash
   nano ~/ansible/playbooks/role_demo.yml
   ```

10. Add the following content:
    ```yaml
    ---
    - name: Apply Webserver Role
      hosts: webservers
      become: yes
      roles:
        - webserver
    ```

11. Run the playbook:
    ```bash
    ansible-playbook ~/ansible/playbooks/role_demo.yml
    ```

## Exercise 9: Deploying Velociraptor for Forensic Collection

This exercise will teach you how to use Ansible to deploy Velociraptor clients, an advanced Digital Forensics and Incident Response (DFIR) tool, to collect artifacts from your managed hosts.

### Step 1: Understanding the Velociraptor Environment

The lab environment already includes a pre-configured Velociraptor server running in a Docker container. You can access the GUI at `http://velociraptor-server:8889` or `http://localhost:8889` from the host machine.

Credentials for the Velociraptor server:
- Username: admin
- Password: password123

From the desktop, verify you can reach the Velociraptor server (this is possible as the ports are mapped to host machine in `docker-compose.yml`) by going to `http://localhost:8889`.

### Step 2: Create an Ansible playbook for deploying Velociraptor clients

1. First, in `ansible-control` container, create a directory for storing the client configuration and binary:
   ```bash
   mkdir -p ~/ansible/playbooks/velociraptor
   cd ~/ansible/playbooks/velociraptor
   ```

2. Copy the pre-configured Velociraptor **client configuration** from the **host machine** to the **ansible-control** container:
   ```bash
   # This command would be run on the host machine, not inside the container

   # client.config.yaml
   docker cp ./velociraptor/client.config.yaml ansible-control:/home/ansible/ansible/playbooks/velociraptor/
   ```

   Note: Make sure the client.config.yaml exists at ./velociraptor/ on your host machine before running this command.

3. Copy over velociraptor binary and enable execution:
   ```bash
   # in /home/ansible/ansible/playbooks/velociraptor/
   cp /shared/binaries/velociraptor /home/ansible/ansible/playbooks/velociraptor/
   chmod +x /home/ansible/ansible/playbooks/velociraptor/velociraptor
   ```

4. Create a playbook for deploying Velociraptor clients:
   ```bash
   nano ~/ansible/playbooks/velociraptor_clients.yml
   ```

5. Add the following content:
   ```yaml
   ---
   - name: Deploy Velociraptor Clients
     hosts: webservers
     become: yes
     vars:
       velociraptor_server: "velociraptor-server"
       client_config_url: "http://{{ velociraptor_server }}:8889/api/v1/GetClientConfig"
     
     tasks:
       - name: Create Velociraptor client directory
         file:
           path: /opt/velociraptor
           state: directory
           mode: '0755'
   
       - name: Copy Velociraptor binary
         copy:
           src: ~/ansible/playbooks/velociraptor/velociraptor
           dest: /opt/velociraptor/velociraptor
           mode: '0755'
   
       - name: Copy client configuration
         copy:
           src: ~/ansible/playbooks/velociraptor/client.config.yaml
           dest: /opt/velociraptor/client.config.yaml
           mode: '0644'
   
       - name: Create systemd service file (for documentation)
         copy:
           dest: /etc/systemd/system/velociraptor-client.service
           content: |
             [Unit]
             Description=Velociraptor client service
             After=network.target
             
             [Service]
             Type=simple
             ExecStart=/opt/velociraptor/velociraptor --config /opt/velociraptor/client.config.yaml client -v
             Restart=always
             RestartSec=4
             
             [Install]
             WantedBy=multi-user.target
   
       # Check if Velociraptor is already running
       - name: Check if Velociraptor client is already running
         shell: "ps aux | grep -v grep | grep '/opt/velociraptor/velociraptor.*client'"
         register: velociraptor_process
         ignore_errors: yes
         changed_when: false
   
       # Run Velociraptor client as root directly (without systemd)
       - name: Run Velociraptor client as root
         shell: "nohup /opt/velociraptor/velociraptor --config /opt/velociraptor/client.config.yaml client -v > /   opt/velociraptor/client.log 2>&1 &"
         args:
           creates: /opt/velociraptor/client.log
         when: velociraptor_process.stdout == ""
   ```

6. Run the playbook to deploy Velociraptor clients to host group `webservers`:
   ```bash
   # Due to compatibility issue, we will skip CentOS for this lab
   ansible-playbook ~/ansible/playbooks/velociraptor_clients.yml
   ```

### Step 3: Access the Velociraptor GUI and verify connections

1. You can access the Velociraptor GUI from your host machine:
   ```
   http://localhost:8889
   ```
   
   Login with the default credentials:
   - Username: admin
   - Password: admin

2. In the GUI, click on the "Search" button to verify that your managed nodes have connected.

3. You should see your target machines (target-ubuntu & target-debian) listed as clients.

### Step 4: Create a collection from the GUI

1. In the Velociraptor GUI, click on one of your connected clients.

2. Select "Hunt Manager" from the sidebar and click on the "+" button to start a new Hunt.

3. In the "Configure Hunt" page, check the box "Start Hunt Immediately".

4. Click on "Select Artifacts" and select a basic artifact "Generic.Client.DiskSpace".

5. Click "Launch" to start the collection.

6. View the results when the collection completes:
   1. Select the Hunt.
   2. Click on Clients tab.
   3. Click on `ClientId` of `target-ubuntu`.
   4. On the sidebar select "Collected Artifacts".
   5. Click on "Results" and you will see the information collected, in this case the disk space information.

This concludes the Velociraptor deployment exercise. You now have a dedicated Velociraptor server and clients deployed to all your managed nodes using Ansible.

## Verifying Your Progress

At any time, you can run the verification script to check your progress:

```bash
exit  # Exit from the container first
./verify_lab.sh
```

## Cleaning Up

When you're finished with the lab, shut down the environment:

```bash
docker-compose down
```

Congratulations on completing the Ansible Fundamentals Lab!
