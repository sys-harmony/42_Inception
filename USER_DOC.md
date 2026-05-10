# User Documentation

This document explains how to interact with the Inception infrastructure from an end-user or administrator perspective.

## Services Provided
Our stack provides a fully functional web environment consisting of:
* **WordPress:** A dynamic blog platform.
* **MariaDB:** The database engine storing the blog's data.
* **Redis:** An in-memory cache system to speed up WordPress load times.
* **FTP Server:** A secure file transfer protocol to manage website files remotely.
* **Static Website:** A portfolio/status page hosted on Lighttpd.
* **Adminer:** A web-based database management interface.
* **Arcane:** A monitoring tool for Docker containers.
* **HAProxy:** A secure proxy protecting Docker's internal API.

## Managing the Infrastructure
Use the provided `Makefile` commands from the root directory to manage the state of the services:

### Standard Operations
* **Build and Start:** `make` or `make all` (Prepares directories, builds images, and starts containers).
* **Start project:** `make up` (Starts existing containers in the background).
* **Stop project:** `make down` (Stops and removes containers while preserving volumes).
* **Restart project:** `make restart` (Useful for applying configuration changes quickly).

### Maintenance & Cleanup
* **Database Shell:** `make mariadb` (Opens an interactive root terminal inside the database container).
* **Full Rebuild:** `make re` (Performs a complete wipe followed by a fresh start).
* **Deep Clean:** `make fclean` (Removes containers, networks, volumes, and images).
    * **Note:** This command is now **interactive**. It will ask for confirmation before deleting persistent data from your host machine (`/home/gdosch/data/`).

## Accessing the Services
Ensure that your host machine's `/etc/hosts` file maps the domain `gdosch.42.fr` to your Virtual Machine's IP address.

* **Main Website (WordPress):** `https://gdosch.42.fr` (Accept the self-signed SSL certificate warning).
* **WordPress Admin Panel:** `https://gdosch.42.fr/wp-admin` (Log in with your `WP_ADMIN` credentials).
* **FTP Access:** Connect using an FTP client (like FileZilla) to `gdosch.42.fr` on port `21`.
* **Static Website:** `http://gdosch.42.fr:8081`
* **Adminer (Database Admin):** `http://gdosch.42.fr:8080`
* **Arcane (Monitoring):** `http://gdosch.42.fr:3552`

## Managing Credentials
For security, credentials are not stored in the repository.
* **Secrets:** Located in the `secrets/` directory on the host.
* **Environment:** Located in the `srcs/.env` file.

**To update a password:**
1. Stop the project: `make down`.
2. Update the `.txt` file in the `secrets/` directory.
3. Restart the project: `make up`.

## Checking Service Health
Each service in this infrastructure is equipped with **Healthchecks**. You can verify their status with:

1. **Detailed Status:** Run `docker compose ps`. Services should show as `Up` and `healthy`.
2. **Logs:** Run `docker logs <service_name>` to troubleshoot initialization or runtime errors.
3. **Real-time Monitoring:** Access the **Arcane** dashboard at `http://gdosch.42.fr:3552`.
4. **Proxy Audit:** To see Docker API requests being filtered, run `docker logs -f haproxy`.
