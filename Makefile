COMPOSE_FILE = srcs/docker-compose.yml

all: init
	docker compose -f $(COMPOSE_FILE) up --build

init:
	mkdir -p $(HOME)/data/db
	mkdir -p $(HOME)/data/wordpress

down:
	docker compose -f $(COMPOSE_FILE) down

stop:
	docker compose -f $(COMPOSE_FILE) stop

start:
	docker compose -f $(COMPOSE_FILE) start

build:
	docker compose -f $(COMPOSE_FILE) build

ps:
	docker compose -f $(COMPOSE_FILE) ps

logs:
	docker compose -f $(COMPOSE_FILE) logs

re: clean
	docker compose -f $(COMPOSE_FILE) build --no-cache
	$(MAKE) all

clean: down
	docker rmi -f mariadb:inception wordpress:inception nginx:inception 2>/dev/null || true
	docker volume rm -f srcs_wp-db srcs_wp-files 2>/dev/null || true
	sudo rm -rf $(HOME)/data/db
	sudo rm -rf $(HOME)/data/wordpress

fclean: clean
	docker volume prune -f
	docker network prune -f

.PHONY: all init down stop start build ps logs re clean fclean

# make         -> start working             # build and start everything (containers run in foreground)
# make down    -> finished for today        # stop and remove containers (volumes/images kept)
# make stop    -> go sleep                  # stop containers without removing them
# make start   -> continue working          # start previously stopped containers
# make build   -> prepare everything        # build images only, don't start containers
# make ps      -> check what's alive        # show status of project containers
# make logs    -> investigate problems      # show logs from all containers
# make re      -> start from scratch        # full rebuild from scratch (clean + no-cache build + start)
# make clean   -> wipe project completely   # remove containers, project images, volumes, and host data
# make fclean  -> delete docker junk        # clean + prune all unused Docker volumes/networks system-wide
