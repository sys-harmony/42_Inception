# Developer Documentation

This document provides instructions for developers to set up, build, and maintain the Inception project.

> **Note on Naming Conventions:**  
> This project is configured using `gdosch` as the primary username and domain prefix, as required by the subject's constraints for my personal submission. If you are a developer looking to deploy or adapt this infrastructure, you must replace every occurrence of `gdosch` with your own login to ensure the environment paths, domain names, and services function correctly for your setup.

## Environment Setup

### Prerequisites
* Docker and Docker Compose (V2) must be installed on the host machine.
* `make` must be installed.
* Ensure port `443`, `8080`, `8081`, `3552`, and `21` are available on the host.

### Configuration Files and Secrets
Before building the project, you must manually create the required credentials.

1. **Environment Variables:**
   Create a `.env` file inside the `srcs/` directory containing the configuration keys (e.g., `DOMAIN_NAME=gdosch.42.fr`, `MYSQL_DATABASE=wordpress`, etc.).

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

## Build and Launch
The project is orchestrated using a `Makefile` situated at the root directory.

* **`make`** or **`make all`**: Creates the necessary local directories for persistent storage (`/home/gdosch/data/...`), builds all Docker images using `docker compose build`, and starts the containers in detached mode.
* **`make build`**: Only builds the images.
* **`make up`**: Starts the existing containers in the background.

## Container and Volume Management
* **`make down`**: Stops and removes the containers and the default network. Volumes are preserved.
* **`make clean`**: Executes `make down` and runs `docker system prune -f` to clean up dangling resources.
* **`make fclean`**: Executes a complete wipe. It removes containers, volumes, all images (`--rmi all`), clears the Docker cache, and forcefully deletes the local data directories (`sudo rm -rf /home/gdosch/data`).
* **`make re`**: Executes `make fclean` followed by `make all` for a fresh start.

## Data Storage and Persistence
To ensure data persists across container restarts and recreations, we use Docker volumes bound to specific host directories via driver options.
All persistent data is stored on the host machine under `/home/gdosch/data/`.

* `/home/gdosch/data/mariadb` -> Mapped to `/var/lib/mysql` (Database files)
* `/home/gdosch/data/wordpress` -> Mapped to `/var/www/html` (Website core, themes, plugins, and static files)
* `/home/gdosch/data/arcane` -> Mapped to `/app/data` (Monitoring data)

## Full Setup Tutorial

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
# Ignore the secrets directory
secrets/

# Ignore environment files
.env
EOF
```

To create the `.env` file in `srcs` with the following configuration, type:
```bash
cat << 'EOF' > ~/inception/srcs/.env
DOMAIN_NAME=yourlogin.42.fr
# MYSQL SETUP
MYSQL_USER=yourlogin
MYSQL_DATABASE=wordpress
MYSQL_HOSTNAME=mariadb
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
echo "your_db_password" > db_password.txt
```

```bash
echo "your_db_root_password" > db_root_password.txt
```

```bash
echo "your_wp_admin_password" > wp_admin_password.txt
```

```bash
echo "your_wp_user_password" > wp_user_password.txt
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

services:
  mariadb:
    build: ./requirements/mariadb
    image: mariadb
    container_name: mariadb
    restart: always
    environment:
      - MYSQL_DATABASE=\${MYSQL_DATABASE}
      - MYSQL_USER=\${MYSQL_USER}
      - MYSQL_HOSTNAME=\${MYSQL_HOSTNAME}
    secrets:
      - db_password
      - db_root_password
    volumes:
      - mariadb_data:/var/lib/mysql
    networks:
      - inception

  wordpress:
    build: ./requirements/wordpress
    image: wordpress
    container_name: wordpress
    restart: always
    depends_on:
      - mariadb
    env_file: .env
    secrets:
      - db_password
      - wp_admin_password
      - wp_user_password
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - inception

  nginx:
    build: ./requirements/nginx
    image: nginx
    container_name: nginx
    restart: always
    depends_on:
      - wordpress
    environment:
      - DOMAIN_NAME=\${DOMAIN_NAME}
    ports:
      - "443:443"
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - inception

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
    driver: bridge

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
DATA_PATH = /home/yourlogin/data
COMPOSE_FILE = srcs/docker-compose.yml

.PHONY: all build up down clean fclean re

all: up

# Create local storage directories and build images
build:
	@mkdir -p \$(DATA_PATH)/mariadb \$(DATA_PATH)/wordpress \$(DATA_PATH)/arcane
	docker compose -f \$(COMPOSE_FILE) build

# Start containers in detached mode
up: build
	docker compose -f \$(COMPOSE_FILE) up -d

# Stop running containers
down:
	docker compose -f \$(COMPOSE_FILE) down

mariadb:
	docker exec -it mariadb mysql -u root -p

# Remove containers and networks
clean: down
	@docker system prune -f

# Full cleanup: removes images, volumes, docker cache, AND data directories
fclean: 
	docker compose -f \$(COMPOSE_FILE) down -v --rmi all
	@docker system prune -af
	@sudo rm -rf \$(DATA_PATH)

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

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
	apt-get install -y mariadb-server mariadb-client && \
	rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/lib/mysql /run/mysqld && \
	chown -R mysql:mysql /var/lib/mysql /run/mysqld

COPY tools/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["mysqld", "--user=mysql", "--bind-address=0.0.0.0"]
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

# 1. Fetch secrets from Docker secret mount points
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# 2. Fail-fast validation
if [ -z "$MYSQL_ROOT_PASSWORD" ] || [ -z "$MYSQL_DATABASE" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ]; then
    echo "Error: Missing mandatory database environment variables or secrets." >&2
    exit 1
fi

# 3. MariaDB Installation Logic
if [ "$1" = 'mysqld' ]; then
    # Marker file check to prevent re-initialization
    if [ ! -f "/var/lib/mysql/.initialized" ]; then
        echo "Initializing MariaDB database..."

        chown -R mysql:mysql /var/lib/mysql
        mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

        # Use bootstrap to configure users and database privileges
        mysqld --user=mysql --datadir=/var/lib/mysql --bootstrap <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
        # Create the marker file to confirm success
        touch /var/lib/mysql/.initialized
        echo "MariaDB initialized successfully."
    fi
fi

# 4. Execute the command from CMD (PID 1)
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

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
	apt-get install -y \
	php8.2-fpm php8.2-mysql php8.2-curl php8.2-gd php8.2-intl \
	php8.2-mbstring php8.2-xml php8.2-zip wget mariadb-client ca-certificates && \
	rm -rf /var/lib/apt/lists/*

RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
	chmod +x wp-cli.phar && \
	mv wp-cli.phar /usr/local/bin/wp

RUN mkdir -p /run/php && \
	chown -R www-data:www-data /run/php

RUN sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 9000|' /etc/php/8.2/fpm/pool.d/www.conf

WORKDIR /var/www/html

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
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
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

# 2. Fail-fast validation
# Database checks
if [ -z "$MYSQL_HOSTNAME" ] || [ -z "$MYSQL_DATABASE" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ]; then
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

# 3. Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
until mysql -h"$MYSQL_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
    sleep 2
done

# 4. WordPress Installation Logic
if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "WordPress not found. Starting installation..."

    # Download WordPress core files
    wp core download --allow-root

    # Create wp-config.php dynamically
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="$MYSQL_HOSTNAME" \
        --allow-root

    # Install WordPress and set up the administrator account
    wp core install \
        --url="https://$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root

    # Create the mandatory secondary user
    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --role=author \
        --user_pass="$WP_USER_PASSWORD" \
        --allow-root

    # Fix ownership and permissions for the web server user
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    echo "WordPress installed successfully."
fi

# 5. Execute the command from CMD (PID 1)
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

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
	apt-get install -y nginx openssl && \
	rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/nginx.conf

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
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
if [ -z "$DOMAIN_NAME" ]; then
    echo "[ERROR] DOMAIN_NAME environment variable is missing." >&2
    exit 1
fi

# 2. Dynamic Configuration Injection
# We replace the placeholder in nginx.conf with your actual domain name
echo "[INFO] Configuring NGINX for domain: $DOMAIN_NAME"
sed -i "s/__DOMAIN_NAME__/$DOMAIN_NAME/g" /etc/nginx/nginx.conf

# 3. SSL Certificate Generation
# We generate a self-signed certificate if it doesn't exist yet
CERTS_DIR="/etc/nginx/ssl"

if [ ! -f "$CERTS_DIR/$DOMAIN_NAME.crt" ]; then
    echo "[INFO] Generating self-signed SSL certificate..."
   
    mkdir -p "$CERTS_DIR"
   
    # Generate the key and certificate valid for 365 days
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERTS_DIR/$DOMAIN_NAME.key" \
        -out "$CERTS_DIR/$DOMAIN_NAME.crt" \
        -subj "/C=FR/ST=GrandEst/L=Mulhouse/O=42/OU=Inception/CN=$DOMAIN_NAME"
       
    echo "[INFO] SSL certificate generated successfully."
fi

# 4. Execute the command from CMD (PID 1)
exec "$@"
```

NGINX also needs a `nginx.conf` file:

```bash
touch ~/inception/srcs/requirements/nginx/conf/nginx.conf
```

Copy the following in it:

```nginx
# NGINX Configuration File

# Run nginx as www-data user for security
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    # Basic settings and MIME types
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging paths
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Main Server Block
    server {
        # Listen exclusively on port 443 for both IPv4 and IPv6
        listen 443 ssl;
        listen [::]:443 ssl;

        # The server name will be dynamically replaced by the entrypoint script
        server_name __DOMAIN_NAME__;

        # SSL Configuration (Subject strictly requires TLSv1.2 and/or TLSv1.3)
        ssl_certificate /etc/nginx/ssl/__DOMAIN_NAME__.crt;
        ssl_certificate_key /etc/nginx/ssl/__DOMAIN_NAME__.key;
        ssl_protocols TLSv1.2 TLSv1.3;

        # Root directory (shared via Docker volumes)
        root /var/www/html;
       
        # Default files to serve
        index index.php index.html index.htm;

        # Route all standard requests
        location / {
            try_files $uri $uri/ /index.php?$args;
        }

        # Pass PHP scripts to PHP-FPM (the WordPress container)
        location ~ \.php$ {
            # Prevent NGINX from passing non-existent files to PHP-FPM
            try_files $uri =404;
           
            # Forward the request to the 'wordpress' container on port 9000
            fastcgi_pass wordpress:9000;
            fastcgi_index index.php;
            include fastcgi_params;
           
            # Tell PHP exactly which file to execute
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }

        # Security - deny access to hidden files like .htaccess
        location ~ /\.ht {
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
echo "your_redis_password" > ~/inception/secrets/redis_password.txt 
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

# Copy the entrypoint script
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the default Redis port
EXPOSE 6379

# Define the entrypoint and default command
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
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

# Fetch the secret
REDIS_PASSWORD=$(cat /run/secrets/redis_password)

# Validation
if [ -z "$REDIS_PASSWORD" ]; then
    echo "Error: REDIS_PASSWORD secret is missing." >&2
    exit 1
fi

echo "Starting Redis server..."

# Start Redis and bind it to all interfaces so WordPress can connect
# --requirepass secures Redis with our secret
exec redis-server --bind 0.0.0.0 --requirepass "$REDIS_PASSWORD" --protected-mode no
```

Now we must update the `docker-compose.yml` file. Add the redis_password secret and the service configuration:
```yaml
# Add this in the main 'secrets' section at the bottom
secrets:
  # ... your other secrets
  redis_password:
    file: ../secrets/redis_password.txt

# Add the service inside 'services'
  redis:
    build: ./requirements/bonus/redis
    image: redis
    container_name: redis
    restart: always
    secrets:
      - redis_password
    networks:
      - inception

# Add the new secret
  wordpress:
    # ... other configs (env_file, networks, etc.)
    secrets:
      - db_password
      - redis_password
      - wp_admin_password
      - wp_user_password
```

The WordPress `entrypoint.sh` file also needs editing, add the following right after the secondary account creation:

```bash
    # Redis Setup
    echo "Configuring Redis Cache with authentication..."
    
    # Fetch the redis password from secret to use it in wp-config
    REDIS_PWD=$(cat /run/secrets/redis_password)

    wp plugin install redis-cache --activate --allow-root

    # Configure Redis connection details
    wp config set WP_REDIS_HOST redis --allow-root
    wp config set WP_REDIS_PORT 6379 --raw --allow-root
    # Crucial: Give WordPress the password to talk to Redis
    wp config set WP_REDIS_PASSWORD "$REDIS_PWD" --allow-root

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
echo "your_ftp_password" > ~/inception/secrets/ftp_password.txt
```

Add your username at the end of the `.env` file:
```env
# FTP SETUP
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

# Copy the entrypoint script
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose FTP port and passive mode range
EXPOSE 21 40000-40005

# Run entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
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

# 1. Fetch the secret from the Docker secret mount point
FTP_PWD=$(cat /run/secrets/ftp_password)

# 2. Create the FTP user if it doesn't exist
# We use the environment variable FTP_USER from the .env file
if ! id "$FTP_USER" >/dev/null 2>&1; then
    echo "Creating FTP user: $FTP_USER..."
    useradd -m -s /bin/bash "$FTP_USER"
    echo "$FTP_USER:$FTP_PWD" | chpasswd
    
    # Set the home directory to the WordPress volume path
    usermod -d /var/www/html "$FTP_USER"
fi

# 3. Configuration for vsftpd
# We generate the config file dynamically to ensure correct settings
cat << EOF > /etc/vsftpd.conf
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

# 4. Fix permissions
# WordPress files often belong to www-data. We ensure our FTP user 
# can actually modify/delete them by taking ownership.
echo "Setting permissions for /var/www/html..."
chown -R "$FTP_USER:$FTP_USER" /var/www/html
chmod -R 755 /var/www/html

# 5. Prepare the runtime environment
mkdir -p /var/run/vsftpd/empty

echo "Starting FTP server for user: $FTP_USER"

# 6. Run vsftpd with the generated configuration
exec vsftpd /etc/vsftpd.conf
```

Passive mode is essential here, as Docker uses NAT networking. Without it, the FTP client would not be able to list or transfer files correctly.


It is now time to update the `docker-compose.yml` file:
```yaml
# 1. Add this to the main 'secrets' section at the bottom
secrets:
  # ... other secrets
  ftp_password:
    file: ../secrets/ftp_password.txt

# 2. Add the FTP service
services:
  # ... other services
  ftp:
    build: ./requirements/bonus/ftp
    image: ftp
    container_name: ftp
    restart: always
    environment:
      - FTP_USER=${FTP_USER}
    secrets:
      - ftp_password
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - inception
    ports:
      - "21:21"
      - "40000-40005:40000-40005"
```

It's time to rebuild your infrastructure using `make re` to apply the changes, and test the FTP service.

* **If you chose Bridged mode:**
    You can test it with the following command:

    ```bash
    curl -u yourlogin:yourpassword ftp://your_vm_ip_address:21/a
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

# Install lighttpd and clean up apt cache
RUN apt-get update && apt-get install -y \
lighttpd \
&& rm -rf /var/lib/apt/lists/*

# Copy the configuration file
COPY ./conf/lighttpd.conf /etc/lighttpd/lighttpd.conf

# Copy our static files to the document root
COPY www /var/www/html

# Ensure the web server user owns the files
RUN chown -R www-data:www-data /var/www/html

# Expose port 80 (internally, mapped via docker-compose)
EXPOSE 80

# Run lighttpd in the foreground
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

# Web server user and group (standard Debian)
server.username             = "www-data"
server.groupname            = "www-data"

# Document root matching your COPY command
server.document-root        = "/var/www/html"

# Internal port matching your EXPOSE command
server.port                 = 80

# Default file
index-file.names            = ( "index.html" )

# Basic MIME types (add more if you use images or JS later)
mimetype.assign             = ( ".html" => "text/html" )
```

We need to update the docker-compose.yml file and map the host port 8081 to the container port 80:
```yaml
  static:
    build: ./requirements/bonus/static
    image: static
    container_name: static
    restart: always
    networks:
      - inception
    ports:
      - "8081:80"
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

# Install wget (to download Adminer), PHP, and the PHP-MySQL extension
RUN apt-get update && apt-get install -y \
wget \
php \
php-mysql \
&& rm -rf /var/lib/apt/lists/*

# Create the web directory
RUN mkdir -p /var/www/html

# Download the latest version of Adminer directly into the web directory
# We rename it to index.php so the server loads it by default
RUN wget https://www.adminer.org/latest.php -O /var/www/html/index.php

# Ensure proper permissions (optional but good practice)
RUN chown -R www-data:www-data /var/www/html

# Set the working directory
WORKDIR /var/www/html

# Expose port 8080
EXPOSE 8080

# Start PHP's built-in web server listening on all interfaces
CMD ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/html"]
```

We must update the `docker-compose.yml` file and add the Adminer service. We map it to port 8080. It needs to be on the inception network to communicate with the MariaDB container. Type:
```yaml
  adminer:
    build: ./requirements/bonus/adminer
    image: adminer
    container_name: adminer
    restart: always
    depends_on:
      - mariadb
    networks:
      - inception
    ports:
      - "8080:8080"
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
echo 'MaSuperCleDeChiffrement32Chars!!' > ~/inception/secrets/arc_encryption_key.txt
echo 'MonAutreCleJWTTresSecrete424242!' > ~/inception/secrets/arc_jwt_secret.txt
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
FROM ghcr.io/getarcaneapp/arcane:latest AS builder

# Stage 2: Final image based on Debian 12
FROM debian:12

# Install requirements
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN mkdir -p /app/data

# Copy the binary from the builder stage
COPY --from=builder /app/arcane /usr/local/bin/arcane
RUN chmod +x /usr/local/bin/arcane

# Copy and prepare the entrypoint script
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3552

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
```

Arcane also needs an `entrypoint.sh` script:

```bash
touch ~/inception/srcs/requirements/bonus/arcane/tools/entrypoint.sh
```

Copy and paste the following code in it:

```bash
#!/bin/sh

# Load secrets into environment variables
export ENCRYPTION_KEY=$(cat /run/secrets/arc_encryption_key)
export JWT_SECRET=$(cat /run/secrets/arc_jwt_secret)

# Execute the binary
exec arcane
```

Add the service and the secrets declaration to your `docker-compose.yml`:
```yaml
  arcane:
    build: ./requirements/bonus/arcane
    image: arcane
    container_name: arcane
    restart: always
    secrets:
      - arc_encryption_key
      - arc_jwt_secret
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:rw
      - arcane_data:/app/data
    networks:
      - inception
    ports:
      - "3552:3552"

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
