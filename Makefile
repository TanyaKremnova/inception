COMPOSE_FILE = srcs/docker-compose.yml

all:
	mkdir -p ~/data/db ~/data/wordpress
	docker compose -f $(COMPOSE_FILE) up --build

down:
	docker compose -f $(COMPOSE_FILE) down

build:
	docker compose -f $(COMPOSE_FILE) build

ps:
	docker compose -f $(COMPOSE_FILE) ps

logs:
	docker compose -f $(COMPOSE_FILE) logs

clean: down
	docker system prune -af
	sudo rm -rf ~/data/db ~/data/wordpress

re: clean all