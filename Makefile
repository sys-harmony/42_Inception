DATA_PATH = /home/gdosch/data
COMPOSE_FILE = srcs/docker-compose.yml

.PHONY: all build up down clean fclean re

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

mariadb:
	docker exec -it mariadb mysql -u root -p

# Remove containers and networks
clean: down
	@docker system prune -f

# Full cleanup: removes all images, volumes, docker cache, AND data directories
fclean: 
	docker compose -f $(COMPOSE_FILE) down -v --rmi all
	@docker system prune -af
	@sudo rm -rf $(DATA_PATH)

# Complete rebuild from scratch
re: fclean all
