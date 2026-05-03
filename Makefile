DATA_PATH = /home/gdosch/data
COMPOSE_FILE = srcs/docker-compose.yml

.PHONY: all build up down mariadb clean fclean re

all: up

# Create local storage directories and build images
build:
	@mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress $(DATA_PATH)/arcane
	docker compose -f $(COMPOSE_FILE) build

# Start containers in detached mode
up: build
	docker compose -f $(COMPOSE_FILE) up -d

# Stop running containers
down:
	docker compose -f $(COMPOSE_FILE) down

# Access the database command line
mariadb:
	docker exec -it mariadb mysql -u root -p

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
