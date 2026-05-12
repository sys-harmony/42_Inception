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
  * `21` & `40000-40005` (FTP)
  * `8081` (Static Site)
  * `8080` (Adminer)
  * `3552` (Arcane)
* Local DNS: You must have the ability to modify the `/etc/hosts` file to map `yourlogin.42.fr` to the host's IP.

### Configuration Files and Secrets

Before building the project, you must manually set up the required configurations and secrets.

1. **Environment Variables:**
   Copy the provided `.env.example` file to create your own `.env` file inside the `srcs/` directory:

   ```sh
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
* `make` or `make all`: Automated sequence that prepares directories, builds Docker images, and starts containers in detached mode.
* `make build`: Builds the Docker images using `docker compose build`.
* `make up`: Starts the existing containers in the background.

### Maintenance
* `make restart`: Stops, rebuilds, and restarts the services using existing cache.
* `make rebuild`: Rebuilds the Docker images from scratch without using cache.
* `make re`: Full stack rebuild: stops services, rebuilds everything without cache, and restarts.

### Database Access
* `make mariadb`: Opens an interactive MariaDB shell as root inside the database container for manual queries and verification.

### Cleanup
* `make down`: Stops and removes the containers and the default network. Volumes are preserved.
* `make clean`: Executes `make down` and runs `docker system prune -f` to clean up dangling resources (stopped containers, dangling networks).
* `make fclean`: Deep clean. It removes all containers, networks, volumes, and images (`--rmi all`) and clears the entire Docker cache. It then interactively prompts you before forcefully deleting the host's local data directories (`sudo rm -rf /home/gdosch/data`), acting as a safeguard to prevent accidental system damage.

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
* `make fclean`: This is a destructive command. It explicitly removes the host data directories to allow a true "from scratch" installation (requires user confirmation). This is intended for development resets or project submission cleanup.

## Full Project Tutorial
This comprehensive guide details every step required to recreate the entire Inception infrastructure from scratch, from the initial virtual machine setup to the final container deployment.

> **Note on Naming Conventions:**  
> In this tutorial, I use `yourlogin` as a placeholder for your 42 username. Don't forget to replace every instance of it.

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
   ```sh
   su -
   ```
   Don’t forget the hyphen, it is important, and enter your root account password.

2. Install the `sudo` utility:
   ```sh
   apt update && apt install sudo
   ```
3. Add your user to the administrators group:
   ```sh
   usermod -aG sudo yourlogin
   ```

---

### 4. Network Configuration

Go to the **VirtualBox** main window. Select your VM -> **Settings** -> **Network** tab. 
Choose between **Bridged Adapter** and **NAT** and :

*   **Bridged mode:** Connects the VM directly to your local network. You can access `yourlogin.42.fr` without port forwarding, but you may require `/etc/hosts` and `ssh config` updates because the IP can change on reboot.

    Find the VM's IP:

    ```sh
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

```sh
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

Confirm the fingerprint (`yes`) and enter your user password. If your prompt changes to `yourlogin@inception:~$`, it means everything is working correctly.

#### Connect VSCode via SSH

Now we will use this connection to link Visual Studio Code.

1. Open VSCode on your physical computer.

2. Go to the Extensions tab (the small squares icon on the left) or press `Ctrl+Shift+X` (or `Cmd+Shift+X` on Mac).

3. Search for and install the official Remote - SSH extension (published by Microsoft).

Then, edit the local SSH configuration file:

4. Open **VSCode** locally and install the **"Remote - SSH"** extension.

5. Open the command palette (`Ctrl+Shift+P` / `Cmd+Shift+P`), type `SSH: Open SSH Configuration File`.

6. Select your user's config file (e.g., `~/.ssh/config`) and add the corresponding block:

    **For Bridged Mode:**

    ```ssh-config
    Host inception
        HostName <your_vm_ip_address>
        User <yourlogin>
    ```

     > ⚠️ **Warning for Bridged Mode Users:** If you change physical workstations or networks, your VM's IP address will likely change. If VSCode throws a "Connection timed out" error in the future, log into your VM directly, run `hostname -I` to get the new IP, and update the `HostName` value in this configuration file.

    **For NAT Mode:**

    ```ssh-config
    Host inception
        HostName localhost
        User <yourlogin>
        Port 2222
    ```

    We can now connect to the virtual machine via SSH from VSCode.

7. In VSCode, click the `><` icon (bottom-left) -> `Connect to Host...` -> `inception`.

8. A new VSCode window will open and you will then be prompted to enter your password (the one for the "yourlogin" user).

9. Once connected, go to the VSCode file explorer (on the left), click `Open Folder`, then select `/home/<yourlogin>` and confirm.

10. To avoid VSCode asking for your password too often, you can set up an SSH key. If you are not interested, skip to the "Local Domain DNS Routing" chapter. Otherwise, if you already have one, skip to the next step.

    > ⚠️ **Be careful:** generating a new SSH key can overwrite an existing one if you are not attentive to the file location, so make sure you know what you are doing before proceeding. If you don’t have an SSH key yet, you first need to create one. In your physical computer’s terminal (not the VM), run:

    ```sh
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
```sh
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
```sh
sudo apt update && sudo apt install ca-certificates curl
```

```sh
sudo install -m 0755 -d /etc/apt/keyrings
```

```sh
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
```

```sh
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

Add the repository to Apt sources:
```sh
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
```sh
sudo apt update && sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

The Docker service starts automatically after installation. To verify that Docker is running, use: `sudo systemctl status docker` and `docker compose version`.

To use Docker without `sudo`:
```sh
sudo usermod -aG docker yourlogin
```
*(You may need to log out and log back in for this to take effect.)*

https://docs.docker.com/engine/install/debian/#install-using-the-repository

---

### 8. Project Structure & Environment

We will now create the project directory structure.

> ⚠️ Be careful: the subject specifies a mandatory `srcs` directory, but it does not explicitly state that it must be located at the root of the project. In practice, we place `srcs` inside another directory (here, `inception`), because otherwise your home directory (`/home/yourlogin`) would have to be your Git repository, which is neither practical nor recommended.

Create the necessary folders:

```sh
mkdir -p \
    ~/inception/srcs/requirements/mariadb/tools \
    ~/inception/srcs/requirements/nginx/{conf,tools} \
    ~/inception/srcs/requirements/wordpress/tools \
    ~/inception/srcs/requirements/tools \
    ~/inception/secrets
```

It's time to secure the repository by ignoring the secrets and the `.env` file. Create the `.gitignore` file:
```sh
touch ~/inception/.gitignore
```

And copy the following in it:
```gitignore
# Ignore the secrets directory (passwords)
secrets/

# Ignore the environment file(s) (variables)
.env
```

> Evaluation Tip: Because your `.env` file and the `secrets/` directory are properly ignored by Git for security reasons, they will be missing when you clone your repository during your defense. It is highly recommended to keep a pre-configured .env file and a ready-to-use secrets/ folder on hand (e.g., on your Desktop) so you can simply drag and drop them into your project during the evaluation. Otherwise, you will need to recreate them manually from scratch (using the .env.example and the instructions in Section 8).

Now, create the `.env` file inside the `srcs` directory:
```sh
touch ~/inception/srcs/.env
```

Paste the following configuration, ensuring you replace `yourlogin` with **your actual 42 username**:
```sh
DOMAIN_NAME=yourlogin.42.fr

# MARIADB
MARIADB_HOST=mariadb
MARIADB_PORT=3306
MARIADB_DATABASE=wordpress
MARIADB_USER=yourlogin

# WORDPRESS
WP_VERSION=6.9.4
WP_TITLE=Inception
WP_PORT=9000
WP_ADMIN_USER=yourlogin
WP_ADMIN_EMAIL=yourlogin@student.42.fr
WP_USER=visitor
WP_USER_EMAIL=visitor@student.42.fr

# NGINX
NGINX_PORT=443
NGINX_HOST_PORT=443
```

While `.env` files are often used to store sensitive data, security best practices recommend keeping critical settings (i.e. passwords, keys and tokens) into dedicated secret files. Replace the values in quotes with passwords of your choice securely in `~/inception/secrets/`:

```sh
cd ~/inception/secrets
```

```sh
echo -n "your_db_password" > db_password.txt
```

```sh
echo -n "your_db_root_password" > db_root_password.txt
```

```sh
echo -n "your_wp_admin_password" > wp_admin_password.txt
```

```sh
echo -n "your_wp_user_password" > wp_user_password.txt
```

---

### 9. Docker-Compose & Makefile

Now that our environment variables and secrets are ready, it's time to create the `docker-compose.yml` file. This file acts as the architect of your infrastructure, defining how our services interact, which networks they use, and where they store their data:

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
      args:
        - MARIADB_PORT
    image: mariadb:inception-v1
    container_name: mariadb
    restart: unless-stopped
    healthcheck:
      # Verifies DB readiness:
      # - mariadb-admin ping: sends a connection check to the server
      # - -h 127.0.0.1: forces connection through the local network interface
      # - -P 3306: explicitly enforces the connection on the default MariaDB port
      # - -uroot: connects with root privileges for the health probe
      # - -p$$(cat ...): securely reads the root password from the Docker secret file
      # - --silent: prevents status messages from cluttering container logs
      test: ["CMD-SHELL", "mariadb-admin ping -h 127.0.0.1 -P ${MARIADB_PORT} -uroot -p$$(cat /run/secrets/db_root_password) --silent"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 15s
    environment:
      # Explicit mapping: only injects required variables instead of using 'env_file: .env'
      - MARIADB_HOST
      - MARIADB_PORT
      - MARIADB_DATABASE
      - MARIADB_USER
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
      args:
        - WP_PORT
    image: wordpress:inception-v1
    container_name: wordpress
    restart: unless-stopped
    depends_on:
      mariadb:
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
      - DOMAIN_NAME
      - MARIADB_HOST
      - MARIADB_PORT
      - MARIADB_DATABASE
      - MARIADB_USER
      - WP_VERSION
      - WP_TITLE
      - WP_PORT
      - WP_ADMIN_USER
      - WP_ADMIN_EMAIL
      - WP_USER
      - WP_USER_EMAIL
      - NGINX_HOST_PORT
    secrets:
      - db_password
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
      args:
        - NGINX_PORT
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
      # - https://localhost:443: explicitly targets the encrypted connection on NGINX default HTTPS port.
      # - || exit 1: triggers an 'unhealthy' status if the request fails or times out.
      test: ["CMD-SHELL", "wget --no-check-certificate --spider https://localhost:${NGINX_PORT}/readme.html || exit 1"]
      interval: 15s
      timeout: 5s
      retries: 5
    environment:
      # Explicit mapping: only injects required variables instead of using 'env_file: .env'
      - DOMAIN_NAME
      - WP_PORT
      - NGINX_PORT
    volumes:
      - wordpress_data:/var/www/html:ro
    networks:
      - inception
    ports:
      - "${NGINX_HOST_PORT}:${NGINX_PORT}" # Only HTTPS port is exposed to the host
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
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/yourlogin/data/mariadb
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/yourlogin/data/wordpress
```

https://docs.docker.com/compose/gettingstarted/

The project subject strictly requires the use of Docker named volumes for persistent storage and explicitly forbids traditional bind mounts. Our configuration fully complies with this rule by declaring formal named volumes within the docker-compose.yml file:

The forbidden classic `bind mount` would look like it:

```yaml
services:
  mariadb:
    volumes:
      - /home/yourlogin/data/mariadb:/var/lib/mysql
```

The classic `named volume` is the standard best practice but it does not meet the project's constraint, which forces you to store data specifically in `/home/yourlogin/data/`:

```yaml
services:
  mariadb:
    volumes:
      - mariadb_data:/var/lib/mysql

volumes:
  mariadb_data: {} # Docker manages the physical location behind the scenes
```

That's why we use a `mapped named volume`: we configure its driver with the bind option to force Docker to physically write the data to your personal folder:

```yaml
services:
  mariadb:
    volumes:
      - mariadb_data:/var/lib/mysql

volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/yourlogin/data/mariadb
```

Now, create the `Makefile`:

```sh
touch ~/inception/Makefile
```

And copy the following into it and make sure to use actual Tabs instead of spaces for indentation:

```makefile
DATA_PATH = /home/yourlogin/data
COMPOSE_FILE = srcs/docker-compose.yml

.PHONY: all prepare build rebuild up down restart re mariadb clean fclean

all: build up

# Create host directories for persistent data storage
prepare:
	@mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress

# Build Docker images
build: prepare
	docker compose -f $(COMPOSE_FILE) build

# Rebuild images from scratch
rebuild: prepare
	docker compose -f $(COMPOSE_FILE) build --no-cache

# Start the containers
up:
    # -d : Detached mode. Run containers in the background and return control to the terminal.
	docker compose -f $(COMPOSE_FILE) up -d

# Stop all services and remove containers
down:
	docker compose -f $(COMPOSE_FILE) down

# Restart service using existing cache
restart: down build up

# Full stack rebuild without cache
re: down rebuild up

# Access the database command line
mariadb:
    # -i : Interactive, keep STDIN open so you can type the password
    # -t : Allocate a pseudo-TTY (gives you a real terminal interface)
    # -u root : Connect as root user to MariaDB
    # -p : Prompt for the password
	docker exec -it mariadb mariadb -u root -p

# Standard cleanup: removes stopped containers and dangling resources (cache, networks)
clean: down
    # -f : Force. Do not prompt for confirmation
	@docker system prune -f

# Deep clean: total removal of the Docker environment
fclean: 
    # -v        : Remove named volumes declared in the volumes section of the Compose file
    # --rmi all : Remove all images built or downloaded by this compose file
	docker compose -f $(COMPOSE_FILE) down -v --rmi all

    # -a : All. Remove all unused images, not just dangling ones, and entire build cache
    # -f : Force. Do not prompt for confirmation
	@docker system prune -af

    # Interactive prompt for persistent data
    # Ensures DATA_PATH is set and is not the root directory to prevent system damage
    # Requires sudo password to securely delete persistent data from the host
	@echo "All Docker containers, networks, volumes, images and cache were deleted."
	@read -p "Would you like to wipe the persistent data too? [y/N] " ans && if [ "$$ans" = "y" ] || [ "$$ans" = "Y" ]; then \
		if [ -z "$(DATA_PATH)" ] || [ "$(DATA_PATH)" = "/" ]; then \
			echo "Error: DATA_PATH is empty or set to root. Aborting wipe."; \
			exit 1; \
		fi; \
		sudo -k; \
		sudo rm -rf $(DATA_PATH); \
		echo "Persistent data wiped successfully."; \
	else \
		echo "Persistent data preserved."; \
	fi
```

https://docs.docker.com/compose/intro/compose-application-model/

---

### 10. Dockerfiles, Entrypoint Scripts and other configuration files

The configuration files (`Dockerfile`, `entrypoint.sh`, `nginx.conf`, etc.) need to be written according to the tutorial provided previously. Follow the setup code to place each `Dockerfile` internally correctly:


**MariaDB Setup**

Create the `Dockerfile`:

```sh
touch ~/inception/srcs/requirements/mariadb/Dockerfile
```

And copy the following in it:

```dockerfile
# Use the stable Debian Bookworm as base image
FROM debian:12

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

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

# Expose the internal port (default 3306) dynamically injected at build time
# The actual listening port is dynamically injected at runtime via the docker-compose.yml file
ARG MARIADB_PORT=3306
EXPOSE ${MARIADB_PORT}

# Set the entrypoint script to handle setup and environment preparation at container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed as PID 1 via the entrypoint's 'exec "$@"'
CMD ["mariadbd"]
```

Then, create the `entrypoint.sh` script:

```sh
touch ~/inception/srcs/requirements/mariadb/tools/entrypoint.sh
```

And copy the following in it:

```sh
#!/bin/sh

# Stop the script immediately if any command fails
set -e

# Only run setup logic if the command passed is 'mariadbd'
if [ "$1" = 'mariadbd' ]; then

    # 1. Fail-fast validation
    # The port is required for BOTH installation and restarts
    if [ -z "$MARIADB_PORT" ]; then
        echo "Error: Missing MARIADB_PORT environment variable." >&2
        exit 1
    fi

    # 2. Persistence Check
    # Skips the entire installation setup if '.initialized' already exists on the volume
    if [ ! -f "/var/lib/mysql/.initialized" ]; then
        
        # 3. Fetch secrets from Docker secret mount points (RAM-only files)
        # This avoids passing sensitive passwords through environment variables
        MARIADB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
        MARIADB_PASSWORD=$(cat /run/secrets/db_password)

        # 4. Fail-fast validation
        # Ensures all necessary credentials are present before attempting installation
        if [ -z "$MARIADB_ROOT_PASSWORD" ] || [ -z "$MARIADB_DATABASE" ] || [ -z "$MARIADB_USER" ] || [ -z "$MARIADB_PASSWORD" ]; then
            echo "Error: Missing database environment variable(s) and/or secret(s)." >&2
            exit 1
        fi

        # 5. MariaDB Installation Logic
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

    # 6. Dynamic Configuration via Command Arguments
    # Injects parameters directly into the command line arguments using 'set --'.
    # We must specify --user=mysql to avoid the "run as root" error
    # --bind-address=0.0.0.0 allows connections from other containers
    set -- "$@" --user=mysql --bind-address=0.0.0.0 --port="$MARIADB_PORT"
fi

# 7. Execute the command from CMD
# 'exec' replaces the shell with the MariaDB process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
```

**WordPress Setup**

Create the `Dockerfile`:

```sh
touch ~/inception/srcs/requirements/wordpress/Dockerfile
```

And copy the following in it:

```dockerfile
# Use Debian Bookworm as the base image
FROM debian:12

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

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

# Expose the internal port (default 9000) dynamically injected at build time
# The actual listening port is dynamically injected at runtime via the entrypoint.sh script
ARG WP_PORT=9000
EXPOSE ${WP_PORT}

# Set the entrypoint script to handle setup and environment preparation at container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed as PID 1 via the entrypoint's 'exec "$@"'
# -F: Forces php-fpm to run in the foreground rather than becoming a daemon.
# This ensures the container stays active and that logs are sent to stdout/stderr.
CMD ["php-fpm8.2", "-F"]
```

Create the `entrypoint.sh` script:

```sh
touch ~/inception/srcs/requirements/wordpress/tools/entrypoint.sh
```

And copy the following in it:

```sh
#!/bin/sh

# Stop the script immediately if any command fails
set -e

# Only run setup logic if the command passed is 'php-fpm8.2'
if [ "$1" = 'php-fpm8.2' ]; then

    # 1. Global Fail-fast validation
    # These variables are strictly required for BOTH installation and restarts.
    # We check them before doing any file modifications or variable calculations.
    if [ -z "$WP_PORT" ] || [ -z "$DOMAIN_NAME" ] || [ -z "$NGINX_HOST_PORT" ] || [ -z "$MARIADB_HOST" ] || [ -z "$MARIADB_PORT" ]; then
        echo "Error: Missing WP_PORT, DOMAIN_NAME, NGINX_HOST_PORT, MARIADB_HOST and/or MARIADB_PORT environment variable(s)." >&2
        exit 1
    fi

    # 2. Update PHP-FPM listening port dynamically before starting
    # The regex '^listen = .*' ensures it works even if the container restarts
    sed -i "s/^listen = .*/listen = ${WP_PORT}/" /etc/php/8.2/fpm/pool.d/www.conf

    # 3. Dynamic Site URL Calculation
    # Computes the absolute WordPress URL, appending the external NGINX port
    # if it differs from the standard 443. This prevents redirection loops.
    if [ "$NGINX_HOST_PORT" = "443" ]; then
        SITE_URL="https://$DOMAIN_NAME"
    else
        SITE_URL="https://$DOMAIN_NAME:$NGINX_HOST_PORT"
    fi

    # 4. Persistence Check
    # Skips the entire installation setup if 'wp-config.php' already exists on the volume
    if [ ! -f "/var/www/html/wp-config.php" ]; then

        # 5. Fetch secrets from Docker secret mount points
        # Retrieves sensitive credentials from Docker secret files
        MARIADB_PASSWORD=$(cat /run/secrets/db_password)
        WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
        WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

        # 6. Fail-fast validation
        # Ensures all necessary credentials are present before attempting installation

        # Database checks
        if [ -z "$MARIADB_DATABASE" ] || [ -z "$MARIADB_USER" ] || [ -z "$MARIADB_PASSWORD" ]; then
            echo "Error: Missing database environment variable(s) and/or secret." >&2
            exit 1
        fi

        # Admin checks
        if [ -z "$WP_ADMIN_USER" ] || [ -z "$WP_ADMIN_PASSWORD" ] || [ -z "$WP_ADMIN_EMAIL" ]; then
            echo "Error: Missing admin environment variable(s) and/or secret." >&2
            exit 1
        fi

        # Secondary User checks
        if [ -z "$WP_USER" ] || [ -z "$WP_USER_PASSWORD" ] || [ -z "$WP_USER_EMAIL" ]; then
            echo "Error: Missing secondary user environment variable(s) and/or secret." >&2
            exit 1
        fi

        # Other checks
        if [ -z "$WP_TITLE" ] || [ -z "$WP_VERSION" ]; then
            echo "Error: Missing WP_TITLE and/or WP_VERSION environment variable(s)." >&2
            exit 1
        fi

        # 7. Service Dependencies
        # Ensures MariaDB is ready before running WP-CLI commands
        echo "Waiting for MariaDB to be ready..."
        until mariadb -h"$MARIADB_HOST" -P "$MARIADB_PORT" -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
            sleep 2
        done

        # 8. WordPress Configuration Logic
        echo "WordPress not found. Starting installation..."

        # Downloads the specific version of WordPress core files
        echo "Downloading WordPress version $WP_VERSION..."
        wp core download --version="$WP_VERSION" --allow-root

        # Generates wp-config.php with provided database credentials
        wp config create \
            --dbname="$MARIADB_DATABASE" \
            --dbuser="$MARIADB_USER" \
            --dbpass="$MARIADB_PASSWORD" \
            --dbhost="$MARIADB_HOST:$MARIADB_PORT" \
            --allow-root

        # Configures the database and creates the primary administrator account
        wp core install \
            --url="$SITE_URL" \
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

        # We hardcode the URLs in wp-config.php to override database settings
        wp config set WP_HOME "$SITE_URL" --allow-root
        wp config set WP_SITEURL "$SITE_URL" --allow-root

        # Finalizes file permissions for the web server (www-data)
        chown -R www-data:www-data /var/www/html
        chmod -R 775 /var/www/html
        echo "WordPress installed successfully."

    else
    
        # 9. Dynamic Update on Restart
        # If wp-config.php exists (persisted volume), we refresh the configuration.
        echo "WordPress is already installed. Preparing updates..."

        # Update the filesystem configuration (wp-config.php)
        wp config set DB_HOST "$MARIADB_HOST:$MARIADB_PORT" --allow-root
        wp config set WP_HOME "$SITE_URL" --allow-root
        wp config set WP_SITEURL "$SITE_URL" --allow-root

        # Update the persistent database options (MariaDB)
        wp option update home "$SITE_URL" --allow-root
        wp option update siteurl "$SITE_URL" --allow-root
        
        echo "Dynamic configuration updated successfully."
    fi
fi

# 10. Execute the command from CMD
# 'exec' replaces the shell with the PHP-FPM process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
```

**NGINX Setup**

Create the `Dockerfile`:

```sh
touch ~/inception/srcs/requirements/nginx/Dockerfile
```

And copy the following in it:

```dockerfile
# Use Debian Bookworm as the base image
FROM debian:12

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# Install NGINX, OpenSSL (certificates), and wget (Docker healthcheck)
RUN apt-get update && apt-get install -y \
	nginx openssl wget && \
	rm -rf /var/lib/apt/lists/*

# Copy the NGINX configuration file into the container
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Copy the entrypoint script and make it executable
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the internal port (default 443) dynamically injected at build time
# The actual listening port is dynamically injected at runtime via the entrypoint.sh script
ARG NGINX_PORT=443
EXPOSE ${NGINX_PORT}

# Set the entrypoint script to handle setup and environment preparation at container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed as PID 1 via the entrypoint's 'exec "$@"'
# -g "daemon off;": Runs NGINX in the foreground so the container doesn't exit
CMD ["nginx", "-g", "daemon off;"]
```

Create the `entrypoint.sh` script:

```sh
touch ~/inception/srcs/requirements/nginx/tools/entrypoint.sh
```

And copy the following in it:

```sh
#!/bin/sh

# Stop the script immediately if any command fails
set -e

# Only run setup logic if the command passed is 'nginx'
if [ "$1" = "nginx" ]; then

    # 1. Fail-fast validation
    # Ensures all mandatory environment variables are set before proceeding
    if [ -z "$DOMAIN_NAME" ] || [ -z "$NGINX_PORT" ] || [ -z "$WP_PORT" ]; then
        echo "Error: Missing DOMAIN_NAME, NGINX_PORT and/or WP_PORT environment variable(s)." >&2
        exit 1
    fi

    # 2. Dynamic Configuration Injection
    # Replaces the placeholders in the template with the actual domain name and ports at runtime
    echo "[INFO] Configuring NGINX for domain: $DOMAIN_NAME"
    sed -i "s/__DOMAIN_NAME__/$DOMAIN_NAME/g" /etc/nginx/nginx.conf
    sed -i "s/__NGINX_PORT__/$NGINX_PORT/g" /etc/nginx/nginx.conf
    sed -i "s/__WP_PORT__/$WP_PORT/g" /etc/nginx/nginx.conf

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
fi

# 4. Execute the command from CMD
# 'exec' replaces the shell with the NGINX process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
```

NGINX also needs a `nginx.conf` file:

```sh
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
        listen __NGINX_PORT__ ssl;
        listen [::]:__NGINX_PORT__ ssl;

        # The server name (domain) will be dynamically replaced by the entrypoint script
        server_name __DOMAIN_NAME__;

        # Disable absolute redirects (e.g. /wp-admin to /wp-admin/) to preserve HOST_PORT 
        absolute_redirect off;

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
            fastcgi_pass wordpress:__WP_PORT__;

            # Default file to process if none is specified
            fastcgi_index index.php;

            # Include standard FastCGI parameters
            include fastcgi_params;
            
            # Pass the original Host header and port to PHP to ensure correct URL generation
            fastcgi_param HTTP_HOST $http_host;

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

```sh
sudo apt update && sudo apt install -y make
cd ~/inception
make
```

Your system is now alive! You can access it via your browser (Accept the self-signed certificate warning in your browser):

* If you chose **Bridged mode:** https://yourlogin.42.fr
* If you chose **NAT mode:** https://yourlogin.42.fr:8443
  
---

## BONUS Deployments

### Bonus 1: REDIS
Redis is an excellent performance upgrade for your WordPress site. We will now create a secret for it. Type the following and replace `your_redis_password` with a password of your choice:
```sh
echo -n "your_redis_password" > ~/inception/secrets/redis_password.txt 
```

Add the REDIS_PORT variable to your .env file:
```env
# REDIS
REDIS_PORT=6379
```

Let's create the structure:
```sh
mkdir -p ~/inception/srcs/requirements/bonus/redis/tools
```

We will now create the Redis `Dockerfile`:
```sh
touch ~/inception/srcs/requirements/bonus/redis/Dockerfile
```

Copy and paste the following configuration in it:
```dockerfile
# Use Debian Bookworm as the base image
FROM debian:12

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# Install redis-server
RUN apt-get update && apt-get install -y \
	redis-server \
	&& rm -rf /var/lib/apt/lists/*

# Copy and prepare the entrypoint script
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the internal port (default 6379) dynamically injected at build time
ARG REDIS_PORT=6379
EXPOSE ${REDIS_PORT}

# Set the entrypoint script to handle setup and environment preparation at container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed as PID 1 via the entrypoint's 'exec "$@"'
CMD ["redis-server"]
```

Now it's time to create the `entrypoint.sh` file for Redis:

```sh
touch ~/inception/srcs/requirements/bonus/redis/tools/entrypoint.sh
```

Copy and paste the following configuration in it:
```sh
#!/bin/sh

# Stop the script immediately if any command fails
set -e

if [ "$1" = "redis-server" ]; then

    # 1. Fetch the secret from Docker secret mount point
    # Retrieves the password from the Docker secret file
    REDIS_PASSWORD=$(cat /run/secrets/redis_password)

    # 2. Fail-fast validation
    if [ -z "$REDIS_PORT" ] || [ -z "$REDIS_PASSWORD" ]; then
        echo "Error: Missing REDIS_PORT environment variable and/or REDIS_PASSWORD secret." >&2
        exit 1
    fi

    echo "Starting Redis server on port $REDIS_PORT..."

    # 3. Dynamic Configuration via Command Arguments
    # Instead of modifying a config file, we inject parameters directly 
    # into the command line arguments using 'set --'.
    # --bind 0.0.0.0: Allows connections from other containers (WordPress)
    # --protected-mode no: Required for remote connections when bind is used
    set -- "$@" --port "$REDIS_PORT" --bind 0.0.0.0 --requirepass "$REDIS_PASSWORD" --protected-mode no
fi

# 4. Execute the command from CMD
# 'exec' replaces the shell with the target process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
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
    environment:
      # ... other variables
      - REDIS_PORT
    secrets:
      # ... other secrets
      - redis_password
    # ... other configs

  # ... other services

  redis:
    build:
      context: ./requirements/bonus/redis
      args:
        - REDIS_PORT
    image: redis:inception-v1
    container_name: redis
    restart: unless-stopped
    healthcheck:
      # Verifies Redis availability by performing a handshake:
      # - redis-cli ping: sends the standard PING command to the server.
      # - -h 127.0.0.1: targets the local instance within the container.
      # - -p 6379: explicitly enforces the connection on the default Redis port.
      # - -a "$$(cat ...)": securely authenticates using the password from the Docker secret.
      # - grep PONG: confirms the server specifically responded with the expected 'PONG'.
      # - || exit 1: ensures the container is marked 'unhealthy' if the handshake fails.
      test: ["CMD-SHELL", "redis-cli -h 127.0.0.1 -p ${REDIS_PORT} -a \"$$(cat /run/secrets/redis_password)\" ping | grep PONG || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 5s
    environment:
      - REDIS_PORT
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

The WordPress `entrypoint.sh` file also needs updating. Replace it with the following:

```sh
#!/bin/sh

# Stop the script immediately if any command fails
set -e

# Only run setup logic if the command passed is 'php-fpm8.2'
if [ "$1" = 'php-fpm8.2' ]; then

    # 1. Fetch the Redis Password (Bonus) from Docker secret mount points
    REDIS_PASSWORD=$(cat /run/secrets/redis_password)

    # 2. Fail-fast validation
    # These variables are strictly required for BOTH installation and restarts.
    # We check them before doing any file modifications or variable calculations.
    if [ -z "$WP_PORT" ] || [ -z "$DOMAIN_NAME" ] || [ -z "$NGINX_HOST_PORT" ] || [ -z "$MARIADB_HOST" ] || [ -z "$MARIADB_PORT" ]; then
        echo "Error: Missing WP_PORT, DOMAIN_NAME, NGINX_HOST_PORT, MARIADB_HOST and/or MARIADB_PORT environment variable(s)." >&2
        exit 1
    fi

    if [ -z "$REDIS_PORT" ] || [ -z "$REDIS_PASSWORD" ]; then
        echo "Error: Missing REDIS_PORT environment variable and/or REDIS_PASSWORD secret." >&2
        exit 1
    fi

    # 3. Update PHP-FPM listening port dynamically before starting
    # The regex '^listen = .*' ensures it works even if the container restarts
    sed -i "s/^listen = .*/listen = ${WP_PORT}/" /etc/php/8.2/fpm/pool.d/www.conf

    # 4. Dynamic Site URL Calculation
    # Computes the absolute WordPress URL, appending the external NGINX port
    # if it differs from the standard 443. This prevents redirection loops.
    if [ "$NGINX_HOST_PORT" = "443" ]; then
        SITE_URL="https://$DOMAIN_NAME"
    else
        SITE_URL="https://$DOMAIN_NAME:$NGINX_HOST_PORT"
    fi

    # 5. Persistence Check
    # Skips the entire installation setup if 'wp-config.php' already exists on the volume
    if [ ! -f "/var/www/html/wp-config.php" ]; then

        # 6. Fetch secrets from Docker secret mount points
        # Retrieves sensitive credentials from Docker secret files
        MARIADB_PASSWORD=$(cat /run/secrets/db_password)
        WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
        WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

        # 7. Fail-fast validation
        # Ensures all necessary credentials are present before attempting installation

        # Database checks
        if [ -z "$MARIADB_DATABASE" ] || [ -z "$MARIADB_USER" ] || [ -z "$MARIADB_PASSWORD" ]; then
            echo "Error: Missing database environment variable(s) and/or secret." >&2
            exit 1
        fi

        # Admin checks
        if [ -z "$WP_ADMIN_USER" ] || [ -z "$WP_ADMIN_PASSWORD" ] || [ -z "$WP_ADMIN_EMAIL" ]; then
            echo "Error: Missing admin environment variable(s) and/or secret." >&2
            exit 1
        fi

        # Secondary User checks
        if [ -z "$WP_USER" ] || [ -z "$WP_USER_PASSWORD" ] || [ -z "$WP_USER_EMAIL" ]; then
            echo "Error: Missing secondary user environment variable(s) and/or secret." >&2
            exit 1
        fi

        # Other checks
        if [ -z "$WP_TITLE" ] || [ -z "$WP_VERSION" ]; then
            echo "Error: Missing WP_TITLE and/or WP_VERSION environment variable(s)." >&2
            exit 1
        fi

        # 8. Service Dependencies
        # Ensures MariaDB is ready before running WP-CLI commands
        echo "Waiting for MariaDB to be ready..."
        until mariadb -h"$MARIADB_HOST" -P "$MARIADB_PORT" -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
            sleep 2
        done

        # 9. WordPress Configuration Logic
        echo "WordPress not found. Starting installation..."

        # Downloads the specific version of WordPress core files
        echo "Downloading WordPress version $WP_VERSION..."
        wp core download --version="$WP_VERSION" --allow-root

        # Generates wp-config.php with provided database credentials
        wp config create \
            --dbname="$MARIADB_DATABASE" \
            --dbuser="$MARIADB_USER" \
            --dbpass="$MARIADB_PASSWORD" \
            --dbhost="$MARIADB_HOST:$MARIADB_PORT" \
            --allow-root

        # Configures the database and creates the primary administrator account
        wp core install \
            --url="$SITE_URL" \
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

        # We hardcode the URLs in wp-config.php to override database settings
        wp config set WP_HOME "$SITE_URL" --allow-root
        wp config set WP_SITEURL "$SITE_URL" --allow-root

        # 10. Redis Setup (Bonus)
        echo "Configuring Redis Cache with authentication..."
        wp plugin install redis-cache --activate --allow-root

        # Injects Redis connection constants into wp-config.php
        wp config set WP_REDIS_HOST redis --allow-root
        wp config set WP_REDIS_PORT "$REDIS_PORT" --raw --allow-root
        wp config set WP_REDIS_PASSWORD "$REDIS_PASSWORD" --allow-root

        # Enables the object cache to start using Redis
        wp redis enable --allow-root

        # Finalizes file permissions for the web server (www-data)
        chown -R www-data:www-data /var/www/html
        chmod -R 775 /var/www/html
        echo "WordPress installed successfully."

    else
    
        # 11. Dynamic Update on Restart
        # If wp-config.php exists (persisted volume), we refresh the configuration.
        echo "WordPress is already installed. Preparing updates..."

        # Temporarily disable object cache to avoid WP-CLI bootstrap failures
        OBJECT_CACHE="/var/www/html/wp-content/object-cache.php"
        if [ -f "$OBJECT_CACHE" ]; then
            mv "$OBJECT_CACHE" "${OBJECT_CACHE}.disabled"
        fi

        # Update the filesystem configuration (wp-config.php)
        wp config set DB_HOST "$MARIADB_HOST:$MARIADB_PORT" --allow-root
        wp config set WP_HOME "$SITE_URL" --allow-root
        wp config set WP_SITEURL "$SITE_URL" --allow-root

        # Update the persistent database options (MariaDB)
        wp option update home "$SITE_URL" --allow-root
        wp option update siteurl "$SITE_URL" --allow-root

        # Update Redis connection constants (wp-config.php)
        echo "Updating Redis configuration..."
        wp config set WP_REDIS_HOST redis --allow-root
        wp config set WP_REDIS_PORT "$REDIS_PORT" --raw --allow-root
        wp config set WP_REDIS_PASSWORD "$REDIS_PASSWORD" --allow-root
        
        # Re-enable object cache
        rm -f "${OBJECT_CACHE}.disabled"
        wp redis enable --allow-root
        
        echo "Dynamic configuration updated successfully."
    fi
fi

# 12. Execute the command from CMD
# 'exec' replaces the shell with the PHP-FPM process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
```

Rebuild your infrastructure using `make re` to apply the changes. Verify that everything is working as expected by opening your browser and go to:

https://yourlogin.42.fr/wp-admin

Log in using your credentials, then navigate to Settings → Redis. If you can read “Status: Connected” displayed in green, everything works fine.

Source: https://redis.io/documentation

---

### Bonus 2: FTP

FTP (File Transfer Protocol) is a classic bonus with real practical value. It allows you to upload and retrieve files (images, themes, plugins, etc.) directly into your WordPress directory from your physical machine, using a client such as FileZilla. We're going to use **vsftpd** (Very Secure FTP Daemon).

let's start by creating a secret for it:
```sh
echo -n "your_ftp_password" > ~/inception/secrets/ftp_password.txt
```

Add the FTP configuration variables to your .env file:
```env
# FTP
FTP_PORT=21
FTP_HOST_PORT=21
FTP_PASV_MIN_PORT=40000
FTP_PASV_MAX_PORT=40005
FTP_USER=yourlogin
```

Let's create the structure:
```sh
mkdir -p ~/inception/srcs/requirements/bonus/ftp/{conf,tools}
```

We will now create the FTP `Dockerfile`:
```sh
touch ~/inception/srcs/requirements/bonus/ftp/Dockerfile
```

Copy and paste the following configuration:
```dockerfile
# Use Debian Bookworm as the base image
FROM debian:12

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# Install vsftpd (Very Secure FTP Daemon)
RUN apt-get update && apt-get install -y \
	vsftpd \
	&& rm -rf /var/lib/apt/lists/*

# Copy the server configuration file
COPY conf/vsftpd.conf /etc/vsftpd.conf

# Copy and prepare the entrypoint script
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the internal ports (default 21, 40000-40005) dynamically injected at build time
ARG FTP_PORT=21
ARG FTP_PASV_MIN_PORT=40000
ARG FTP_PASV_MAX_PORT=40005
EXPOSE ${FTP_PORT} ${FTP_PASV_MIN_PORT}-${FTP_PASV_MAX_PORT}

# Set the entrypoint script to handle setup and environment preparation at container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed as PID 1 via the entrypoint's 'exec "$@"'
CMD ["vsftpd", "/etc/vsftpd.conf"]
```

Next, let's create the `vsftpd` configuration file:
```sh
touch ~/inception/srcs/requirements/bonus/ftp/conf/vsftpd.conf
```

Copy and paste the following configuration:
```ini
# Run in the foreground (required for Docker containers)
listen=YES
listen_ipv6=NO
listen_port=21

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
```

**vsftpd** requires a system user to operate. We create it dynamically at runtime with an `entrypoint.sh` file:

```sh
touch ~/inception/srcs/requirements/bonus/ftp/tools/entrypoint.sh
```

Copy and paste the following configuration:
```sh
#!/bin/sh

# Stop the script immediately if any command fails
set -e

# Only run setup logic if the command passed is 'vsftpd'
if [ "$1" = "vsftpd" ]; then

    # 1. Fetch secrets from Docker secret mount points (RAM-only files)
    FTP_PASSWORD=$(cat /run/secrets/ftp_password)

    # 2. Fail-fast validation
    # Check for credentials
    if [ -z "$FTP_USER" ] || [ -z "$FTP_PASSWORD" ]; then
        echo "Error: Missing FTP_USER environment variable and/or FTP_PASSWORD secret." >&2
        exit 1
    fi

    # Check for network variables
    if [ -z "$FTP_PORT" ] || [ -z "$FTP_PASV_MIN_PORT" ] || [ -z "$FTP_PASV_MAX_PORT" ]; then
        echo "Error: Missing FTP port environment variable(s)." >&2
        exit 1
    fi

    # 3. User Creation and Permissions
    if ! id "$FTP_USER" >/dev/null 2>&1; then
        useradd -m -d /var/www/html -s /bin/bash -G www-data "$FTP_USER"
        echo "$FTP_USER:$FTP_PASSWORD" | chpasswd
    else
        usermod -d /var/www/html -G www-data "$FTP_USER"
    fi

    echo "Setting permissions for /var/www/html..."
    chown -R www-data:www-data /var/www/html
    chmod -R 775 /var/www/html

    # 4. Prepare the runtime environment
    mkdir -p /var/run/vsftpd/empty

    # 5. Dynamic Port Configuration
    # Injects the ports defined in the .env file into the vsftpd configuration
    echo "Configuring dynamic ports for vsftpd..."
    sed -i "s/^listen_port=.*/listen_port=${FTP_PORT}/" /etc/vsftpd.conf
    sed -i "s/^pasv_min_port=.*/pasv_min_port=${FTP_PASV_MIN_PORT}/" /etc/vsftpd.conf
    sed -i "s/^pasv_max_port=.*/pasv_max_port=${FTP_PASV_MAX_PORT}/" /etc/vsftpd.conf

    echo "Starting FTP server for user: $FTP_USER"
fi

# 6. Execute the command from CMD
exec "$@"
```

Passive mode is essential here, as Docker uses NAT networking. Without it, the FTP client would not be able to list or transfer files correctly.

It is now time to update the `docker-compose.yml` file:

```yaml
# 1. Add the 'ftp' service
services:
  # ... other services
  ftp:
    build:
      context: ./requirements/bonus/ftp
      args:
        - FTP_PORT
        - FTP_PASV_MIN_PORT
        - FTP_PASV_MAX_PORT
    image: ftp:inception-v1
    container_name: ftp
    restart: unless-stopped
    depends_on:
      wordpress:
        condition: service_healthy
    environment:
      # Explicit mapping: only injects required variables instead of using 'env_file: .env'
      - FTP_USER
      - FTP_PORT
      - FTP_PASV_MIN_PORT
      - FTP_PASV_MAX_PORT
    secrets:
      - ftp_password
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - inception
    ports:
      - "${FTP_HOST_PORT}:${FTP_PORT}"
      - "${FTP_PASV_MIN_PORT}-${FTP_PASV_MAX_PORT}:${FTP_PASV_MIN_PORT}-${FTP_PASV_MAX_PORT}" # Passive mode port range
    logging: *default-logging

# 2. Add this to the main 'secrets' section at the bottom
secrets:
  # ... other secrets
  ftp_password:
    file: ../secrets/ftp_password.txt
```

It's time to rebuild your infrastructure using `make re` to apply the changes, and test the FTP service.

* **If you chose Bridged mode:**
    You can test it with the following command:

    ```sh
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

  ```sh
  curl -u yourlogin:yourpassword ftp://127.0.0.1:2121/
  ```

Alternatively, you can test the connection interactively using the `ftp` client with the following commands:
  ```sh
  sudo apt update && sudo apt install -y ftp
  ```

* **If you chose Bridged mode:**

    ```sh
    ftp your_vm_ip_address 21
    ```

* **If you chose NAT mode:**

    ```sh
    ftp 127.0.0.1 2121
  ```

If the connection is successful, you should see a listing of the files in your WordPress directory.

Source: https://security.appspot.com/vsftpd.html

---

### Bonus 3: STATIC WEBSITE

This bonus consists of a simple static page served by a dedicated webserver container. For this service, we have decided to use **lighttpd**, a secure, fast, and very lightweight alternative to NGINX.

Add these configuration variables to your .env file:
```env
# STATIC WEBSITE & LIGHTTPD
STATIC_PORT=80
STATIC_HOST_PORT=8081
```

Create the project structure:

```sh
mkdir -p ~/inception/srcs/requirements/bonus/static/{conf,tools,www}
```

Let's create the `Dockerfile` for the static website:

```sh
touch ~/inception/srcs/requirements/bonus/static/Dockerfile
```

Copy and paste the following code in it:
```dockerfile
# Use Debian Bookworm as the base image
FROM debian:12

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

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

# Copy the initialization script to the container
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the internal port (default 80) dynamically injected at build time
ARG STATIC_PORT=80
EXPOSE ${STATIC_PORT}

# Set the entrypoint script to handle setup and environment preparation at container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed as PID 1 via the entrypoint's 'exec "$@"'
# -D: don't go to background (foreground mode, essential for Docker)
# -f: path to the configuration file
CMD ["lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]
```

The static website also needs an `entrypoint.sh` script:

```sh
touch ~/inception/srcs/requirements/bonus/static/tools/entrypoint.sh
```

Copy and paste the following code in it:

```sh
#!/bin/sh

# Stop the script immediately if any command fails
set -e

# Only run setup logic if the command passed is 'lighttpd'
if [ "$1" = "lighttpd" ]; then

    # 1. Fail-fast validation
    # Ensures the mandatory STATIC_PORT is set before proceeding
    if [ -z "$STATIC_PORT" ]; then
        echo "Error: Missing STATIC_PORT environment variable." >&2
        exit 1
    fi

    # 2. Dynamic Port Configuration
    # Updates the Lighttpd server.port value to match the .env configuration.
    # The regex ensures accuracy even if the container restarts multiple times.
    echo "Configuring Lighttpd to listen on port: $STATIC_PORT"
    sed -i "s/^server.port.*/server.port = ${STATIC_PORT}/" /etc/lighttpd/lighttpd.conf
fi

# 3. Execute the command from CMD
# 'exec' replaces the shell with the Lighttpd process so it becomes PID 1.
exec "$@"
```

Now, let's create a simple HTML file:
```sh
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
```sh
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
      args:
        - STATIC_PORT
    image: static:inception-v1
    container_name: static
    restart: unless-stopped
    environment:
      - STATIC_PORT
    networks:
      - inception
    ports:
      - "${STATIC_HOST_PORT}:${STATIC_PORT}"
    logging: *default-logging
```

Do not forget the VirtualBox rule if you chose the NAT mode:

| Rule Name    | Protocol | Host IP   | Host Port | Guest IP | Guest Port |
|--------------|----------|-----------|-----------|----------|------------|
| **Static**      | TCP      | 127.0.0.1 | 8081      |          | 8081         |

Rebuild your infrastructure using `make re` to apply the changes. To test the static website, open the following URL and make sure to use HTTP (not HTTPS):

http://yourlogin.42.fr:8081

Source: https://redmine.lighttpd.net/projects/lighttpd/wiki/Docs

---

### Bonus 4: ADMINER

Adminer is a lightweight database management tool written in a single PHP file. It is a great alternative to phpMyAdmin.

Add these configuration variables to your .env file:
```env
# ADMINER
ADMINER_VERSION=5.4.2
ADMINER_PORT=8080
ADMINER_HOST_PORT=8080
```

Create the structure:

```sh
mkdir -p ~/inception/srcs/requirements/bonus/adminer/tools
```

We will now create the `Dockerfile`. Adminer doesn't even need local files or entrypoint scripts, we can download it directly when building the image.

```sh
touch ~/inception/srcs/requirements/bonus/adminer/Dockerfile
```

Copy and paste the following code in it:

```dockerfile
# Use Debian Bookworm as the base image for consistency
FROM debian:12

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# Install PHP, the PHP-MySQL extension and wget (to download Adminer)
RUN apt-get update && apt-get install -y \
	php8.2 php8.2-mysql \
	wget && \
	rm -rf /var/lib/apt/lists/*

# Create the web directory
RUN mkdir -p /var/www/html

# Download the specific version of Adminer directly into the web directory
# We rename it to index.php so the server loads it by default
ARG ADMINER_VERSION=5.4.2
RUN wget https://github.com/vrana/adminer/releases/download/v${ADMINER_VERSION}/adminer-${ADMINER_VERSION}.php -O /var/www/html/index.php

# Ensure proper permissions
RUN chown -R www-data:www-data /var/www/html

# Set the working directory
WORKDIR /var/www/html

# Copy the entrypoint script into the container
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the internal port (default 8080) dynamically injected at build time
ARG ADMINER_PORT=8080
EXPOSE ${ADMINER_PORT}

# Set the entrypoint script to handle setup and environment preparation at container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed as PID 1 via the entrypoint's 'exec "$@"'
CMD ["php"]
```

Now it's time to create the `entrypoint.sh` file for Adminer:

```sh
touch ~/inception/srcs/requirements/bonus/adminer/tools/entrypoint.sh
```

Copy and paste the following configuration in it:
```sh
#!/bin/sh

# Stop the script immediately if any command fails
set -e

# 1. Dynamic Configuration via Command Arguments
# If the command is 'php', we inject the built-in server parameters.
if [ "$1" = "php" ]; then

    # 2. Fail-fast validation
    # Ensures the mandatory ADMINER_PORT is set before proceeding
    if [ -z "$ADMINER_PORT" ]; then
        echo "Error: Missing ADMINER_PORT environment variable." >&2
        exit 1
    fi

    # 3. Arguments Injection
    # -S 0.0.0.0:${ADMINER_PORT}: Starts the PHP built-in web server on the dynamic port.
    # -t /var/www/html: Sets the document root where Adminer (index.php) is located.
    echo "Starting Adminer on port: $ADMINER_PORT"
    set -- "$@" "-S" "0.0.0.0:${ADMINER_PORT}" "-t" "/var/www/html"
fi

# 4. Execute the command from CMD
# 'exec' replaces the shell with the PHP process so it becomes PID 1.
exec "$@"
```

We must update the `docker-compose.yml` file and add the Adminer service. We map it to port 8080. It needs to be on the inception network to communicate with the MariaDB container. Type:
```yaml
# Add the 'adminer' service
services:
  # ... other services
  adminer:
    build:
      context: ./requirements/bonus/adminer
      args:
        - ADMINER_VERSION
        - ADMINER_PORT
    image: adminer:inception-v1
    container_name: adminer
    restart: unless-stopped
    depends_on:
      mariadb:
        condition: service_healthy
    environment:
      - ADMINER_PORT
    networks:
      - inception
    ports:
      - "${ADMINER_HOST_PORT}:${ADMINER_PORT}"
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

Arcane is a modern, lightweight, and high-performance Docker management interface built with Go and SvelteKit. It allows you to monitor your Inception infrastructure, view logs in real-time, and manage containers through a sleek web interface.

First, we need to generate two new secrets using OpenSSL. We use long random strings because they are cryptographically secure and, unlike passwords, you will never need to type them manually:
```sh
openssl rand -hex 32 > ~/inception/secrets/arc_encryption_key.txt
```

```sh
openssl rand -hex 32 > ~/inception/secrets/arc_jwt_secret.txt
```

Add these configuration variables to your .env file:
```env
# ARCANE
ARCANE_VERSION=1.18.1
ARCANE_PORT=3552
ARCANE_HOST_PORT=3552
```

Now, create the necessary directories for this service:
```sh
mkdir -p ~/inception/srcs/requirements/bonus/arcane/tools
```

Update the following line of your `Makefile` to include the Arcane data directory:
```makefile
@mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress $(DATA_PATH)/arcane
```

It's time to create the Arcane `Dockerfile`:

```sh
touch ~/inception/srcs/requirements/bonus/arcane/Dockerfile
```

Copy and paste the following code in it:

```dockerfile
# Use Debian Bookworm as the base image
FROM debian:12

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# Update system and install required base utilities
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set working directory for the application
WORKDIR /app

# Download the pre-compiled Linux AMD64 binary for the specific version
ARG ARCANE_VERSION=1.18.1
RUN curl -fsSL https://github.com/getarcaneapp/arcane/releases/download/v${ARCANE_VERSION}/arcane_linux_amd64 -o arcane \
    && chmod +x arcane

# Copy the entrypoint script into the container and make it executable
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the internal port (default 3552) dynamically injected at build time
ARG ARCANE_PORT=3552
EXPOSE ${ARCANE_PORT}

# Set the entrypoint script to handle setup and environment preparation at container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed as PID 1 via the entrypoint's 'exec "$@"'
CMD ["./arcane"]
```

Arcane also needs an `entrypoint.sh` script:

```sh
touch ~/inception/srcs/requirements/bonus/arcane/tools/entrypoint.sh
```

Copy and paste the following code in it:

```sh
#!/bin/sh

# Stops the script immediately if any command fails
set -e

# Only run setup logic if the command passed is './arcane'
if [ "$1" = "./arcane" ]; then

    # 1. Fetch secrets from Docker secret mount points
    ARC_ENCRYPTION_KEY=$(cat /run/secrets/arc_encryption_key)
    ARC_JWT_SECRET=$(cat /run/secrets/arc_jwt_secret)

    # 2. Fail-fast validation
    # Check for secrets and mandatory environment variables
    if [ -z "$ARCANE_PORT" ] || [ -z "$ARC_ENCRYPTION_KEY" ] || [ -z "$ARC_JWT_SECRET" ]; then
        echo "Error: Missing ARCANE_PORT environment variable, ARC_ENCRYPTION_KEY and/or ARC_JWT_SECRET secret(s)." >&2
        exit 1
    fi

    # 3. Export secrets to environment for the application
    export PORT="$ARCANE_PORT"
    export ENCRYPTION_KEY="$ARC_ENCRYPTION_KEY"
    export JWT_SECRET="$ARC_JWT_SECRET"
fi

# 4. Execute the command from CMD
# 'exec' replaces the shell with the Arcane process so it becomes PID 1.
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
      args:
        - ARCANE_VERSION
        - ARCANE_PORT
    image: arcane:inception-v1
    container_name: arcane
    restart: unless-stopped
    environment:
      - ARCANE_PORT
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
      - "${ARCANE_HOST_PORT}:${ARCANE_PORT}"
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
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/yourlogin/data/arcane
```

If you chose NAT mode, add the following VirtualBox NAT Rule:

| Rule Name    | Protocol | Host IP   | Host Port | Guest IP | Guest Port |
|--------------|----------|-----------|-----------|----------|------------|
| **Arcane**      | TCP      | 127.0.0.1 | 3552      |          | 3552         |

Rebuild your infrastructure using `make re` and open the following URL — make sure to use HTTP (not HTTPS):

http://yourlogin.42.fr:3552

Follow the setup instructions to create your admin account. The default username and password are `arcane` and `arcane-admin`. You can now see all your Inception containers (WordPress, NGINX, MariaDB) in a single dashboard.

Source: https://getarcane.app/docs

### Bonus 6: HAPROXY

While Arcane is now up and running, it currently has unrestricted read and write access to the host's Docker socket (`/var/run/docker.sock`) — a major security risk if the container gets compromised. To enforce the principle of least privilege, we will secure our infrastructure by implementing a socket proxy using `HAProxy`.

To achieve this, we will move away from the default version of HAProxy bundled with Debian 12. While stable, the legacy 2.6 release proved too rigid for the modern requirements of the Docker API and Arcane's interactive terminal. By installing **HAProxy 3.2 LTS**, we can implement a truly "intelligent" proxy that inspects every request, selectively upgrading connections to bi-directional tunnels only when a terminal is requested, while maintaining a strict "Zero Trust" policy for everything else.

Let's create the structure:
```sh
mkdir -p ~/inception/srcs/requirements/bonus/haproxy/{conf,tools}
```

Add these configuration variables to your .env file:
```env
# HAPROXY
HAPROXY_VERSION=3.2.19
HAPROXY_HOST=haproxy
HAPROXY_PORT=2375
```

Create the `Dockerfile`:

```sh
touch ~/inception/srcs/requirements/bonus/haproxy/Dockerfile
```

And copy the following in it:

```dockerfile
# Use Debian Bookworm as the base image
FROM debian:12

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# Install prerequisites for adding the official HAProxy repository
RUN apt-get update && apt-get install -y \
    curl gnupg ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Register the HAProxy official repository (3.2 LTS)
# HAProxy 3.2 is required: Debian 12 ships 2.6 which strips hop-by-hop headers
# (Connection, Upgrade) even when re-injected via http-request rules, making
# Docker's exec/attach TCP upgrade impossible in HTTP mode.
RUN curl https://haproxy.debian.net/haproxy-archive-keyring.gpg \
        --create-dirs --output /etc/apt/keyrings/haproxy-archive-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/haproxy-archive-keyring.gpg] \
        https://haproxy.debian.net bookworm-backports-3.2 main" \
        > /etc/apt/sources.list.d/haproxy.list

# Install the pinned HAProxy version
# The '*' suffix matches the Debian revision suffix (e.g. 3.2.19-1~bpo12+1)
ARG HAPROXY_VERSION=3.2.19
RUN apt-get update && apt-get install -y \
    "haproxy=${HAPROXY_VERSION}*" \
    && rm -rf /var/lib/apt/lists/*

# Copy our custom security configuration
COPY conf/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

# Copy the initialization script to the container
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the internal port (default 2375) dynamically injected at build time
ARG HAPROXY_PORT=2375
EXPOSE ${HAPROXY_PORT}

# Set the entrypoint script to handle setup and environment preparation at container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed as PID 1 via the entrypoint's 'exec "$@"'
# -f: Specifies the path to the configuration file.
# By default, HAProxy runs in the foreground unless '-D' is specified,
# ensuring the container remains active and manageable by Docker.
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
```

The socket proxy service also needs an `entrypoint.sh` script:

```sh
touch ~/inception/srcs/requirements/bonus/haproxy/tools/entrypoint.sh
```

Copy and paste the following code in it:

```sh
#!/bin/sh

# Stop the script immediately if any command fails
set -e

# Only run setup logic if the command passed is 'haproxy'
if [ "$1" = "haproxy" ]; then

    # 1. Fail-fast validation
    # Ensures the mandatory HAPROXY_PORT is set before proceeding
    if [ -z "$HAPROXY_PORT" ]; then
        echo "Error: Missing HAPROXY_PORT environment variable." >&2
        exit 1
    fi

    # 2. Dynamic Port Configuration
    # Injects the dynamic port into the haproxy.cfg bind instruction.
    # We use a regex '[0-9]*' instead of hardcoding '2375' to ensure idempotency.
    # This allows the container to restart successfully without failing the substitution.
    echo "Configuring HAProxy to listen on port: $HAPROXY_PORT"
    sed -i "s/bind \*:[0-9]*/bind \*:${HAPROXY_PORT}/" /usr/local/etc/haproxy/haproxy.cfg
fi

# 3. Execute the command from CMD
# 'exec' replaces the shell with the HAProxy process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
```

Then, create the `haproxy.cfg` configuration file:
```sh
touch ~/inception/srcs/requirements/bonus/haproxy/conf/haproxy.cfg
```

And copy the following in it:
```conf
global
    # Forward logs to stdout — readable via 'docker logs'
    log stdout format raw local0

defaults
    # HAProxy operates at Layer 7 (HTTP) to allow path-based filtering and deep inspection
    mode http

    # Standard timeout configurations for connection, client, and server response
    timeout connect 5000ms
    timeout client  50000ms
    timeout server  50000ms

    # Extended timeout for tunneled connections (exec/attach interactive sessions)
    timeout tunnel 1h

    # Inherit logging configuration from the global section
    log global

    # Generates rich logs for HTTP requests, including paths, status codes, and timings
    option httplog

frontend docker-api
    # Listens on all interfaces on the port dynamically injected by the entrypoint
    bind *:2375

    # --- ACLs: define what Arcane is allowed to reach ---

    # Safe read-only endpoints
    acl is_read_only path_reg ^/(v[0-9.]+/)?(version|info|_ping|events|images/json|containers/json|networks|volumes)$

    # Detailed container inspection (required for Arcane to view logs, stats, and details)
    acl is_container_inspect path_reg ^/(v[0-9.]+/)?containers/[a-zA-Z0-9_.-]+/(json|logs|stats|top)$

    # Container lifecycle control — no DELETE
    acl is_container_action path_reg ^/(v[0-9.]+/)?containers/[a-zA-Z0-9_.-]+/(start|stop|restart|kill|wait|attach)$

    # Exec API: create and run commands inside containers
    acl is_exec path_reg ^/(v[0-9.]+/)?(containers/[a-zA-Z0-9_.-]+/exec|exec/[a-zA-Z0-9_.-]+/(start|json))$

    # High-risk daemon-level endpoints
    acl forbidden_paths path_reg ^/(v[0-9.]+/)?(build|swarm|system|nodes|services|tasks|plugins|configs|secrets|auth|commit)$

    # --- Rules: deny > allow > deny all (zero-trust) ---
    http-request deny  if forbidden_paths
    http-request allow if is_read_only
    http-request allow if is_container_inspect
    http-request allow if is_container_action
    http-request allow if is_exec
    http-request deny

    # Route all authorized and sanitized traffic to the backend
    default_backend docker-socket

backend docker-socket
    # Identifies requests that require an HTTP → TCP protocol upgrade
    acl is_terminal path_reg ^/(v[0-9.]+/)?(exec/[a-zA-Z0-9_.-]+/start|containers/[a-zA-Z0-9_.-]+/attach)$

    # Inject upgrade headers so Docker switches its connection to raw TCP stream mode.
    # HAProxy 3.2 correctly preserves these hop-by-hop headers when set via http-request
    # rules, unlike HAProxy 2.6 which stripped them before forwarding to the backend.
    http-request set-header Connection "Upgrade" if is_terminal
    http-request set-header Upgrade    "tcp"     if is_terminal

    # Safety net: if Docker responds 200 instead of 101 for any reason, force the
    # status to 101 Switching Protocols to trigger HAProxy's internal tunnel mode.
    # In practice Docker responds with 101 directly when it receives the Upgrade headers.
    http-response set-status 101 reason "Switching Protocols" if is_terminal { status 200 }

    # 'unix@' tells HAProxy to use a Unix socket instead of TCP.
    # The 'check' option is omitted: health checks on Unix sockets require specific
    # HTTP probes; omitting it avoids falsely marking the backend as DOWN.
    server docker unix@/var/run/docker.sock

```

Ensure that your haproxy.cfg file ends with a final empty line (a trailing newline). This line must be completely blank, containing no spaces or tabs. HAProxy's configuration parser may fail to read the last directive or even crash during startup if this terminating newline is missing.

Next, let's update Arcane's `entrypoint.sh` script to route its Docker API calls through our new proxy instead of the default local socket. By setting the `DOCKER_HOST` environment variable, we instruct the Docker client inside Arcane to communicate strictly over TCP with HAProxy. Replace the file content with the following:

```sh
#!/bin/sh

# Stops the script immediately if any command fails
set -e

# Only run setup logic if the command passed is './arcane'
if [ "$1" = "./arcane" ]; then

    # 1. Fetch secrets from Docker secret mount points
    ARC_ENCRYPTION_KEY=$(cat /run/secrets/arc_encryption_key)
    ARC_JWT_SECRET=$(cat /run/secrets/arc_jwt_secret)

    # 2. Fail-fast validation
    # Check for secrets and mandatory environment variables
    if [ -z "$ARCANE_PORT" ] || [ -z "$ARC_ENCRYPTION_KEY" ] || [ -z "$ARC_JWT_SECRET" ]; then
        echo "Error: Missing ARCANE_PORT environment variable, ARC_ENCRYPTION_KEY and/or ARC_JWT_SECRET secret(s)." >&2
        exit 1
    fi

    # 3. Export secrets to environment for the application
    export PORT="$ARCANE_PORT"
    export ENCRYPTION_KEY="$ARC_ENCRYPTION_KEY"
    export JWT_SECRET="$ARC_JWT_SECRET"

    # 4. Configures the Docker client to talk to HAProxy instead of the local socket
    if [ -n "$HAPROXY_HOST" ]; then
        if [ -z "$HAPROXY_PORT" ]; then
            echo "Error: HAPROXY_HOST is set but HAPROXY_PORT is missing." >&2
            exit 1
        fi
        echo "Routing Docker traffic through HAProxy at ${HAPROXY_HOST}:${HAPROXY_PORT}"
        export DOCKER_HOST="tcp://${HAPROXY_HOST}:${HAPROXY_PORT}"
    fi
fi

# 5. Execute the command from CMD
# 'exec' replaces the shell with the Arcane process so it becomes PID 1.
exec "$@"
```

It is now time to update the `docker-compose.yml` file to reflect this architectural shift. We need to do three things:
1. Create the new `haproxy` service and give it exclusive access to the host's Docker socket.
2. Remove Arcane's direct access to the `docker.sock` volume so it can no longer bypass the proxy.
3. Pass the `HAPROXY_HOST` environment variable to Arcane so it knows where to send its API requests.

```yaml
# Update the 'arcane' service and add the 'haproxy' one
services:
  # ... other services

  arcane:
    # ... other configs
    depends_on:
      haproxy:
        condition: service_started
    environment:
      - ARCANE_PORT
      - HAPROXY_HOST
      - HAPROXY_PORT
    volumes:
      # Remove: /var/run/docker.sock:/var/run/docker.sock:rw
      - arcane_data:/app/data
    # ... other configs

  haproxy:
    build:
      context: ./requirements/bonus/haproxy
      args:
        - HAPROXY_VERSION
        - HAPROXY_PORT
    image: haproxy:inception-v1
    container_name: haproxy
    restart: unless-stopped
    environment:
      - HAPROXY_PORT
    volumes:
      # Only the proxy has access to the real docker socket
      - /var/run/docker.sock:/var/run/docker.sock:rw
    networks:
      - inception
    logging: *default-logging
```

To verify your secure setup, simply run `make re`, refresh your Arcane dashboard, and monitor `docker logs -f haproxy` to watch your API requests being safely filtered and routed in real-time.

Source: https://docs.haproxy.org/

## Final Submission & Vogsphere Deployment

To submit your project, you must push your code directly from your Virtual Machine to the 42 Vogsphere repository. Since the VM is isolated, you first need to transfer your authorized SSH key from your host machine to the VM.

> ⚠️ **Warning:** Before proceeding, double-check your `.gitignore` file. Ensure that the `secrets/` directory and your `.env` file are completely ignored. Pushing passwords or environment variables to the Vogsphere will compromise your project.

### Step 1: Prepare the SSH Directory in the VM

First, open the terminal **inside your VM** and create the hidden `.ssh` directory with the correct security permissions:

```sh
mkdir -p ~/.ssh
```
```sh
chmod 700 ~/.ssh
```

### Step 2: Authenticate with your SSH Key

To connect to the 42 Vogsphere, your VM needs access to your authorized SSH key. You can achieve this using a secure "Forwarding" method (recommended) or a manual "Copy" method.

#### Option A: SSH Agent Forwarding

This is the cleanest method because your private key **never leaves your host machine**. The VM simply "borrows" your host's authentication agent to talk to Vogsphere.

**On your Host Machine:** Add your key to the SSH agent:

```sh
ssh-add ~/.ssh/id_rsa
```

**In VSCode**, open the command palette (`Ctrl+Shift+P` / `Cmd+Shift+P`), type `SSH: Open SSH Configuration File`. Select your user's config file (e.g., `~/.ssh/config`) and add `ForwardAgent yes` in the corresponding block as follows:

```ssh-config
Host inception
    HostName <your_vm_ip_or_localhost>
    User <yourlogin>
    Port <22_or_2222>
    ForwardAgent yes
```

Now, still **in VSCode**, close the remote connection and reconnect to the host. Then, with its terminal, verify that the agent is active:

```sh
ssh-add -l
```

If you see your key listed, the VM is now authorized to use it for Vogsphere.

#### Option B: Manual Key Transfer

If you prefer your VM to be independent, you can copy your key files directly onto the virtual disk.

Open a terminal **on your Host Machine** to securely copy your keys to the VM using `scp` (Secure Copy Protocol). The command depends on your VirtualBox network configuration:

* **For NAT Mode:**
  Since NAT mode requires port forwarding, you must specify the forwarded SSH port (`2222`). Assuming this is a dedicated VM for this project, you can copy the keys using their default names:

  ```sh
  scp -P 2222 ~/.ssh/id_rsa yourlogin@localhost:~/.ssh/
  ```
  ```sh
  scp -P 2222 ~/.ssh/id_rsa.pub yourlogin@localhost:~/.ssh/
  ```

* **For Bridged Mode:**
  In Bridged mode, you communicate directly with the VM's local IP address (find it by running `hostname -I` in the VM):

  ```sh
  scp ~/.ssh/id_rsa yourlogin@<VM_IP_ADDRESS>:~/.ssh/
  ```
  ```sh
  scp ~/.ssh/id_rsa.pub yourlogin@<VM_IP_ADDRESS>:~/.ssh/
  ```

Return to the terminal **inside your VM**. SSH is extremely strict about file permissions. If your private key is accessible to anyone else, SSH will refuse to use it. Lock down the files:

```sh
chmod 600 ~/.ssh/id_rsa
```
```sh
chmod 644 ~/.ssh/id_rsa.pub
```

### Step 3: Test the Vogsphere Connection

To verify that your VM is recognized by the 42 servers, run the following command (adjust the domain to your specific campus):

```sh
ssh -T git@vogsphere.42mycity.com
```
If you see a message saying `"Welcome <yourlogin>!"`, your SSH connection is successfully configured.

### Step 4: Configure the Git Remote

If your project currently points to a personal GitHub repository, you must detach it and link it to your official 42 Vogsphere repository. Remove the old remote (if any):

```sh
git remote remove origin
```

Add the Vogsphere repository (you can find this URL on your intra project page):

```sh
git remote add origin git@vogsphere.42mycity.com:vogsphere/intra-uuid-xxxx-xxxx
```

Verify that the remote was added correctly:

```sh
git remote -v
```

### Step 5: Enforce the master Branch

The Vogsphere server **only** accepts pushes to the `master` branch. Modern Git versions often use `main` by default. If you push `main`, the server will ignore it. Check your current branch name:

```sh
git branch
```

If your branch is named `main` (or anything else), rename it to `master`:

```sh
git branch -m master
```

### Step 6: Final Commit and Push

You are now ready to send your code. Stage your files, create your final commit, and push to the server:

```sh
git add .
```

```sh
git commit -m "feat: final project submission"
```

```sh
git push -u origin master
```

Congratulations! Your Inception infrastructure is now deployed to the Vogsphere and ready for evaluation.
