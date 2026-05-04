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

## Starting and Stopping the Project
To manage the state of the infrastructure, use the provided Makefile commands from the root directory:
* **Start the project:** `make up`
* **Stop the project:** `make down`
* **Stop and wipe all data:** `make fclean` (Warning: This deletes all databases and website files!)

## Accessing the Services
Ensure that your host machine's `/etc/hosts` file maps the domain `gdosch.42.fr` to your Virtual Machine's IP address.
* **Main Website (WordPress):** `https://gdosch.42.fr` (Accept the self-signed SSL certificate warning).
* **WordPress Admin Panel:** `https://gdosch.42.fr/wp-admin` (Log in with your WP_ADMIN credentials).
* **FTP Access:** Connect using an FTP client (like FileZilla) to `gdosch.42.fr` on port `21`.
* **Static Website:** `http://gdosch.42.fr:8081`
* **Adminer (Database Admin):** `http://gdosch.42.fr:8080`
* **Arcane (Monitoring):** `http://gdosch.42.fr:3552`

## Managing Credentials
Credentials are not stored in the repository for security reasons. Administrators must provide them locally.
* **Database & Site Passwords:** Located in the `secrets/` directory on the host machine.
* **Environment Variables:** Located in the `srcs/.env` file.
To change a password, you must stop the project (`make down`), update the respective `.txt` file in the `secrets/` directory, and restart the project.

## Checking Service Health
To verify that all services are running correctly:
1. Open a terminal on the host machine.
2. Run `docker ps` to see the status of all containers. Ensure none are marked as "restarting" or "exited".
3. To view the logs of a specific service, run `docker logs <service_name>`.
4. Graphical Monitoring (Arcane): Access the dashboard at `http://gdosch.42.fr:3552` and log in using the credentials provided by the administrator.
