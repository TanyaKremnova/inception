COMPOSE_FILE = srcs/docker-compose.yml

all: init
	docker compose -f $(COMPOSE_FILE) up --build

init:
	mkdir -p /home/tkremnov/data/db
	mkdir -p /home/tkremnov/data/wordpress

down:
	docker compose -f $(COMPOSE_FILE) down

stop:
	docker compose -f $(COMPOSE_FILE) stop

build:
	docker compose -f $(COMPOSE_FILE) build

ps:
	docker compose -f $(COMPOSE_FILE) ps

logs:
	docker compose -f $(COMPOSE_FILE) logs

re: clean all

clean: down
	docker system prune -af
	docker volume rm -f srcs_wp-db srcs_wp-files 2>/dev/null || true
	sudo rm -rf /home/tkremnov/data/db
	sudo rm -rf /home/tkremnov/data/wordpress

fclean: clean
	docker volume prune -f
	docker network prune -f

.PHONY: all init down stop build ps logs re clean fclean

# make        # builds and starts everything
# make down   # stop and remove containers
# make re     # full rebuild from scratch
# make clean  # remove containers + images + data
