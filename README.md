*This project has been created as part of the 42 curriculum by gdosch.*

# Inception

## Description
The Inception project aims to broaden our knowledge of system administration by using Docker. The goal is to virtualize an entire infrastructure using Docker Compose, creating multiple interacting services within custom containers, all running under a single Debian 12 base image.

This project implements a complete web hosting infrastructure including a Nginx reverse proxy, a MariaDB database, a WordPress site (PHP-FPM) cached by Redis, a static website hosted on Lighttpd, an Adminer database management tool, an FTP server, the Arcane container monitoring tool, and a secure HAProxy socket router.

### Technical Design & Comparisons

**Virtual Machines vs Docker**
Virtual Machines (VMs) virtualize the entire hardware stack, requiring a full Guest OS for every instance, which consumes significant CPU, RAM, and storage. Docker, on the other hand, utilizes containerization. Containers share the host system's kernel and isolate processes, making them incredibly lightweight, fast to boot, and highly scalable compared to VMs.

**Secrets vs Environment Variables**
Environment variables are often visible in container inspection (`docker inspect`), process lists, or crash dumps, posing a security risk for sensitive data. Docker Secrets are mounted securely as in-memory files within the container (typically in `/run/secrets/`), ensuring that passwords and keys are never exposed in the environment or committed to the image layers.

**Docker Network vs Host Network**
The host network driver binds the container directly to the host's network interfaces, removing network isolation. A custom Docker Bridge Network (like the one used in this project) creates an isolated, internal network for the containers. This provides DNS resolution between containers using their service names and ensures that only explicitly exposed ports can be accessed from the outside world, drastically improving security.

**Docker Volumes vs Bind Mounts**
Bind mounts map a specific file or directory from the host machine directly into a container. They depend heavily on the host's file system structure. Docker Volumes are fully managed by Docker and stored in a specific host directory managed by the Docker daemon. Volumes are safer, easier to back up, and ensure better consistency across different host environments. In this project, we use local driver options to map volumes to a specific path for persistent storage.

## Instructions
For a quick start, navigate to the root of the repository and run:
```bash
make
```

This will build the images and start all services in the background. Please refer to the `DEV_DOC.md` and `USER_DOC.md` files for detailed installation and usage instructions.

## Resources
* **Docker Documentation:** https://docs.docker.com/
* **Docker Compose Documentation:** https://docs.docker.com/compose/
* **Docker Secrets:** https://docs.docker.com/engine/swarm/secrets/
* **NGINX Documentation:** https://nginx.org/en/docs/
* **MariaDB Documentation:** https://mariadb.com/kb/en/
* **WordPress CLI:** https://wp-cli.org/
* **Redis Documentation:** https://redis.io/documentation
* **vsftpd Documentation:** https://security.appspot.com/vsftpd.html
* **Use of AI:** Artificial Intelligence (Google Gemini) was used during this project as a pedagogical assistant. It was primarily utilized to understand complex Docker networking concepts and review the security implementation of Docker Secrets. AI was also used to proofread and structure this documentation.
