# Developer Documentation

This document provides instructions for developers to set up, build, and maintain the Inception project.

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
