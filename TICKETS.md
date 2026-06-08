# 🏗️ Setup & Infrastructure
## TICKET-01 — VM & Directory Structure

- Create the VM (Debian recommended — see note below)
- Create root `Makefile`, `srcs/` folder, `srcs/.env`, `srcs/docker-compose.yml`
- Create `secrets/` folder with `db_password.txt`, `db_root_password.txt`, `credentials.txt`
- Add `.gitignore` to exclude secrets and `.env`

## TICKET-02 — Docker Network

- Define a custom bridge network in `docker-compose.yml`
- No `host`, `--link`, or `links:` allowed

---

# 🐳 Container: MariaDB
## TICKET-03 — MariaDB Dockerfile & config

- Base image: `debian:bookworm` (penultimate stable = bookworm)
- Write entrypoint script to initialize DB, create users, set passwords from secrets
- Two DB users: one admin (username must NOT contain "admin/Admin/administrator")
- No passwords in Dockerfile — use `.env` + secrets
- Bind volume `wp-db` → `/var/lib/mysql`
- `restart: on-failure` (or `unless-stopped`)

---

# 🐘 Container: WordPress + php-fpm
## TICKET-04 — WordPress Dockerfile & config

- Base image: `debian:bookworm`
- Install `php-fpm`, `php-mysql`, `wget/curl`, `wp-cli`
- Configure `www.conf` to listen on `9000`
- Use entrypoint script with wp-cli to auto-configure WP (DB connection, users)
- No nginx inside this container
- Bind volume `wp-files` → `/var/www/html`
- `restart: on-failure`
- Depends on `mariadb`

---

# 🌐 Container: NGINX
## TICKET-05 — NGINX Dockerfile & config

- Base image: `debian:bookworm`
- Install `nginx`, `openssl`
- Generate self-signed TLS cert at build time (or via entrypoint)
- `nginx.conf` — TLSv1.2/1.3 only, port 443 only, proxy_pass to wordpress:9000
- Bind volume `wp-files` → `/var/www/html` (shared read with WP container)
- `restart: on-failure`
- Expose port `443` only — this is the sole entrypoint

---

# 🔗 Volumes & Compose wiring
## TICKET-06 — Named volumes

- `wp-db` and `wp-files` as Docker named volumes
- Both must map to `/home/<login>/data/` on the host via the volume driver options
- No bind mounts for these two

## TICKET-07 — docker-compose.yml

- Wire all 3 services, network, volumes
- Pass secrets via Docker secrets or env_file
- `image:` name must match service name
- No `latest` tags anywhere
- Makefile calls `docker compose up --build`

---

# 🌍 Domain & TLS
## TICKET-08 — Domain name

- Edit `/etc/hosts` on the VM: `127.0.0.1 <login>.42.fr`
- NGINX cert CN should match `<login>.42.fr`

---

# 📄 Documentation (mandatory for validation)
## TICKET-09 — README.md

- Italicized first line crediting 42 curriculum
- Description, Instructions, Resources + AI usage
- Project description comparing: VM vs Docker, Secrets vs Env vars, Docker Network vs Host Network, Docker Volumes vs Bind Mounts

## TICKET-10 — USER_DOC.md

- How to start/stop, access the site and wp-admin, find credentials, check service health

## TICKET-11 — DEV_DOC.md

- From-scratch setup, build & launch via Makefile, container management commands, data persistence explanation

---

# 🎁 Bonus

| Bonus         | Effort        | Notes |
| ------------- |---------------| -----|
| Adminer       | ⭐ Very easy | Single container, tiny image, just expose a port |
| Static website| ⭐ Easy      | Nginx serving plain HTML/CSS — no PHP |
| Redis cache   | ⭐⭐ Medium   | WP redis plugin + Redis container, needs WP config |
| FTP server    | ⭐⭐ Medium   | vsftpd pointing to wp-files volume |
| Custom service| ⭐⭐⭐ Varies | Your call — a monitoring page (e.g. netdata) is a solid justifiable choice |
