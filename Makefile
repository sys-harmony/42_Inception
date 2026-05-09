DATA_PATH = /home/gdosch/data
COMPOSE_FILE = srcs/docker-compose.yml

.PHONY: all build up down mariadb clean fclean re

all: up

# Create local storage directories and build images
build:
	@mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress $(DATA_PATH)/arcane
	docker compose -f $(COMPOSE_FILE) build

# Start the containers
up: build
    # -d : Detached mode. Run containers in the background and return control to the terminal.
	docker compose -f $(COMPOSE_FILE) up -d

# Stop the containers
down:
	docker compose -f $(COMPOSE_FILE) down

# Restart the containers (useful to apply new .env configurations)
restart: down up

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

# Complete rebuild from scratch
re: fclean all
