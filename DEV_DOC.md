# Developer Documentation

This document provides instructions for developers to set up, build, and maintain the Inception project.

> **Note on Naming Conventions:**  
> This project is configured using `gdosch` as the primary username and domain prefix, as required by the subject's constraints for my personal submission. If you are a developer looking to deploy or adapt this infrastructure, you must replace every occurrence of `gdosch` with your own login to ensure the environment paths, domain names, and services function correctly for your setup.

## Environment Setup

### Prerequisites
Before setting up the environment, ensure the following requirements are met on the host machine:

* Operating System: A stable version of Debian (v12 recommended).
* Software:
  * `docker` and `docker compose` (V2) must be installed and running.
  * GNU `make` must be installed to execute the project's automation.
  * `sudo` must be installed and configured for the current user.
* Privileges: The user must have `sudo` privileges (required for volume management and port binding).
* Ports Availability: Ensure the following ports are not occupied by other services on the host:
  * `443` (NGINX/HTTPS)
  * `8080` (Adminer)
  * `8081` (Static Site)
  * `3552` (Arcane)
  * `21` & `40000-40005` (FTP)
* Local DNS: You must have the ability to modify the `/etc/hosts` file to map `yourlogin.42.fr` to the host's IP.

### Configuration Files and Secrets

Before building the project, you must manually set up the required configurations and secrets.

1. **Environment Variables:**
   Copy the provided `.env.example` file to create your own `.env` file inside the `srcs/` directory:

   ```bash
   cp srcs/.env.example srcs/.env
   ```

   And fill it with your specific values.

2. **Secrets:**
   Create a `secrets/` directory at the root of the project. Inside, create the following text files containing only the respective passwords/keys:
   * `db_password.txt`
   * `db_root_password.txt`
   * `wp_admin_password.txt`
   * `wp_user_password.txt`
   * `redis_password.txt`
   * `ftp_password.txt`
   * `arc_encryption_key.txt`
   * `arc_jwt_secret.txt`

## Makefile Targets
The project is orchestrated using a `Makefile` situated at the root directory.

### Build & Launch
* `make` or `make all`: Creates the necessary local directories for persistent storage (`/home/gdosch/data/...`), builds all Docker images using `docker compose build`, and starts the containers in detached mode.
* `make build`: Only builds the images.
* `make up`: Starts the existing containers in the background.

### Database Access
* `make mariadb`: Opens an interactive MariaDB shell as root inside the database container for manual queries and verification.

### Cleanup & Maintenance
* `make down`: Stops and removes the containers and the default network. Volumes are preserved.
* `make clean`: Executes `make down` and runs `docker system prune -f` to clean up dangling resources (stopped containers, dangling networks).
* `make fclean`: Executes a complete wipe with safeguards. It removes all containers, networks, volumes, and images (`--rmi all`), clears the entire Docker cache, and verifies `DATA_PATH` safety before forcefully deleting local data directories (`sudo rm -rf /home/gdosch/data`). This prevents accidental system damage from misconfiguration.
* `make re`: Executes `make fclean` followed by `make all` for a complete fresh rebuild from scratch.
* `make mariadb`: Opens an interactive MariaDB shell as root inside the database container for manual queries and verification.

## Relevant Docker Commands
While the `Makefile` automates the general workflow, you may need to use native Docker commands for deeper debugging and monitoring. Run these commands from the root of the project (where the `docker-compose.yml` is located):

* `docker ps [-a]`: Displays all currently running containers. Add the `-a` flag to see all containers, including those that have crashed or stopped.
* `docker logs [-f] <container>`: Displays the log history for a specific container. Add the `-f` flag to follow the logs in real time.
* `docker exec -it <container> /bin/bash`: Access an interactive shell inside a container. This is extremely useful for verifying mounted files, checking permissions, or manually executing internal commands.
* `docker stats`: Displays real-time CPU and memory usage for all containers.
* `docker inspect <object>`: Inspect container, network, or volume details. This command outputs a JSON document containing low-level metadata such as internal IP addresses, mounted volume paths, network configuration, environment variables, and runtime state.

## Relevant Docker Compose Commands
Since this project is orchestrated using a `docker-compose.yml` file, these commands are the most relevant for managing the entire stack at once:

* `docker compose ps`: Lists the status of all services defined in the configuration, showing if they are "Up" or "Healthy".
* `docker compose logs [-f] [service]`: Aggregates logs from all services. Specify a service name to filter the output, and use `-f` to stream them.
* `docker compose up -d`: Starts the entire infrastructure in the background. It builds images, creates networks, and mounts volumes automatically.
* `docker compose down [-v] [--rmi all]`: Stops and removes all containers and networks. Add the `-v` flag to also delete the persistent volumes (use with caution!). The `--rmi all` option removes all images used by the services, including those built locally.
* `docker compose top`: Displays the running processes of each service in the stack, similar to the `top` command on Linux.
* `docker compose config`: Validates and displays the final rendered version of your configuration. This is perfect for verifying that your `.env` variables and secrets are correctly interpreted.

## Database Management (MariaDB)
To manage and verify your persistent data, you must interact with the MariaDB container. These commands allow you to access the database and perform basic checks to ensure it is not empty:

* `docker exec -it mariadb mariadb -u root -p`: Access the database with full administrative privileges. You will be prompted for the `MARIADB_ROOT_PASSWORD` defined in your `.env`.
* `docker exec -it mariadb mariadb -u [user] -p`: Access the database as a standard user (e.g., the WordPress user). You will be prompted for the `MARIADB_PASSWORD`.
* `SHOW DATABASES;`: Once inside the MariaDB prompt, this command lists all available databases. Look for your WordPress database here.
* `USE [database_name];`: Selects a specific database to work with. You must run this before querying tables.
* `SHOW TABLES;`: Lists all tables within the selected database. If WordPress is correctly installed, you should see about 12 tables (e.g., `wp_users`, `wp_posts`).
* `SELECT * FROM wp_users;`: Displays all columns and rows from the users table. This is the most effective way to prove the database is populated and to see your admin credentials.
* `SELECT user_login, user_email FROM wp_users;`: A quick query to display registered users, proving that the database has been populated with actual data.
* `exit`: Safely exits the MariaDB interactive shell and returns to your host terminal.

## Data Storage and Persistence
To ensure data persists across container restarts and recreations, we use Docker volumes bound to specific host directories via driver options. All persistent data is stored on the host machine under `/home/gdosch/data/`.

### Persistence Mechanism
Data is stored on the host machine to remain independent of the container's lifecycle:
* `/home/gdosch/data/mariadb` -> Mapped to `/var/lib/mysql` (Database files)
* `/home/gdosch/data/wordpress` -> Mapped to `/var/www/html` (Website core, themes, plugins, and static files)
* `/home/gdosch/data/arcane` -> Mapped to `/app/data` (Monitoring data)

### Lifecycle of Data
* `make down` / `make clean`: Containers are stopped/removed, but data persists in the host folders.
* `make fclean`: This is a destructive command. It explicitly removes the host data directories to allow a true "from scratch" installation. This is intended for development resets or project submission cleanup.

## Full Project Tutorial
This comprehensive guide details every step required to recreate the entire Inception infrastructure from scratch, from the initial virtual machine setup to the final container deployment.

> **Note on Naming Conventions:**  
> In this tutorial, we use `yourlogin` as a placeholder for your 42 username. Don't forget to replace every instance of it.

### 1. Download & Virtual Machine Setup

1. Download the **penultimate stable Debian ISO**.
2. Open **VirtualBox** and create a new Virtual Machine. Apply the following settings:
    * **VM Name:** `inception`
    * **VM Folder:** (Your preferred location, ideally a fast USB stick)
    * **ISO image:** Path to your downloaded Debian ISO
    * **Uncheck:** "Proceed with Unattended Installation"
    * In **Specify virtual hardware**, set **Base Memory** to `2048 MB` and the **Number of CPUs** to `2`.
    * In **Specify virtual hard disk**, select **"Create a New Virtual Hard Disk"** and set the **Disk Size** to `20.00 GB`.
    * In **Hard Disk File Type and Format**, select **"VDI (VirtualBox Disk Image)"** and check **"Pre-allocate Full Size"**.
    * Click on **Finish**.

The virtual disk will now be created by VirtualBox, which will take a few minutes. Once it is created, select the **`inception`** virtual machine and click **Start**.

---

### 2. Debian Installation

The Debian installation will begin. Select **"Graphical Install"**. This option provides a more comfortable setup experience but will not automatically install a graphical interface. Then proceed with the following options:

*   **Language:** English
*   **Location:** Your location
*   **Locales:** United States - en_US.UTF-8
*   **Keyboard Keymap:** American English
*   **Hostname:** `inception`
*   **Domain name:** (leave blank)
*   **Root password:** (Password of your choice)
*   **Full name:** (Your login)
*   **Username:** (Your login)
*   **User password:** (Password of your choice)

For partitioning and software selection:
*   **Partitioning method:** Guided - use entire disk
*   **Select disk:** (Select the only available disk)
*   **Partitioning scheme:** All files in one partition
*   Click **Continue**, select **Yes** to apply the changes, and click **Continue**.
*   **Scan extra installation media:** No
*   **Debian archive mirror country:** Your country
*   **Debian archive mirror:** `deb.debian.org`
*   **HTTP proxy:** (leave blank)
*   **Participate in package survey:** No
*   **Software selection:** 
    *   `[ ]` Debian desktop environment
    *   `[ ]` GNOME
    *   `[x]` SSH server
    *   `[x]` standard system utilities
    *   and leave all other options unchecked
*   **Install GRUB boot loader:** Yes
*   **Device for boot loader:** Your `/dev/sda` or `/dev/vda` disk

When the installation is complete, click **Continue** to reboot.

---

### 3. Sudo Setup

After rebooting, log in using the username and password provided earlier. Once logged in (`yourlogin@inception:~$`):

1. Switch to the superuser (root):
   ```bash
   su -
   ```
   Don’t forget the hyphen, it is important, and enter your root account password.

2. Install the `sudo` utility:
   ```bash
   apt update && apt install sudo
   ```
3. Add your user to the administrators group:
   ```bash
   usermod -aG sudo yourlogin
   ```

---

### 4. Network Configuration

Go to the **VirtualBox** main window. Select your VM -> **Settings** -> **Network** tab. 
Choose between **Bridged Adapter** and **NAT** and :

*   **Bridged mode:** Connects the VM directly to your local network. You can access `yourlogin.42.fr` without port forwarding, but you may require `/etc/hosts` and `ssh config` updates because the IP can change on reboot.

    Find the VM's IP:

    ```bash
    hostname -I
    ```

    Then note the first IP address displayed — we will need it.

*   **NAT mode:** Isolates the VM in a private network. The VM can access the internet, but your host cannot access VM services without port forwarding.

    Click on **Port Forwarding** and add the following rules:

    | Rule Name    | Protocol | Host IP   | Host Port | Guest IP | Guest Port |
    |--------------|----------|-----------|-----------|----------|------------|
    | **SSH**      | TCP      | 127.0.0.1 | 2222      |          | 22         |
    | **HTTPS**    | TCP      | 127.0.0.1 | 8443      |          | 443        |

    Apply the changes.

Now, restart the VM:

```bash
reboot
```

And log in again, using your username and password.

---

### 5. SSH & VSCode Access

From your **host machine's terminal**, verify the SSH connection:

*   Using **Bridged Mode:**

    ```
    ssh yourlogin@<your_vm_ip_address>
    ```

*   Using **NAT Mode:**

    ```
    ssh yourlogin@localhost -p 2222
    ```

Confirm the fingerprint (`yes`) and enter your user password. If your prompt changes to yourlogin@inception:~$, it means everything is working correctly.

#### Connect VSCode via SSH

Now we will use this connection to link Visual Studio Code.

1. Open VSCode on your physical computer.

2. Go to the Extensions tab (the small squares icon on the left) or press Ctrl+Shift+X (or Cmd+Shift+X on Mac).

3. Search for and install the official Remote - SSH extension (published by Microsoft).

Then, edit the local SSH configuration file:

4. Open **VSCode** locally and install the **"Remote - SSH"** extension.

5. Open the command palette (`Ctrl+Shift+P` / `Cmd+Shift+P`), type **SSH: Open SSH Configuration File**.

6. Select your user's config file (e.g., `~/.ssh/config`) and add the corresponding block:

    **For Bridged Mode:**

    ```ssh-config
    Host inception
        HostName <your_vm_ip_address>
        User <yourlogin>
    ```

    **For NAT Mode:**

    ```ssh-config
    Host inception
        HostName localhost
        User <yourlogin>
        Port 2222
    ```

    We can now connect to the virtual machine via SSH from VSCode.

7. In VSCode, click the `><` icon (bottom-left) -> **Connect to Host...** -> **inception**.

8. A new VSCode window will open and you will then be prompted to enter your password (the one for the "yourlogin" user).

9. Once connected, go to the VSCode file explorer (on the left), click **Open Folder**, then select `/home/<yourlogin>` and confirm.

10. To avoid VSCode asking for your password too often, you can set up an SSH key. If you are not interested, skip to the "Local Domain DNS Routing" chapter. Otherwise, if you already have one, skip to the next step.

    > **Be careful:** generating a new SSH key can overwrite an existing one if you are not attentive to the file location, so make sure you know what you are doing before proceeding. If you don’t have an SSH key yet, you first need to create one. In your physical computer’s terminal (not the VM), run:

    ```bash
    ssh-keygen -t rsa -b 4096
    ```

    Press Enter for all prompts to accept the default options and do not set a passphrase for the key.

11. Then, once the key is created (or if you already had one), send it to your virtual machine using the following command:

    **For Bridged Mode:**

    ```
    ssh-copy-id yourlogin@your_vm_ip_address
    ```

    **For NAT Mode:**

    ```
    ssh-copy-id -p 2222 yourlogin@localhost
    ```

    You will be asked for your password one last time. After that, the connection between VSCode and your VM will be instant and seamless.

---

### 6. Local Domain DNS Routing

We will also need to modify the `/etc/hosts` file so that your domain name (`yourlogin.42.fr`) correctly resolves to your virtual machine. This allows your system to redirect requests for the domain to the right IP address, whether you are using a browser or tools like VSCode and SSH.

Open your host's `/etc/hosts` file (with `sudo`):
```bash
sudo nano /etc/hosts
```

Add the following line based on your mode:

* **For Bridged Mode:**

  ```
  <your_vm_ip_address>   yourlogin.42.fr
  ```

  If the VM’s IP address changes, you must update it both in this `/etc/hosts` file and in your VSCode SSH configuration as well.

* **For NAT Mode:**

  ```
  127.0.0.1   yourlogin.42.fr
  ```

---

### 7. Install Docker

Open the VSCode integrated terminal (`Ctrl+J`) directly inside the VM and install Docker using the official repository:

Add Docker's official GPG key:
```bash
sudo apt update && sudo apt install ca-certificates curl
```

```bash
sudo install -m 0755 -d /etc/apt/keyrings
```

```bash
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
```

```bash
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

Add the repository to Apt sources:
```bash
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: \$(. /etc/os-release && echo "\$VERSION_CODENAME")
Components: stable
Architectures: \$(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```

Install Docker:
```bash
sudo apt update && sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

The Docker service starts automatically after installation. To verify that Docker is running, use: `sudo systemctl status docker` and `docker compose version`.

To use Docker without `sudo`:
```bash
sudo usermod -aG docker yourlogin
```
*(You may need to log out and log back in for this to take effect.)*

https://docs.docker.com/engine/install/debian/#install-using-the-repository

---

### 8. Project Structure & Environment

We will now create the project directory structure. Be careful: the subject specifies a mandatory `srcs` directory, but it does not explicitly state that it must be located at the root of the project. In practice, we place `srcs` inside another directory (here, `inception`), because otherwise your home directory (`/home/yourlogin`) would have to be your Git repository, which is neither practical nor recommended.

Create the necessary folders:

```bash
mkdir -p \
    ~/inception/srcs/requirements/mariadb/tools \
    ~/inception/srcs/requirements/nginx/conf \
    ~/inception/srcs/requirements/nginx/tools \
    ~/inception/srcs/requirements/wordpress/tools \
    ~/inception/srcs/requirements/tools \
    ~/inception/secrets
```

Secure the repository by ignoring secrets and `.env`:
```bash
cat << 'EOF' > ~/inception/.gitignore
# Ignore the secrets directory (passwords)
secrets/

# Ignore the environment file(s) (variables)
.env
EOF
```

To create the `.env` file in `srcs` with the following configuration, type:
```bash
cat << 'EOF' > ~/inception/srcs/.env
DOMAIN_NAME=yourlogin.42.fr

# MARIADB SETUP
MARIADB_USER=yourlogin
MARIADB_DATABASE=wordpress
MARIADB_HOSTNAME=mariadb

# WORDPRESS SETUP
WP_TITLE=Inception
WP_ADMIN_USER=yourlogin
WP_ADMIN_EMAIL=yourlogin@student.42.fr
WP_USER=visitor
WP_USER_EMAIL=visitor@student.42.fr
EOF
```

Make sure to replace `yourlogin` with your actual 42 username.

While `.env` files are often used to store sensitive data, security best practices recommend keeping critical settings (i.e. passwords) into dedicated secret files. Replace the values in quotes with passwords of your choice securely in `~/inception/secrets/`:

```bash
cd ~/inception/secrets
```

```bash
echo -n "your_db_password" > db_password.txt
```

```bash
echo -n "your_db_root_password" > db_root_password.txt
```

```bash
echo -n "your_wp_admin_password" > wp_admin_password.txt
```

```bash
echo -n "your_wp_user_password" > wp_user_password.txt
```

---

### 9. Docker-Compose & Makefile

Now that our environment variables and secrets are ready, it's time to create the docker-compose.yml file. This file acts as the architect of your infrastructure, defining how our services interact, which networks they use, and where they store their data:

```
touch ~/inception/srcs/docker-compose.yml
```

Then copy the following configuration into it:
```yaml
name: inception

# YAML Anchor to standardize logging across all services
x-logging: &default-logging
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"

services:
  mariadb:
    build:
      context: ./requirements/mariadb
    image: mariadb:inception-v1
    container_name: mariadb
    restart: unless-stopped
    healthcheck:
      # Verifies DB readiness:
      # - mariadb-admin ping: sends a connection check to the server
      # - -h 127.0.0.1: forces connection through the local network interface
      # - -uroot: connects with root privileges for the health probe
      # - -p$$(cat ...): securely reads the root password from the Docker secret file
      # - --silent: prevents status messages from cluttering container logs
      test: ["CMD-SHELL", "mariadb-admin ping -h 127.0.0.1 -uroot -p$$(cat /run/secrets/db_root_password) --silent"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 15s
    environment:
      # Explicit mapping: only injects required variables instead of using 'env_file: .env'
      - MARIADB_DATABASE=${MARIADB_DATABASE}
      - MARIADB_USER=${MARIADB_USER}
      - MARIADB_HOSTNAME=${MARIADB_HOSTNAME}
    secrets:
      - db_password
      - db_root_password
    volumes:
      - mariadb_data:/var/lib/mysql
    networks:
      - inception
    logging: *default-logging

  wordpress:
    build:
      context: ./requirements/wordpress
    image: wordpress:inception-v1
    container_name: wordpress
    restart: unless-stopped
    depends_on:
      mariadb:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      # Verifies that the PHP-FPM process is active and running:
      # - pgrep php-fpm: searches for any process matching the PHP-FPM name.
      # - > /dev/null: redirects output to keep the healthcheck logs clean.
      # - || exit 1: ensures the container is marked as 'unhealthy' if no process is found.
      # This is more flexible than checking for a specific versioned binary name.
      test: ["CMD-SHELL", "pgrep php-fpm > /dev/null || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s # Gives wp-cli enough time to download and install everything during the first boot
    environment:
      # Explicit mapping: only injects required variables instead of using 'env_file: .env'
      - MARIADB_HOSTNAME=${MARIADB_HOSTNAME}
      - MARIADB_DATABASE=${MARIADB_DATABASE}
      - MARIADB_USER=${MARIADB_USER}
      - WP_ADMIN_USER=${WP_ADMIN_USER}
      - WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL}
      - DOMAIN_NAME=${DOMAIN_NAME}
      - WP_TITLE=${WP_TITLE}
      - WP_USER=${WP_USER}
      - WP_USER_EMAIL=${WP_USER_EMAIL}
    secrets:
      - db_password
      - redis_password
      - wp_admin_password
      - wp_user_password
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - inception
    logging: *default-logging

  nginx:
    build:
      context: ./requirements/nginx
    image: nginx:inception-v1
    container_name: nginx
    restart: unless-stopped
    depends_on:
      wordpress:
        condition: service_healthy
    healthcheck:
      # Verifies the web server is operational and serving content via HTTPS:
      # - wget: uses the built-in web downloader to probe the server.
      # - --no-check-certificate: ignores SSL validation since we use self-signed certs.
      # - --spider: runs in web-crawler mode (checks page existence without downloading).
      # - https://localhost: specifically tests the encrypted connection on the local interface.
      # - || exit 1: triggers an 'unhealthy' status if the request fails or times out.
      test: ["CMD-SHELL", "wget --no-check-certificate --spider https://localhost || exit 1"]
      interval: 15s
      timeout: 5s
      retries: 5
    environment:
      # Explicit mapping: only injects required variables instead of using 'env_file: .env'
      - DOMAIN_NAME=${DOMAIN_NAME}
    volumes:
      - wordpress_data:/var/www/html:ro
    networks:
      - inception
    ports:
      - "443:443" # Only HTTPS port is exposed to the host
    logging: *default-logging

# Docker Secrets: Files are mounted as temporary files inside /run/secrets/ in containers
secrets:
  db_password:
    file: ../secrets/db_password.txt
  db_root_password:
    file: ../secrets/db_root_password.txt
  wp_admin_password:
    file: ../secrets/wp_admin_password.txt
  wp_user_password:
    file: ../secrets/wp_user_password.txt

networks:
  inception:
    driver: bridge # Standard bridge network for inter-container communication (default mode)

# Mapped named volumes (configured as bind-mounts) to specific host paths
volumes:
  mariadb_data:
    driver_opts:
      type: none
      o: bind
      device: /home/yourlogin/data/mariadb
  wordpress_data:
    driver_opts:
      type: none
      o: bind
      device: /home/yourlogin/data/wordpress
```

https://docs.docker.com/compose/gettingstarted/

Now, create the `Makefile`:

```bash
touch ~/inception/Makefile
```

And copy the following into it and make sure to use actual Tabs instead of spaces for indentation:

```makefile
DATA_PATH = /home/gdosch/data
COMPOSE_FILE = srcs/docker-compose.yml

.PHONY: all build up down mariadb clean fclean re

all: up

# Create local storage directories and build images
build:
	@mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress
	docker compose -f $(COMPOSE_FILE) build

# Start containers in detached mode
up: build
	docker compose -f $(COMPOSE_FILE) up -d

# Stop running containers
down:
	docker compose -f $(COMPOSE_FILE) down

# Access the database command line
mariadb:
	docker exec -it mariadb mariadb -u root -p

# Standard cleanup: removes stopped containers and dangling resources (cache, networks)
clean: down
	@docker system prune -f

# Full cleanup: total wipe of the Docker environment and local data
fclean: 
#   Removes all containers, networks, volumes, and images defined in the project
	docker compose -f $(COMPOSE_FILE) down -v --rmi all

#   Deep clean: removes all unused images and entire build cache (including non-dangling)
	@docker system prune -af

#   Security check: ensures DATA_PATH is set and is not the root directory to prevent system damage
	@if [ -z "$(DATA_PATH)" ] || [ "$(DATA_PATH)" = "/" ]; then \
		echo "Error: DATA_PATH is empty or set to root. Aborting wipe."; \
		exit 1; \
	fi

#   Requires sudo password to securely delete persistent data from the host
	@sudo rm -rf $(DATA_PATH)

# Complete rebuild from scratch
re: fclean all
```

https://docs.docker.com/compose/intro/compose-application-model/

---

### 10. Dockerfiles, Entrypoint Scripts and other configuration files

The configuration files (`Dockerfile`, `entrypoint.sh`, `nginx.conf`, etc.) need to be written according to the tutorial provided previously. Follow the setup code to place each `Dockerfile` internally correctly:


**MariaDB Setup**

Create the `Dockerfile`:

```bash
touch ~/inception/srcs/requirements/mariadb/Dockerfile
```

And copy the following in it:

```dockerfile
# Use the stable Debian Bookworm as base image
FROM debian:12

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update the system and install MariaDB server and client
RUN apt-get update && apt-get install -y \
	mariadb-server mariadb-client && \
	rm -rf /var/lib/apt/lists/*

# Create required directories for the database and the socket
# and ensure the 'mysql' user owns them
RUN mkdir -p /var/lib/mysql /run/mysqld && \
	chown -R mysql:mysql /var/lib/mysql /run/mysqld

# Copy the initialization script to the container
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the default MariaDB port
EXPOSE 3306

# Define the script that will handle the initial setup
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed by the entrypoint script (PID 1)
# We must specify --user=mysql to avoid the "run as root" error
# --bind-address=0.0.0.0 allows connections from other containers
CMD ["mariadbd", "--user=mysql", "--bind-address=0.0.0.0", "--port=3306"]
```

Then, create the `entrypoint.sh` script:

```bash
touch ~/inception/srcs/requirements/mariadb/tools/entrypoint.sh
```

And copy the following in it:

```bash
#!/bin/sh

# Stop the script immediately if any command fails
set -e

# 1. Fetch secrets from Docker secret mount points (RAM-only files)
# This avoids passing sensitive passwords through environment variables
MARIADB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MARIADB_PASSWORD=$(cat /run/secrets/db_password)

# 2. Fail-fast validation
# Ensures all necessary credentials are present before attempting installation
if [ -z "$MARIADB_ROOT_PASSWORD" ] || [ -z "$MARIADB_DATABASE" ] || [ -z "$MARIADB_USER" ] || [ -z "$MARIADB_PASSWORD" ]; then
    echo "Error: Missing mandatory database environment variables or secrets." >&2
    exit 1
fi

# 3. MariaDB Installation Logic
# Only run initialization if the command passed is 'mariadbd'
if [ "$1" = 'mariadbd' ]; then
    # Custom marker file check to ensure persistence (skips if already initialized)
    if [ ! -f "/var/lib/mysql/.initialized" ]; then
        echo "Initializing MariaDB database..."

        # Ensure the mysql user owns the data directory for proper permissions
        chown -R mysql:mysql /var/lib/mysql

        # Create system tables and initial database structure
        mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null

        # Use bootstrap to configure users and database privileges
        # This executes SQL commands without starting the full network server
        mariadbd --user=mysql --datadir=/var/lib/mysql --bootstrap <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MARIADB_DATABASE};
CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MARIADB_DATABASE}.* TO '${MARIADB_USER}'@'%';
FLUSH PRIVILEGES;
EOF
        # Create the marker file to confirm successful first-time setup
        touch /var/lib/mysql/.initialized
        echo "MariaDB initialized successfully."
    fi
fi

# 4. Execute the command from CMD
# 'exec' replaces the shell with the MariaDB process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
```

**WordPress Setup**

Create the `Dockerfile`:

```bash
touch ~/inception/srcs/requirements/wordpress/Dockerfile
```

And copy the following in it:

```dockerfile
# Use Debian Bookworm as the base image
FROM debian:12

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install PHP-FPM, MySQL extensions, and required tools
RUN apt-get update && apt-get install -y \
	php8.2-fpm php8.2-mysql php8.2-curl php8.2-gd php8.2-intl \
	php8.2-mbstring php8.2-xml php8.2-zip \
	wget mariadb-client ca-certificates && \
	rm -rf /var/lib/apt/lists/*

# Install WP-CLI (WordPress Command Line Interface)
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
	chmod +x wp-cli.phar && \
	mv wp-cli.phar /usr/local/bin/wp

# Create directory for PHP-FPM runtime files and set correct permissions
RUN mkdir -p /run/php && \
	chown -R www-data:www-data /run/php

# Configure PHP-FPM to listen on port 9000 instead of a Unix socket for network communication
RUN sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 9000|' /etc/php/8.2/fpm/pool.d/www.conf

# Set the working directory to the web root
WORKDIR /var/www/html

# Copy the entrypoint script into the container
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the PHP-FPM port
EXPOSE 9000

# Set the entrypoint script to handle setup at container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed by the entrypoint script (PID 1)
CMD ["php-fpm8.2", "-F"]
```

Create the `entrypoint.sh` script:

```bash
touch ~/inception/srcs/requirements/wordpress/tools/entrypoint.sh
```

And copy the following in it:

```bash
#!/bin/sh

# Stop the script immediately if any command fails
set -e

# 1. Fetch secrets from Docker secret mount points
# Retrieves sensitive credentials from Docker secret files
MARIADB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

# 2. Fail-fast validation
# Ensures all necessary credentials are present before attempting installation

# Database checks
if [ -z "$MARIADB_HOSTNAME" ] || [ -z "$MARIADB_DATABASE" ] || [ -z "$MARIADB_USER" ] || [ -z "$MARIADB_PASSWORD" ]; then
    echo "Error: Missing database environment variables or secrets." >&2
    exit 1
fi

# Admin checks
if [ -z "$WP_ADMIN_USER" ] || [ -z "$WP_ADMIN_PASSWORD" ] || [ -z "$WP_ADMIN_EMAIL" ]; then
    echo "Error: Missing admin environment variables or secrets." >&2
    exit 1
fi

# Site and Secondary User checks
if [ -z "$DOMAIN_NAME" ] || [ -z "$WP_TITLE" ] || [ -z "$WP_USER" ] || [ -z "$WP_USER_PASSWORD" ] || [ -z "$WP_USER_EMAIL" ]; then
    echo "Error: Missing site or secondary user environment variables." >&2
    exit 1
fi

# 3. Service Initialization & Dependencies
# Service availability check: ensures the database is up before running WP-CLI commands
echo "Waiting for MariaDB to be ready..."
until mariadb -h"$MARIADB_HOSTNAME" -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
    sleep 2
done

# 4. WordPress & Redis Configuration Logic
# Skips if wp-config.php exists (persistence check for already initialized volumes)
if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "WordPress not found. Starting installation..."

    # Downloads the WordPress core files
    wp core download --allow-root

    # Generates wp-config.php with provided database credentials
    wp config create \
        --dbname="$MARIADB_DATABASE" \
        --dbuser="$MARIADB_USER" \
        --dbpass="$MARIADB_PASSWORD" \
        --dbhost="$MARIADB_HOSTNAME" \
        --allow-root

    # Configures the database and creates the primary administrator account
    wp core install \
        --url="https://$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root

    # Creates the mandatory non-administrator user required by the subject
    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --role=author \
        --user_pass="$WP_USER_PASSWORD" \
        --allow-root

    # Redis Setup (Bonus)
    echo "Configuring Redis Cache with authentication..."
    
    # Fetch the redis password from secret to use it in wp-config
    REDIS_PWD=$(cat /run/secrets/redis_password)

    wp plugin install redis-cache --activate --allow-root

    # Injects Redis connection constants into wp-config.php
    wp config set WP_REDIS_HOST redis --allow-root
    wp config set WP_REDIS_PORT 6379 --raw --allow-root
    wp config set WP_REDIS_PASSWORD "$REDIS_PWD" --allow-root

    # Enables the object cache to start using Redis
    wp redis enable --allow-root

    # Finalizes file permissions for the web server (www-data)
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    echo "WordPress installed successfully."
fi

# 5. Execute the command from CMD
# 'exec' replaces the shell with the PHP-FPM process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
```

**NGINX Setup**

Create the `Dockerfile`:

```bash
touch ~/inception/srcs/requirements/nginx/Dockerfile
```

And copy the following in it:

```dockerfile
# Use Debian Bookworm as the base image
FROM debian:12

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update the system and install NGINX and OpenSSL
RUN apt-get update && apt-get install -y \
	nginx openssl && \
	rm -rf /var/lib/apt/lists/*

# Copy the NGINX configuration file into the container
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Copy the entrypoint script and make it executable
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose port 443 for HTTPS traffic
EXPOSE 443

# Define the script that will handle the initial setup
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Run NGINX in the foreground so the container doesn't exit
CMD ["nginx", "-g", "daemon off;"]
```

Create the `entrypoint.sh` script:

```bash
touch ~/inception/srcs/requirements/nginx/tools/entrypoint.sh
```

And copy the following in it:

```bash
#!/bin/sh

# Stop the script immediately if any command fails
set -e

# 1. Fail-fast validation
# Ensures DOMAIN_NAME is set before generating certificates
if [ -z "$DOMAIN_NAME" ]; then
    echo "[ERROR] DOMAIN_NAME environment variable is missing." >&2
    exit 1
fi

# 2. Dynamic Configuration Injection
# Replaces the placeholder in the template with the actual domain name at runtime
echo "[INFO] Configuring NGINX for domain: $DOMAIN_NAME"
sed -i "s/__DOMAIN_NAME__/$DOMAIN_NAME/g" /etc/nginx/nginx.conf

# 3. SSL Certificate Generation
# Creates a self-signed certificate if not present (persistence check)
CERTS_DIR="/etc/nginx/ssl"

if [ ! -f "$CERTS_DIR/$DOMAIN_NAME.crt" ]; then
    echo "[INFO] Generating self-signed SSL certificate..."
    
    mkdir -p "$CERTS_DIR"
    
    # Generate a non-interactive RSA 2048-bit key and certificate valid for 365 days
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERTS_DIR/$DOMAIN_NAME.key" \
        -out "$CERTS_DIR/$DOMAIN_NAME.crt" \
        -subj "/C=FR/ST=GrandEst/L=Mulhouse/O=42/OU=Inception/CN=$DOMAIN_NAME"
        
    echo "[INFO] SSL certificate generated successfully."
fi

# 4. Execute the command from CMD
# 'exec' replaces the shell with the NGINX process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
```

NGINX also needs a `nginx.conf` file:

```bash
touch ~/inception/srcs/requirements/nginx/conf/nginx.conf
```

Copy the following in it:

```nginx
# NGINX Configuration File

# Run nginx as www-data user for security to prevent running as root
user www-data;

# Set the number of worker processes automatically based on available CPU cores
worker_processes auto;

# Path to store the master process ID
pid /run/nginx.pid;

events {
    # Maximum number of simultaneous connections that can be opened by a worker process
    worker_connections 1024;
}

http {
    # Basic settings and MIME types
    include /etc/nginx/mime.types;

    # Fallback MIME type for unknown file extensions
    default_type application/octet-stream;

    # Logging paths for incoming HTTP requests and errors
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Main Server Block
    server {
        # Listen exclusively on port 443 (HTTPS) for both IPv4 and IPv6
        listen 443 ssl;
        listen [::]:443 ssl;

        # The server name (domain) will be dynamically replaced by the entrypoint script
        server_name __DOMAIN_NAME__;

        # SSL Configuration
        ssl_certificate /etc/nginx/ssl/__DOMAIN_NAME__.crt;
        ssl_certificate_key /etc/nginx/ssl/__DOMAIN_NAME__.key;
        ssl_protocols TLSv1.2 TLSv1.3;

        # Root directory where our website files are located (shared via Docker volumes)
        root /var/www/html;
        
        # Priority list of default files to serve when a directory is requested
        index index.php index.html index.htm;

        # Route all standard requests to the root location
        location / {
            # Try to serve the exact URI, then a directory (with /), and fallback to index.php
            try_files $uri $uri/ /index.php?$args;
        }

        # Pass PHP scripts to PHP-FPM (running in the WordPress container)
        location ~ \.php$ {
            # Prevent NGINX from forwarding non-existent files to PHP-FPM (Security measure)
            try_files $uri =404;
            
            # Forward the request to the 'wordpress' container on port 9000
            fastcgi_pass wordpress:9000;

            # Default file to process if none is specified
            fastcgi_index index.php;

            # Include standard FastCGI parameters
            include fastcgi_params;
            
            # Explicitly tell PHP which file to execute based on the document root
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }

        # Security: deny access to all hidden files (like .htaccess, .env)
        location ~ /\. {
            deny all;
        }
    }
}
```

Sources:  
https://docs.docker.com/get-started/docker-concepts/building-images/writing-a-dockerfile/  
https://docs.docker.com/reference/dockerfile/#entrypoint  
https://nginx.org/en/docs/beginners_guide.html

---

### 11. Run the Project!

Once everything is written and mapped out, run the following commands to install `make` and start the infrastructure:

```bash
sudo apt update && sudo apt install -y make
cd ~/inception
make
```

Your system is alive at `https://yourlogin.42.fr` (Accept the self-signed certificate warning in your browser).

---

## BONUS Deployments

### Bonus 1: REDIS
Redis is an excellent performance upgrade for your WordPress site. We will now create a secret for it. Type the following and replace `your_redis_password` with a password of your choice:
```bash
echo -n "your_redis_password" > ~/inception/secrets/redis_password.txt 
```

Let's create the structure:
```bash
mkdir -p ~/inception/srcs/requirements/bonus/redis/tools
```

We will now create the Redis `Dockerfile`:
```bash
touch ~/inception/srcs/requirements/bonus/redis/Dockerfile
```

Copy and paste the following configuration in it:
```dockerfile
# Use Debian Bookworm as the base image
FROM debian:12

# Install redis-server
RUN apt-get update && apt-get install -y \
	redis-server \
	&& rm -rf /var/lib/apt/lists/*

# Copy and prepare the entrypoint script
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the default Redis port
EXPOSE 6379

# Prepares the environment (secrets) before launching the application
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Redis is started by the entrypoint with the runtime secret applied
```

Now it's time to create the `entrypoint.sh` file for Redis:

```bash
touch ~/inception/srcs/requirements/bonus/redis/tools/entrypoint.sh
```

Copy and paste the following configuration in it:
```bash
#!/bin/sh

# Stop the script immediately if any command fails
set -e

# 1. Fetch the secret from Docker secret mount point
# Retrieves the password from the Docker secret file
REDIS_PASSWORD=$(cat /run/secrets/redis_password)

# 2. Fail-fast validation
if [ -z "$REDIS_PASSWORD" ]; then
    echo "Error: REDIS_PASSWORD secret is missing." >&2
    exit 1
fi

echo "Starting Redis server..."

# 3. Start Redis with the secret fetched above
# 'exec' replaces the shell with the Redis process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec redis-server --bind 0.0.0.0 --requirepass "$REDIS_PASSWORD" --protected-mode no
```

To ensure a deterministic startup and service health monitoring, we update the `docker-compose.yml` as follows:
```yaml
# 1. Update the 'wordpress' service and add the 'redis' one
services:
  # ... other services
  wordpress:
    # ... other configs
    depends_on:
      mariadb:
        condition: service_healthy
      redis:
        condition: service_healthy
    # ... other configs
    secrets:
      - db_password
      - redis_password
      - wp_admin_password
      - wp_user_password
  # ...
  redis:
    build:
      context: ./requirements/bonus/redis
    image: redis:inception-v1
    container_name: redis
    restart: unless-stopped
    healthcheck:
      # Verifies Redis availability by performing a handshake:
      # - redis-cli ping: sends the standard PING command to the server.
      # - -h 127.0.0.1: targets the local instance within the container.
      # - -a "$$(cat ...)": securely authenticates using the password from the Docker secret.
      # - grep PONG: confirms the server specifically responded with the expected 'PONG'.
      # - || exit 1: ensures the container is marked 'unhealthy' if the handshake fails.
      test: ["CMD-SHELL", "redis-cli -h 127.0.0.1 -a \"$$(cat /run/secrets/redis_password)\" ping | grep PONG || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 5s
    secrets:
      - redis_password
    networks:
      - inception
    logging: *default-logging

# 2. Add this in the main 'secrets' section at the bottom
secrets:
  # ... your other secrets
  redis_password:
    file: ../secrets/redis_password.txt
```

The WordPress `entrypoint.sh` file also needs editing, add the following between the secondary account creation and the ownership and permissions configuration:

```bash
# Redis Setup (Bonus)
    echo "Configuring Redis Cache with authentication..."
    
    # Fetch the redis password from secret to use it in wp-config
    REDIS_PWD=$(cat /run/secrets/redis_password)

    wp plugin install redis-cache --activate --allow-root

    # Injects Redis connection constants into wp-config.php
    wp config set WP_REDIS_HOST redis --allow-root
    wp config set WP_REDIS_PORT 6379 --raw --allow-root
    wp config set WP_REDIS_PASSWORD "$REDIS_PWD" --allow-root

    # Enables the object cache to start using Redis
    wp redis enable --allow-root
```

Rebuild your infrastructure using `make re` to apply the changes and verify that everything is working as expected, by opening your browser and go to:

https://yourlogin.42.fr/wp-admin

Log in using your credentials, then navigate to Settings → Redis. If you can read “Status: Connected” displayed in green, everything works fine.

---

### Bonus 2: FTP

FTP (File Transfer Protocol) is a classic bonus with real practical value. It allows you to upload and retrieve files (images, themes, plugins, etc.) directly into your WordPress directory from your physical machine, using a client such as FileZilla. We're going to use **vsftpd** (Very Secure FTP Daemon).

let's start by creating a secret for it:
```bash
echo -n "your_ftp_password" > ~/inception/secrets/ftp_password.txt
```

Add your username at the end of the `.env` file:
```env
# FTP SETUP (BONUS)
FTP_USER=yourlogin
```

Let's create the structure:
```bash
mkdir -p ~/inception/srcs/requirements/bonus/ftp/tools
```

We will now create the FTP `Dockerfile`:
```bash
touch ~/inception/srcs/requirements/bonus/ftp/Dockerfile
```

Copy and paste the following configuration:
```dockerfile
# Use Debian Bookworm as the base image
FROM debian:12

# Install vsftpd (Very Secure FTP Daemon)
RUN apt-get update && apt-get install -y \
	vsftpd \
	&& rm -rf /var/lib/apt/lists/*

# Copy and prepare the entrypoint script
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose FTP port and passive mode range
EXPOSE 21 40000-40005

# Prepares the environment (users, permissions, secrets) before launching
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default binary executed as PID 1 via the entrypoint's 'exec "$@"'
CMD ["vsftpd", "/etc/vsftpd.conf"]
```

**vsftpd** requires a system user to operate. We create it dynamically at runtime with an `entrypoint.sh` file:

```bash
touch ~/inception/srcs/requirements/bonus/ftp/tools/entrypoint.sh
```

Copy and paste the following configuration:
```bash
#!/bin/sh

# Stop the script immediately if any command fails
set -e

# 1. Fetch secrets from Docker secret mount points
FTP_PASSWORD=$(cat /run/secrets/ftp_password)

# 2. Fail-fast validation
if [ -z "$FTP_USER" ] || [ -z "$FTP_PASSWORD" ]; then
    echo "Error: FTP_USER or ftp_password secret is missing." >&2
    exit 1
fi

# 3. User Creation and Permissions
# Create the FTP user if it doesn't exist and set their password
if ! id "$FTP_USER" >/dev/null 2>&1; then
    useradd -m -d /var/www/html -s /bin/bash "$FTP_USER"
    echo "$FTP_USER:$FTP_PASSWORD" | chpasswd
else
    usermod -d /var/www/html "$FTP_USER"
fi

# Ensure the webroot is owned by the FTP user for upload capabilities
echo "Setting permissions for /var/www/html..."
chown -R "$FTP_USER:$FTP_USER" /var/www/html
chmod -R 755 /var/www/html

# 4. Prepare the runtime environment
# vsftpd requires this specific directory to run for isolation (chroot)
mkdir -p /var/run/vsftpd/empty

# Generate the vsftpd configuration used by the container
cat <<EOF > /etc/vsftpd.conf
# Run in the foreground (required for Docker containers)
listen=YES
listen_ipv6=NO

# Access rights for local users
local_enable=YES
write_enable=YES
local_umask=022

# Security & Chroot (isolates the user in their home directory)
chroot_local_user=YES
allow_writeable_chroot=YES
secure_chroot_dir=/var/run/vsftpd/empty

# Passive mode configuration (Crucial for Docker NAT networking)
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40005
pasv_address=0.0.0.0
EOF

echo "Starting FTP server for user: $FTP_USER"

# 5. Execute the command from CMD
# 'exec' replaces the shell with the vsftpd process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
```

Passive mode is essential here, as Docker uses NAT networking. Without it, the FTP client would not be able to list or transfer files correctly.

It is now time to update the `docker-compose.yml` file:
```yaml
# 1. Update the 'wordpress' service to prevent access
# to the unrelated 'FTP_USER' environment variable.
  wordpress:
    # ... keep existing config
    # Replace 'env_file: .env' with explicit mapping:
    environment:
      # Explicit mapping: only injects required variables instead of using 'env_file: .env'
      - MARIADB_HOSTNAME=${MARIADB_HOSTNAME}
      - MARIADB_DATABASE=${MARIADB_DATABASE}
      - MARIADB_USER=${MARIADB_USER}
      - WP_ADMIN_USER=${WP_ADMIN_USER}
      - WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL}
      - DOMAIN_NAME=${DOMAIN_NAME}
      - WP_TITLE=${WP_TITLE}
      - WP_USER=${WP_USER}
      - WP_USER_EMAIL=${WP_USER_EMAIL}

# 2. Add the 'ftp' service
services:
  # ... other services
  ftp:
    build:
      context: ./requirements/bonus/ftp
    image: ftp:inception-v1
    container_name: ftp
    restart: unless-stopped
    environment:
      # Explicit mapping: only injects required variables instead of using 'env_file: .env'
      - FTP_USER=${FTP_USER}
    secrets:
      - ftp_password
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - inception
    ports:
      - "21:21"
      - "40000-40005:40000-40005" # Passive mode port range
    logging: *default-logging

# 3. Add this to the main 'secrets' section at the bottom
secrets:
  # ... other secrets
  ftp_password:
    file: ../secrets/ftp_password.txt
```

It's time to rebuild your infrastructure using `make re` to apply the changes, and test the FTP service.

* **If you chose Bridged mode:**
    You can test it with the following command:

    ```bash
    curl -u yourlogin:yourpassword ftp://your_vm_ip_address:21/
    ```

* **If you chose NAT mode:**
    You first have to create all these port forwarding rules:

  | Name | Protocol | Host IP | Host Port | Guest IP | Guest Port |
  | :--- | :--- | :--- | :--- | :--- | :--- |
  | FTP-Command | TCP | 127.0.0.1 | 2121 | | 21 |
  | FTP-Pasv-0 | TCP | 127.0.0.1 | 40000 | | 40000 |
  | FTP-Pasv-1 | TCP | 127.0.0.1 | 40001 | | 40001 |
  | FTP-Pasv-2 | TCP | 127.0.0.1 | 40002 | | 40002 |
  | FTP-Pasv-3 | TCP | 127.0.0.1 | 40003 | | 40003 |
  | FTP-Pasv-4 | TCP | 127.0.0.1 | 40004 | | 40004 |
  | FTP-Pasv-5 | TCP | 127.0.0.1 | 40005 | | 40005 |

  Then, you can test it with the following command:

  ```bash
  curl -u yourlogin:yourpassword ftp://127.0.0.1:2121/
  ```

Alternatively, you can test the connection interactively using the `ftp` client with the following commands:
  ```bash
  sudo apt update && sudo apt install -y ftp
  ```

* **If you chose Bridged mode:**

    ```bash
    ftp your_vm_ip_address 21
    ```

* **If you chose NAT mode:**

    ```bash
    ftp 127.0.0.1 2121
  ```

If the connection is successful, you should see a listing of the files in your WordPress directory.

---

### Bonus 3: STATIC WEBSITE

This bonus consists of a simple static page served by a dedicated webserver container. For this service, we have decided to use **lighttpd**, a secure, fast, and very lightweight alternative to NGINX.

Create the project structure:

```bash
mkdir -p \
    ~/inception/srcs/requirements/bonus/static/www \
    ~/inception/srcs/requirements/bonus/static/conf
```

Let's create the `Dockerfile` for the static website:

```bash
touch ~/inception/srcs/requirements/bonus/static/Dockerfile
```

Copy and paste the following code in it:
```dockerfile
# Use Debian Bookworm as the base image
FROM debian:12

# Install lighttpd and clean up apt cache to keep the image slim
RUN apt-get update && apt-get install -y \
	lighttpd \
	&& rm -rf /var/lib/apt/lists/*

# Copy the configuration file
COPY ./conf/lighttpd.conf /etc/lighttpd/lighttpd.conf

# Copy our static files to the document root
COPY www /var/www/html

# Ensure the web server user (www-data) owns the files for proper access
RUN chown -R www-data:www-data /var/www/html

# Expose port 80 (internal container port)
EXPOSE 80

# Run lighttpd as PID 1
# -D: don't go to background (foreground mode, essential for Docker)
# -f: path to the configuration file
CMD ["lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]
```

Now, let's create a simple HTML file:
```bash
touch ~/inception/srcs/requirements/bonus/static/www/index.html
```

Copy and paste the following code in it:
```html
<!DOCTYPE html>
<html>
<head>
    <title>Inception - Static Site</title>
    <style>
        body { background-color: #1a1a1a; color: #00ff42; font-family: 'Courier New', monospace; 
               display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
        .box { border: 1px solid #00ff42; padding: 40px; text-align: center; }
        h1 { text-transform: uppercase; letter-spacing: 5px; }
    </style>
</head>
<body>
    <div class="box">
        <h1>Inception</h1>
        <p>Bonus Service: Static Website</p>
        <p>Status: Running on Debian 12</p>
    </div>
</body>
</html>
```

We will now configure the web server, **lighttpd**. Let's start with its configuration file:
```bash
touch ~/inception/srcs/requirements/bonus/static/conf/lighttpd.conf
```

Open it and paste the following configuration:
```conf
# Basic modules
server.modules = (
    "mod_access",
    "mod_accesslog"
)

# Standard Debian web server user/group
server.username         = "www-data"
server.groupname        = "www-data"

# Document root matching the path in the Dockerfile (COPY command)
server.document-root    = "/var/www/html"

# Internal port matching the EXPOSE 80 instruction
server.port             = 80

# Default file to serve
index-file.names        = ( "index.html" )

# Basic MIME types (add more if you use images or JS later)
mimetype.assign         = ( ".html" => "text/html" )

# Security: deny access to all hidden files (like .htaccess, .env)
$HTTP["url"] =~ "/\." {
    url.access-deny = ("")
}
```

We need to update the docker-compose.yml file and map the host port 8081 to the container port 80:
```yaml
# Add the 'static' service
services:
  # ... other services
  static:
    build:
      context: ./requirements/bonus/static
    image: static:inception-v1
    container_name: static
    restart: unless-stopped
    networks:
      - inception
    ports:
      - "8081:80"
    logging: *default-logging
```

Do not forget the VirtualBox rule if you chose the NAT mode:

| Rule Name    | Protocol | Host IP   | Host Port | Guest IP | Guest Port |
|--------------|----------|-----------|-----------|----------|------------|
| **Static**      | TCP      | 127.0.0.1 | 8081      |          | 8081         |

Rebuild your infrastructure using `make re` to apply the changes. To test the static website, open the following URL and make sure to use HTTP (not HTTPS):

http://yourlogin.42.fr:8081

---

### Bonus 4: ADMINER

Adminer is a lightweight database management tool written in a single PHP file. It is a great alternative to phpMyAdmin.

Create the structure:

```bash
mkdir -p ~/inception/srcs/requirements/bonus/adminer
```

We will now create the `Dockerfile`. Adminer doesn't even need local files or entrypoint scripts, we can download it directly when building the image.

```bash
touch ~/inception/srcs/requirements/bonus/adminer/Dockerfile
```

Copy and paste the following code in it:

```dockerfile
# Use Debian Bookworm as the base image for consistency
FROM debian:12

# Install PHP, the PHP-MySQL extension and wget (to download Adminer)
RUN apt-get update && apt-get install -y \
	php8.2 php8.2-mysql \
	wget && \
	rm -rf /var/lib/apt/lists/*

# Create the web directory
RUN mkdir -p /var/www/html

# Download Adminer directly into the web directory
# We rename it to index.php so the server loads it by default
RUN wget https://github.com/vrana/adminer/releases/download/v5.4.2/adminer-5.4.2.php -O /var/www/html/index.php

# Ensure proper permissions
RUN chown -R www-data:www-data /var/www/html

# Set the working directory
WORKDIR /var/www/html

# Expose port 8080
EXPOSE 8080

# Start PHP's built-in web server listening on all interfaces (PID 1)
CMD ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/html"]
```

We must update the `docker-compose.yml` file and add the Adminer service. We map it to port 8080. It needs to be on the inception network to communicate with the MariaDB container. Type:
```yaml
# Add the 'adminer' service
services:
  # ... other services
  adminer:
    build:
      context: ./requirements/bonus/adminer
    image: adminer:inception-v1
    container_name: adminer
    restart: unless-stopped
    depends_on:
      mariadb:
        condition: service_healthy
    networks:
      - inception
    ports:
      - "8080:8080"
    logging: *default-logging
```

If you chose NAT mode, add the following VirtualBox NAT Rule:

| Rule Name    | Protocol | Host IP   | Host Port | Guest IP | Guest Port |
|--------------|----------|-----------|-----------|----------|------------|
| **Adminer**      | TCP      | 127.0.0.1 | 8080      |          | 8080         |

Rebuild your infrastructure using `make re`. Open your browser and go to

http://yourlogin.42.fr:8080

You will be greeted by the Adminer login screen. Use the following credentials:
* System: MySQL / MariaDB
* Server: mariadb (This is the container name, Docker's internal DNS will resolve it)
* Username: yourlogin
* Password: The password you set in your secrets
* Database: wordpress

If you can log in and see your WordPress tables (wp_users, wp_posts, etc.), Adminer is fully functional!

---

### Bonus 5: ARCANE

Arcane is a modern, lightweight, and high-performance Docker management interface built with Go and SvelteKit. It allows you to monitor your Inception infrastructure, view logs in real-time, and manage containers through a beautiful Web UI.

We first need to create two new secrets:
```bash
echo -n 'MaSuperCleDeChiffrement32Chars!!' > ~/inception/secrets/arc_encryption_key.txt
echo -n 'MonAutreCleJWTTresSecrete424242!' > ~/inception/secrets/arc_jwt_secret.txt
```

Create the necessary folders for the Arcane requirements:
```bash
mkdir -p ~/inception/srcs/requirements/bonus/arcane/tools
```

Update your `Makefile` to include the Arcane data directory:
```makefile
@mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress $(DATA_PATH)/arcane
```

It's time to create the Arcane `Dockerfile`. We'll use a multi-stage build to keep our image lightweight while strictly basing our final container on Debian 12.

```bash
touch ~/inception/srcs/requirements/bonus/arcane/Dockerfile
```

Copy and paste the following code in it:

```dockerfile
# Stage 1: Temporary stage to get the binary
FROM ghcr.io/getarcaneapp/arcane:v1.18.1 AS builder

# Stage 2: Final image based on Debian 12
FROM debian:12

# Install requirements
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Setup application directory
WORKDIR /app
RUN mkdir -p /app/data

# Copy the binary from the builder stage
COPY --from=builder /app/arcane /usr/local/bin/arcane
RUN chmod +x /usr/local/bin/arcane

# Copy and prepare the entrypoint script
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose port 3552
EXPOSE 3552

# Prepares the environment (secrets) before launching the application
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default binary executed as PID 1 via the entrypoint's 'exec "$@"'
CMD ["arcane"]
```

Arcane also needs an `entrypoint.sh` script:

```bash
touch ~/inception/srcs/requirements/bonus/arcane/tools/entrypoint.sh
```

Copy and paste the following code in it:

```bash
#!/bin/sh

# Stops the script immediately if any command fails
set -e

# 1. Loads secrets into environment variables
export ENCRYPTION_KEY=$(cat /run/secrets/arc_encryption_key)
export JWT_SECRET=$(cat /run/secrets/arc_jwt_secret)

# 2. Execute the command from CMD
# 'exec' replaces the shell with the Arcane process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
```

Add the service and the secrets declaration to your `docker-compose.yml`:
```yaml
# Add the 'arcane' service
services:
  # ... other services
  arcane:
    build:
      context: ./requirements/bonus/arcane
    image: arcane:inception-v1
    container_name: arcane
    restart: unless-stopped
    secrets:
      - arc_encryption_key
      - arc_jwt_secret
    volumes:
      # Allows Arcane to interact with the host Docker daemon
      - /var/run/docker.sock:/var/run/docker.sock:rw
      - arcane_data:/app/data
    networks:
      - inception
    ports:
      - "3552:3552"
    logging: *default-logging

# Add to your secrets section at the bottom
secrets:
  # ... other secrets
  arc_encryption_key:
    file: ../secrets/arc_encryption_key.txt
  arc_jwt_secret:
    file: ../secrets/arc_jwt_secret.txt

# Add to your volumes section
volumes:
  # ... other volumes
  arcane_data:
    driver_opts:
      type: none
      o: bind
      device: /home/yourlogin/data/arcane
```

Rebuild your infrastructure using `make re` and open the following URL — make sure to use HTTP (not HTTPS):

http://yourlogin.42.fr:3552

Follow the setup instructions to create your admin account. The default username and password are `arcane` and `arcane-admin`. You can now see all your Inception containers (WordPress, NGINX, MariaDB) in a single dashboard.
