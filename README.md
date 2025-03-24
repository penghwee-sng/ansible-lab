# Ansible Fundamentals Lab

This repository contains a comprehensive Ansible lab environment for learning the fundamentals of Ansible through hands-on exercises.

## Prerequisites

- Docker and Docker Compose installed on your system
- Basic Linux command line knowledge

## Quick Start

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd ansible-lab
   ```

2. Start the lab environment:
   ```bash
   docker-compose up -d
   ```

3. Open the lab guide:
   ```bash
   less lab_guide.md
   ```

4. Connect to the Ansible control node:
   ```bash
   docker exec -it ansible-control bash
   ```

5. Follow the exercises in the lab guide.

## Verifying Progress

Run the verification script to check your progress:

```bash
./verify_lab.sh
```

## Preparing for Offline Use

To prepare the lab for use in an offline environment:

```bash
./prepare_offline.sh
```

This will create a `ansible-lab-offline.tar.gz` file containing everything needed for the lab, along with instructions in `ansible-lab-offline-instructions.txt`.

To use in an offline environment:
1. Transfer both files to the offline system
2. Follow the instructions in the text file to load the pre-built Docker images
3. Start the lab with `docker-compose up -d`

No internet connection will be required as all Docker images are pre-built and included in the archive.

## Environment Structure

- `ansible-control`: Ansible control node with required tools
- `target-ubuntu`: Ubuntu target machine
- `target-centos`: CentOS target machine
- `target-debian`: Debian target machine

## Credentials

All machines use the same credentials:
- Username: `ansible`
- Password: `ansible`

## Cleaning Up

When you're finished with the lab:

```bash
docker-compose down
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
