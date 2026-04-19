# User Documentation

This document explains how to interact with the Inception infrastructure from an end-user or administrator perspective.

## Services Provided
Our stack provides a fully functional web environment consisting of:
* **WordPress:** A dynamic blog platform.
* **MariaDB:** The database engine storing the blog's data.
* **Static Website:** A portfolio/status page hosted on Lighttpd.
* **Adminer:** A web-based database management interface.
* **FTP Server:** A secure file transfer protocol to manage website files remotely.
* **Redis:** An in-memory cache system to speed up WordPress load times.
* **Arcane:** A monitoring tool for Docker containers.

## Starting and Stopping the Project
To manage the state of the infrastructure, use the provided Makefile commands from the root directory:
* **Start the project:** `make up`
* **Stop the project:** `make down`
* **Stop and wipe all data:** `make fclean` (Warning: This deletes all databases and website files!)

## Accessing the Services
Ensure that your host machine's `/etc/hosts` file maps the domain `gdosch.42.fr` to your Virtual Machine's IP address.
* **Main Website (WordPress):** `https://gdosch.42.fr` (Accept the self-signed SSL certificate warning).
* **Static Website:** `http://gdosch.42.fr:8081`
* **Adminer (Database Admin):** `http://gdosch.42.fr:8080`
* **Arcane (Monitoring):** `http://gdosch.42.fr:3552`
* **FTP Access:** Connect using an FTP client (like FileZilla) to `gdosch.42.fr` on port `21`.

## Managing Credentials
Credentials are not stored in the repository for security reasons. Administrators must provide them locally.
* **Database & Site Passwords:** Located in the `secrets/` directory on the host machine.
* **Environment Variables:** Located in the `srcs/.env` file.
To change a password, you must stop the project (`make down`), update the respective `.txt` file in the `secrets/` directory, and restart the project.

## Checking Service Health
To verify that all services are running correctly:
1. Open a terminal on the host machine.
2. Run `docker ps` to see the status of all containers. Ensure none are marked as "restarting" or "exited".
3. To view the logs of a specific service (e.g., NGINX), run `docker logs nginx`.

## Full Inception Setup Tutorial

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
*   **Full name & Username:** (Your login)
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
Choose between **NAT** and **Bridged Adapter**:

*   **NAT mode:** Isolates the VM in a private network. The VM can access the internet, but your host cannot access VM services without port forwarding.
*   **Bridged mode:** Connects the VM directly to your local network. You can access `yourlogin.42.fr` without port forwarding, but the IP may change on reboot (requires `/etc/hosts` and `ssh config` updates).

#### If using NAT mode:
Click on **Port Forwarding** and add the following rules:

| Rule Name    | Protocol | Host IP   | Host Port | Guest IP | Guest Port |
|--------------|----------|-----------|-----------|----------|------------|
| **SSH**      | TCP      | 127.0.0.1 | 2222      |          | 22         |
| **HTTPS**    | TCP      | 127.0.0.1 | 8443      |          | 443        |

Apply the changes and restart the VM:
```bash
reboot
```

#### If using Bridged mode:
Log in to the VM and find its IP:
```bash
hostname -I
```
Then note the first IP address displayed — we will need it.

---

### 5. SSH & VSCode Access

From your **host machine's terminal**, verify the SSH connection:

*   **Bridged Mode:** `ssh yourlogin@<your_vm_ip_address>`
*   **NAT Mode:** `ssh yourlogin@localhost -p 2222`

Confirm the fingerprint (`yes`) and enter your user password. If your prompt changes to yourlogin@inception:~$, it means everything is working correctly.

#### Connect VSCode via SSH
1. Open **VSCode** locally and install the **"Remote - SSH"** extension.
2. Open the command palette (`Ctrl+Shift+P` / `Cmd+Shift+P`), type **SSH: Open SSH Configuration File**.
3. Select your user's config file (e.g., `~/.ssh/config`) and add the corresponding block:

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

4. In VSCode, click the green `><` icon (bottom-left) -> **Connect to Host...** -> **inception**.
5. Once connected, click **Open Folder** and select `/home/<yourlogin>`.

To avoid VSCode asking for your password too oftenm you can set up an SSH key. If you already have one, skip to the next step.

Be careful: generating a new SSH key can overwrite an existing one if you are not attentive to the file location, so make sure you know what you are doing before proceeding. If you don’t have an SSH key yet, you first need to create one. In your physical computer’s terminal (not the VM), run:

```
ssh-keygen -t rsa -b 4096
```

Once the key is ready (or if you already have one) send it to your virtual machine using the following command:

**For Bridged Mode:**
```
ssh-copy-id yourlogin@your_vm_ip_address
```

**For NAT Mode:**
```
ssh-copy-id -p 2222 yourlogin@localhost
```

---

### 6. Local Domain DNS Routing

Map your domain name to your VM so requests resolve correctly. Open your host's `/etc/hosts` file (with `sudo`):
```bash
sudo nano /etc/hosts
```

Add the following line based on your mode:

**For Bridged Mode:**

```
<your_vm_ip_address>   yourlogin.42.fr
```
*(Must update if VM IP changes)*

**For NAT Mode:**
```
127.0.0.1   yourlogin.42.fr
```

---

### 7. Install Docker

Open the VSCode integrated terminal (`Ctrl+J`) directly inside the VM and install Docker using the official repository:

```bash
# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: \$(. /etc/os-release && echo "\$VERSION_CODENAME")
Components: stable
Architectures: \$(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Install Docker:
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Verify installation: `sudo systemctl status docker` and `docker compose version`.

To use Docker without `sudo`:
```bash
sudo usermod -aG docker yourlogin
```
*(You may need to log out and log back in for this to take effect.)*

---

### 8. Project Structure & Environment

Create the necessary folders:
```bash
cd ~
mkdir -p inception/srcs/requirements/mariadb/tools
mkdir -p inception/srcs/requirements/nginx/conf
mkdir -p inception/srcs/requirements/nginx/tools
mkdir -p inception/srcs/requirements/wordpress/tools
mkdir -p inception/srcs/requirements/tools
mkdir -p inception/secrets
```

Secure the repository by ignoring secrets and `.env`:
```bash
cd ~/inception
cat << 'EOF' > .gitignore
# Ignore the secrets directory
secrets/

# Ignore environment files
**/.env
EOF
```

Create the `.env` file in `srcs`:
```bash
cd ~/inception/srcs
cat << 'EOF' > .env
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

Store passwords securely in `/secrets/`:
```bash
cd ~/inception/secrets
echo "your_db_password" > db_password.txt
echo "your_db_root_password" > db_root_password.txt
echo "your_wp_admin_password" > wp_admin_password.txt
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

Create `Makefile` (`~/inception/Makefile`):
*(Make sure to use actual Tabs instead of spaces for indentation)*
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

---

### 10. Dockerfiles & Entrypoint Scripts

The configuration files (`Dockerfile`, `entrypoint.sh`, `nginx.conf`, etc.) need to be written according to the tutorial provided previously. Follow the setup code to place each `Dockerfile` internally correctly:


**MariaDB (`srcs/requirements/mariadb/Dockerfile`):**
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

**WordPress (`srcs/requirements/wordpress/Dockerfile`):**
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

**NGINX (`srcs/requirements/nginx/Dockerfile`):**
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

> **Note:** The `entrypoint.sh` scripts code (for initializing the Database securely, injecting WP-CLI configuration, and dynamically processing `__DOMAIN_NAME__` to provision self-signed certificates) must be placed in their matching `tools/entrypoint.sh` paths. (See full code setup).

---

### 11. Run the Project!

Once everything is written and mapped out:
```bash
sudo apt update
sudo apt install make
cd ~/inception
make up
```

Your system is alive at `https://yourlogin.42.fr` (Accept self-signed certificates in your browser).

---

## BONUS Deployments

### Bonus 1: REDIS
Redis is an excellent performance upgrade for your WordPress site. We will now create a secret for it:
```bash
echo "your_redis_password" > ~/inception/secrets/redis_password.txt 
```

Let's create the structure:
```bash
mkdir -p ~/inception/srcs/requirements/bonus/redis/tools
```

We will now create the Redis Dockerfile:
```bash
cd ~/inception/srcs/requirements/bonus/redis
touch Dockerfile
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

Now it's time to create the entrypoint.sh for Redis:
```bash
cd ~/inception/srcs/requirements/bonus/redis/tools
touch entrypoint.sh
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

Now we must update the docker-compose.yml file. Add the redis_password secret and the service configuration:
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

The WordPress entrypoint.sh file also needs editing, add the following right after the secondary account creation:
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

To verify that everything is working as expected, open your browser and go to:
https://yourlogin.42.fr/wp-admin

Log in using your credentials, then navigate to Settings → Redis. If you can read “Status: Connected” displayed in green, everything works fine.

---

### Bonus 2: FTP

FTP (File Transfer Protocol) is a classic bonus with real practical value. It allows you to upload and retrieve files (images, themes, plugins, etc.) directly into your WordPress directory from your physical machine, using a client such as FileZilla. We're going tu use vsftpd (Very Secure FTP Daemon).

We will now create a secret for it:
```bash
echo "your_ftp_password" > ~/inception/secrets/ftp_password.txt
```

Add your username at the end of the .env file:
```env
# FTP SETUP
FTP_USER=yourlogin
```

Let's create the structure:
```bash
mkdir -p ~/inception/srcs/requirements/bonus/ftp/tools
```

We will now create the FTP Dockerfile:
```bash
cd ~/inception/srcs/requirements/bonus/ftp
touch Dockerfile
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

FTP requires a system user to operate. We create it dynamically at runtime with an entrypoint.sh file:
```bash
cd ~/inception/srcs/requirements/bonus/ftp/tools
touch entrypoint.sh
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


It is now time to update the docker-compose.yml file:
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

We will quickly test that the FTP service is working.

If you chose Bridged mode:
You can test it with the following command:
```bash
curl -u yourlogin:yourpassword ftp://your_vm_ip_address:21/a
```

Or install and use ftp to navigate in it:
```bash
sudo apt-get update && sudo apt-get install -y ftp
ftp your_vm_ip_address 21
```

If you chose NAT mode, you first have to create all these port forwarding rules :

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

Or install and use ftp to navigate in it:
```bash
sudo apt-get update && sudo apt-get install -y ftp
ftp 127.0.0.1 2121
```

If the connection is successful, you should see a listing of the files in your WordPress directory.

---

### Bonus 3: STATIC WEBSITE

This bonus consists of a simple static page served by a dedicated NGINX container.

Create the project structure:
```bash
mkdir -p ~/inception/srcs/requirements/bonus/static/www
mkdir -p ~/inception/srcs/requirements/bonus/static/conf
```

Let's create the Dockerfile for the static website. Since we use the default NGINX configuration which already serves /var/www/html, we don't even need a custom nginx.conf
```bash
cd ~/inception/srcs/requirements/bonus/static
touch Dockerfile
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
cd ~/inception/srcs/requirements/bonus/static/www
touch index.html
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

We will now configure the web server, lighttpd. Let's start with its configuration file:
```bash
cd ~/inception/srcs/requirements/bonus/static/conf
touch lighttpd.conf
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
mimetype.assign             = (
    ".html" => "text/html",
    ".css"  => "text/css",
    ".txt"  => "text/plain"
)
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
Rule 3: Static Website
• Name: Static
• Protocol: TCP
• Host IP: 127.0.0.1 (or leave empty)
• Host Port: 8081
• Guest IP: (leave empty)
• Guest Port: 8081

Then open the following URL — make sure to use HTTP (not HTTPS):
http://yourlogin.42.fr:8081

---

### Bonus 4: ADMINER

Adminer is a lightweight database management tool written in a single PHP file. It is a great alternative to phpMyAdmin.

Create the structure:
```bash
mkdir -p ~/inception/srcs/requirements/bonus/adminer
```

We will now create the Dockerfile. Adminer doesn't even need local files or entrypoint scripts, we can download it directly when building the image.
```bash
cd ~/inception/srcs/requirements/bonus/adminer
touch Dockerfile
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

We must update the docker-compose.yml file and add the Adminer service. We map it to port 8080. It needs to be on the inception network to communicate with the MariaDB container. Type:
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
Rule 4: Adminer
• Name: Adminer
• Protocol: TCP
• Host IP: 127.0.0.1 (or leave empty)
• Host Port: 8080
• Guest IP: (leave empty)
• Guest Port: 8080

Rebuild your infrastructure using `make re`. Open your browser and go to http://yourlogin.42.fr:8080. You will be greeted by the Adminer login screen. Use the following credentials:
• System: MySQL / MariaDB
• Server: mariadb (This is the container name, Docker's internal DNS will resolve it)
• Username: yourlogin
• Password: The password you set in your secrets
• Database: wordpress

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

Update your Makefile to include the Arcane data directory:
```makefile
@mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress $(DATA_PATH)/arcane
```

It's time to create the Arcane Dockerfile. We'll use a multi-stage build to keep our image lightweight while strictly basing our final container on Debian 12.
```bash
cd ~/inception/srcs/requirements/bonus/arcane
touch Dockerfile
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

Arcane also needs an entrypoint.sh script:
```bash
cd ~/inception/srcs/requirements/bonus/arcane/tools
touch entrypoint.sh
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

Add the service and the secrets declaration to your docker-compose.yml:
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

Then open the following URL — make sure to use HTTP (not HTTPS):
http://yourlogin.42.fr:3552
Follow the setup instructions to create your admin account. The default username and password are 'arcane' and 'arcane-admin'. You can now see all your Inception containers (WordPress, NGINX, MariaDB) in a single dashboard.
