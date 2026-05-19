*This project has been created as part of the 42 curriculum by gdosch.*

# Inception

![Score: 125/100](https://img.shields.io/badge/Score-125%2F100-00b4ab?style=for-the-badge&logo=42&logoColor=white)

## Description
The Inception project aims to broaden our knowledge of system administration by using Docker. The goal is to virtualize an entire infrastructure using Docker Compose, creating multiple interacting services within custom containers, all running under a single Debian 12 base image.

This project implements a complete web hosting infrastructure including a Nginx reverse proxy, a MariaDB database, a WordPress site (PHP-FPM) cached by Redis, a static website hosted on Lighttpd, an Adminer database management tool, an FTP server, the Arcane container monitoring tool, and a secure HAProxy socket router.

### Technical Design & Key Features

**Virtual Machines vs Docker**
Virtual Machines (VMs) virtualize the entire hardware stack, requiring a full Guest OS for every instance. Docker utilizes containerization, sharing the host system's kernel and isolating processes. This makes containers incredibly lightweight, fast to boot, and highly scalable compared to VMs.

**Advanced Security & Secrets**
While environment variables are often visible via `docker inspect`, this project utilizes **Docker Secrets**. Sensitive data (passwords, keys) are mounted securely as in-memory files within the containers (inside `/run/secrets/`). Furthermore, each service implements a **Fail-fast validation** mechanism: the startup scripts verify the presence and integrity of both environment variables and secrets before execution.

**Hardened Infrastructure with HAProxy**
To enforce the principle of least privilege, the Docker socket (`/var/run/docker.sock`) is not accessed directly by monitoring tools. Instead, an **HAProxy socket proxy** acts as a security gateway. It uses granular **Access Control Lists (ACLs)** to filter Docker API requests, allowing only safe, read-only, or specific container lifecycle operations while blocking high-risk daemon-level endpoints.

**Robust Persistence & Entrypoints**
All persistent data is stored on the host machine under `/home/gdosch/data/` using Docker named volumes with local bind options. The custom **Entrypoint scripts** are designed to be idempotent and resilient:
* **MariaDB:** Handles one-time initialization with secure bootstrapping.
* **WordPress:** Automatically detects existing installations and dynamically updates URLs and Redis configurations at every boot to ensure consistency with the current `.env`.
* **NGINX:** Dynamically injects configurations and manages SSL certificates based on the current domain name.

## Instructions
For a quick start, navigate to the root of the repository and run:
```bash
make
```
This automated command prepares the host directories, builds the images, and starts all services in the background.

Please refer to the `DEV_DOC.md` and `USER_DOC.md` files for detailed installation and usage instructions.

## Resources
* **Docker Documentation:** https://docs.docker.com/
* **Docker Compose Documentation:** https://docs.docker.com/compose/
* **Docker Secrets:** https://docs.docker.com/engine/swarm/secrets/
* **NGINX Documentation:** https://nginx.org/en/docs/
* **MariaDB Documentation:** https://mariadb.com/kb/en/
* **WordPress CLI:** https://wp-cli.org/
* **Redis Documentation:** https://redis.io/documentation
* **vsftpd Documentation:** https://security.appspot.com/vsftpd.html
* **lighttpd Documentation:** https://redmine.lighttpd.net/projects/lighttpd/wiki/Docs
* **Arcane Documentation:** https://getarcane.app/docs
* **HAProxy Documentation:** https://docs.haproxy.org/
* **Use of AI:** Artificial Intelligence (Google Gemini) was used during this project as a pedagogical assistant. It was primarily utilized to understand complex Docker networking concepts, review the security implementation of Docker Secrets and harden the HAProxy ACL configuration. AI also served as documentation for installing Adminer and creating the HTML for the static website. Finally, it was used to proofread and structure this documentation.
