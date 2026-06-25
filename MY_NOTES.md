# Inception — Personal Notes

Reference notes collected while building this project. Organized by topic for quick lookup.

---

## 1. SSH Access to the VM

### Connect

```bash
ssh tkremnov@127.0.0.1 -p 4242
```

| Part | Meaning |
|---|---|
| `ssh` | SSH client, used to log into a remote machine securely |
| `tkremnov` | Username on the remote machine (the VM) |
| `@127.0.0.1` | Remote host IP — `127.0.0.1` is localhost, used here via port forwarding |
| `-p 4242` | Port to connect to. Default SSH port is 22; VirtualBox forwards host port 4242 → guest port 22 |

### Disconnect

```bash
exit
```
or
```bash
logout
```

If you used `newgrp docker`, you may need `exit` twice:
- 1st `exit` → leaves the `docker` group shell
- 2nd `exit` → leaves the SSH session

---

## 2. Docker Basics

### Check versions

```bash
docker --version
docker compose version
```

### Run a test container

```bash
sudo docker run --rm hello-world
```

| Flag | Meaning |
|---|---|
| `sudo` | Run as superuser (needed if your user isn't in the `docker` group) |
| `run` | Create and run a new container from an image |
| `--rm` | Auto-remove the container when it exits |
| `hello-world` | Image to pull and run |

### Add your user to the docker group (avoid needing sudo)

```bash
sudo usermod -aG docker tkremnov
```
- `-a` = append, `-G docker` = add to the `docker` group without removing existing groups

Apply the new group without logging out:
```bash
newgrp docker
```
Then test:
```bash
docker run --rm hello-world
```

---

## 3. Architecture — Mental Model of the Stack

### Overall request flow

```
Browser → NGINX (443) → WordPress+php-fpm (9000) → MariaDB (3306)
```

### MariaDB startup sequence

```
docker compose up
      │
      ▼
  init.sh runs
      │
      ├── First run? → mysql_install_db → bootstrap SQL → create DB + users
      │
      └── exec mysqld  ← becomes PID 1, MariaDB is now running
```

### WordPress startup sequence

```
docker compose up
       │
       ▼
  WordPress container starts
       │
       ├── wp-config.php exists?
       │        │
       │      NO → download WP → create config → wait for DB
       │                → wp core install → create users
       │        │
       │      YES → skip all setup
       │
       └── exec php-fpm --nodaemonize  ← PID 1, listens on :9000
                                              ▲
                              NGINX sends FastCGI requests here
```

### NGINX request routing

```
Internet
    │
    │  HTTPS port 443 (TLS 1.2/1.3)
    ▼
 NGINX container
    │
    ├── Static files (CSS, JS, images) → serves directly from wp-files volume
    │
    └── PHP files → forwards to WordPress:9000 via FastCGI
```

### Full request lifecycle (detailed)

```
Browser: https://yourlogin.42.fr
         │
         │ TCP:443
         ▼
    NGINX container
         │
         ├── Is it a static file? (jpg, css, js)
         │       └── YES → serve directly from wp-files volume → done
         │
         └── Is it a .php file? (or falls through to index.php)
                 │
                 │ FastCGI protocol, TCP:9000
                 ▼
         WordPress+php-fpm container
                 │
                 │ executes PHP, queries DB if needed
                 │ TCP:3306
                 ▼
         MariaDB container
                 │
                 └── returns data → php builds HTML → back to NGINX → back to browser
```

---

## 4. Useful Commands — Setup & Debugging

### Clean and restart everything

```bash
docker compose down
docker system prune -af
docker compose up --build
```

### Create `.env` directly on the VM

```bash
cat > ~/inception/srcs/.env << 'EOF'
DOMAIN_NAME=tkremnov.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_ADMIN_USER=wpmaster
DB_PASSWORD=somepassword
DB_ROOT_PASSWORD=somerootpassword
EOF
```

### Inspect MariaDB users/databases directly

```bash
docker exec -it mariadb mariadb -u root -p
# use DB_ROOT_PASSWORD from .env

# then inside MariaDB:
SELECT User, Host FROM mysql.user;
SHOW DATABASES;
```

### Create host data directories (for named volumes)

```bash
mkdir -p ~/data/db ~/data/wordpress
```

### Add domain to `/etc/hosts` on the VM

```bash
echo "127.0.0.1 tkremnov.42.fr" | sudo tee -a /etc/hosts
```

### Power off the VM cleanly

```bash
sudo poweroff
```

### Check NGINX is actually listening on 443 inside the container

```bash
docker exec -it nginx ss -tlnp | grep 443
# or
docker exec nginx nginx -T | grep listen
```

### Confirm what WordPress thinks its own URL is

```bash
docker exec wordpress wp option get home --allow-root
docker exec wordpress wp option get siteurl --allow-root
# Expected: https://tkremnov.42.fr:8443
```

---

## 5. Local Browser Access

If workstations don't allow non-root binding to port 443, and `/etc/hosts` can't be edited without sudo locally, use VirtualBox port forwarding and browser host mapping.

### Update WordPress URLs

WordPress stores its own URL in the database. When using VirtualBox port forwarding (`8443 → 443`), update the stored URLs:

```bash
docker exec wordpress wp option update siteurl 'https://tkremnov.42.fr:8443' --path=/var/www/html --allow-root
docker exec wordpress wp option update home 'https://tkremnov.42.fr:8443' --path=/var/www/html --allow-root
```

Verify:
```bash
docker exec wordpress wp option get home --path=/var/www/html --allow-root
docker exec wordpress wp option get siteurl --path=/var/www/html --allow-root
```

### Open browser with manual domain resolution

Using curl:
```bash
curl -k --resolve tkremnov.42.fr:8443:127.0.0.1 https://tkremnov.42.fr:8443 | head
```

Chrome:

```bash
pkill chrome
google-chrome \
  --host-resolver-rules="MAP tkremnov.42.fr 127.0.0.1" \
  --ignore-certificate-errors \
  --log-level=3 \
  https://tkremnov.42.fr:8443
```

or with Chromium:

```bash
chromium \
  --host-resolver-rules="MAP tkremnov.42.fr 127.0.0.1" \
  --ignore-certificate-errors \
  --log-level=3 \
  https://tkremnov.42.fr:8443
```

The browser flag makes Chrome/Chromium resolve tkremnov.42.fr to 127.0.0.1.

### Change Port

```bash
nano srcs/requirements/mariadb/conf/my.cnf
# Change:
# port = 3306 -> port = 3307

nano srcs/requirements/mariadb/Dockerfile
# Change:
# EXPOSE 3306 -> EXPOSE 3307

nano srcs/requirements/wordpress/tools/init.sh
# Change:
# --dbhost="mariadb:3306" -> --dbhost="mariadb:3307"

# Also update the health check:
# mysqladmin ping -h mariadb -P 3307
```
**Rebuild and restart the stack**
```bash
make clean
make
```
**Verification**  
```bash
# Check MariaDB is listening on the new port:
docker exec mariadb ss -tlnp
# Expected:
# 0.0.0.0:3307

# Check WordPress connection:
docker logs wordpress
# Look for:
# - `mysqld is alive`
# - `Success: WordPress installed successfully`

# Check DB host inside WP config:
docker exec wordpress grep DB_HOST /var/www/html/wp-config.php
# Expected:
# define( 'DB_HOST', 'mariadb:3307' );

docker exec wordpress wp db check --allow-root
# Expected:
# Success: Database checked.
```
---

## 6. Verification Checklist (Manual Test Flow)

1. **Log in as admin (`wpmaster`)**
   ```
   https://tkremnov.42.fr/wp-admin/
   ```
   Username: `wpmaster`, Password: from `.env` (`DB_PASSWORD`)

2. **Create/edit a post**
   Posts → Add New → write something → Publish

3. **Log out**
   Top right → your name → Log Out

4. **Log in as regular user (`wpuser`)**
   Same login page, username `wpuser`, same password

5. **Show a simple action as regular user**
   Since `wpuser` has the `author` role, they can:
   - View their dashboard
   - Edit their own profile (Users → Profile)
   - Create a draft post

   They **cannot** publish others' posts or manage plugins/themes — correct, admin-only behavior to point out during defense.

---

## 7. Networking, Docker, and VMs — Concepts

### Why ports 0–1023 are special (privileged ports)

Examples:

| Port | Service |
|---|---|
| 22 | SSH |
| 25 | SMTP |
| 80 | HTTP |
| 443 | HTTPS |

Only root-owned processes can normally bind to these. Without this restriction, any unprivileged user on a shared server could start a fake SSH server on port 22 and steal credentials.

```bash
python3 -m http.server 80      # Permission denied (non-root)
sudo python3 -m http.server 80 # Works
```

### Why NGINX can use port 443 inside Docker

The container's main process typically starts as root:
1. Starts as root
2. Opens port 443
3. Creates worker processes
4. Drops privileges to `www-data`

This is why `listen 443 ssl;` works even though NGINX *workers* run as `www-data`, not root.

### Why the subject wants port 443 specifically

HTTPS conventionally runs on 443. The subject expects NGINX to behave like a real-world HTTPS server:
```nginx
listen 443 ssl;
```

### What Docker actually is

Containers are **not** virtual machines — they share the host's Linux kernel:

```
Host Linux Kernel
├── Container A
├── Container B
└── Container C
```

This makes them lightweight, fast to start, and low on memory overhead compared to a full VM.

### Docker disk usage

Docker stores images, containers, volumes, networks, and logs — typically under `/var/lib/docker`.

```bash
docker system df
```
```
Images      2.5GB
Containers  300MB
Volumes     1.2GB
```

### What Docker volumes solve

Without a volume: `Container deleted → Data deleted`
With a volume: `Container deleted → Data survives`

In this project: WordPress files and MariaDB data both live in named volumes, so data survives container rebuilds.

### What a Virtual Machine actually is

A complete computer running inside another computer:
```
Host Computer
└── VirtualBox
    └── Debian VM
```
The VM has its own OS, users, processes, filesystem, and networking — it behaves like a real machine from the OS's perspective.

### VM disk and RAM usage

- **Disk:** VirtualBox creates a virtual disk file (e.g. `debian.vdi`) holding the entire VM — OS, Docker, images, containers, databases, logs. Deleting Docker containers doesn't touch the VM; deleting the VM removes everything inside it.
- **RAM:** Allocated RAM (e.g. 4GB) is reserved from the host while the VM runs, and returned when powered off.

### Port availability inside the VM

The VM is a separate machine — all ports `0–65535` exist independently inside it (22 SSH, 443 HTTPS, 3306 MariaDB, 9000 PHP-FPM, etc.), regardless of what's happening on the host.

### Why the host can't automatically reach VM ports

VirtualBox sits between host and guest:
```
Host Computer
      |
VirtualBox
      |
Guest VM
```
The VM is isolated; VirtualBox decides which ports are exposed to the host via explicit port-forwarding rules.

### What "Host 8443 → Guest 443" means

```
Browser
    |
localhost:8443
    |
VirtualBox NAT
    |
VM:443
```
Connecting to `https://localhost:8443` gets forwarded by VirtualBox to port 443 inside the VM, where NGINX is listening.

### Why not just use Host 443 → Guest 443?

You can, if available — but on Codam machines port 443 typically requires root to bind, and may already be in use. Using a higher port (e.g. 8443) on the host side avoids permission issues entirely; this is a common local-development pattern.

### Docker's own port mapping (inside the VM)

```bash
docker ps
# 0.0.0.0:8443->443/tcp
```
Meaning: VM port 8443 → Container port 443. Docker receives traffic on the VM's port and forwards it into the container.

### Full traffic path in this project

```
Chrome/Chromium (Host)
      |
      | https://tkremnov.42.fr:8443
      | (mapped to 127.0.0.1 by Chrome)
      V
Host machine
      |
      | VirtualBox NAT:
      | Host:8443 -> Guest 443
      V
Debian VM
      |
      | Docker:
      | VM port 443 -> nginx container port 443
      V
NGINX Container
      |
      | fastcgi_pass wordpress:9000
      V
WordPress Container
      |
      | mariadb:3306
      V
MariaDB Container
```

### Explanation

**Browser**

You type:
```bash
https://tkremnov.42.fr:8443
```
Chrome is told:
```bash
tkremnov.42.fr = 127.0.0.1
```
so it actually sends traffic to your own machine.

**VirtualBox NAT**

VirtualBox has a rule:
```text
Host: 8443 -> Guest: 443
```

Meaning:
```text
Host receives request on port 8443
            ↓
Forwards it to VM port 443
```

**Debian VM**

The VM receives HTTPS traffic on:
```text
443
```
Docker Compose exposes:
```text
ports:
  - "443:443"
```
Meaning:
```text
VM port 443
      ↓
NGINX container port 443
```

**Key takeaway:** NGINX only ever sees the final destination port (443) after all forwarding layers translate it — it has no idea the original browser request came in on a different port. This is exactly why `HTTP_HOST`/`siteurl`/`home` must be set to match the *externally visible* port, not whatever `$server_port` reports inside the container.

---
---
---
# Eval:

## Reset everything before testing, exactly as eval will:
```bash
docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker network rm $(docker network ls -q) 2>/dev/null
```

## Check Dockerfiles for forbidden patterns:
```bash
cat srcs/requirements/*/Dockerfile | grep ENTRYPOINT
# must point to the init.sh scripts, not "bash" or "sh" alone
```

## Check current Debian stable name
```bash
# on the VM
cat /etc/os-release
```

## Simple setup
```bash
docker compose -f srcs/docker-compose.yml ps
# all 3 containers Up

curl -k https://tkremnov.42.fr # WordPress HTML
curl http://tkremnov.42.fr     # fail/refuse connection
```

## Docker Basics
```bash
docker compose -f srcs/docker-compose.yml config | grep "image:"

# Each image name must match its service name exactly:
image: mariadb:inception
image: wordpress:inception
image: nginx:inception
```

## Docker Network
```bash
grep -A 3 "^networks:" srcs/docker-compose.yml
docker network ls
# NETWORK ID     NAME             DRIVER    SCOPE
# 25dcb0f8ab52   bridge           bridge    local
# d9c71fbd8d87   host             host      local
# 22c669c0a1b4   none             null      local
# 3ea4748445d0   srcs_inception   bridge    local
```

## NGINX with SSL/TLS
```bash
# TLS version
openssl s_client -connect tkremnov.42.fr:443 -tls1_2 < /dev/null 2>&1 | grep -i "protocol\|cipher"
openssl s_client -connect tkremnov.42.fr:443 -tls1_3 < /dev/null 2>&1 | grep -i "protocol\|cipher"
openssl s_client -connect tkremnov.42.fr:443 -tls1_1 < /dev/null 2>&1 | grep -i "error\|alert"
# tls1.1 attempt MUST fail
```

## WordPress
```bash
# Admin login + page edit test:
chromium \
  --host-resolver-rules="MAP tkremnov.42.fr 127.0.0.1" \
  --ignore-certificate-errors \
  --log-level=3 \
  https://tkremnov.42.fr:8443
```

## MariaDB
```bash
# DB login:
docker exec -it mariadb mariadb -u root -p
# enter DB_ROOT_PASSWORD when prompted

SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT user_login, user_email FROM wp_users;
```

## Persistence
```bash
make down
sudo reboot

make

# verify:
make ps
curl -k https://tkremnov.42.fr
```