## SSH – Connect to your Debian VM
```bash
ssh tkremnov@127.0.0.1 -p 4242
```

- `ssh` – SSH client, used to log into a remote machine securely.
- `tkremnov` – The user name on the remote machine (your Debian VM).
- `@127.0.0.1` – The remote host IP. `127.0.0.1` is your local machine (localhost), because you’re using port forwarding.
- `-p 4242` – `-p` specifies the port to connect to.
  - Default SSH port is 22.
  - You configured VirtualBox to forward port `4242` on your host to port `22` (SSH) on the VM.

This command opens an SSH session to your Debian VM and asks for the password.

## Exit / Logout from SSH or shell
```bash
exit
```

If you used `newgrp docker`, you might need to run `exit` twice:
- First `exit` → leaves the `docker` group shell.
- Second `exit` → leaves the SSH session.

```bash
logout
```
- Same as `exit`, but explicitly means “end this login session”.
- Works in login shells (like an SSH session).

## Docker

```bash
docker --version
docker compose version
```

### Docker – Run a container
```bash
sudo docker run --rm hello-world
```

- `sudo` – Run as superuser (needed if your user is not in the docker group).
- `docker` – Docker CLI.
- `run` – Create and run a new container from an image.
- `--rm` – Automatically remove the container when it exits (no leftover stopped containers).
- `hello-world` – The image name to pull from Docker Hub and run.

### Group management – Add user to docker group

```bash
sudo usermod -aG docker tkremnov
```

- `sudo` – Run as root.
- `usermod` – Modify a user account.
- `-aG docker` – `-a` = append, `-G` = add to a
**group**
- .Adds `tkremnov` to the `docker` group without removing them from other groups.

After this, you still need to refresh your group membership (log out/in or use `newgrp docker`).

```bash
newgrp docker
```

Starts a new shell with the docker group as an active group.  
Allows you to run docker commands without sudo in that shell.

```bash
docker run --rm hello-world
```

## Quick mental model of the whole flow

Browser → NGINX (443) → WordPress+php-fpm (9000) → MariaDB (3306)

```bash
docker compose up
      │
      ▼
  init.sh runs
      │
      ├── First run? → mysql_install_db → bootstrap SQL → create DB + users
      │
      └── exec mysqld  ← becomes PID 1, MariaDB is now running
```

```bash
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

```bash
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

```bash
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

## Clean and restart

```bash
docker compose down
docker system prune -af
docker compose up --build
```


## Inside MariaDB:
```bash
SELECT User, Host FROM mysql.user;
SHOW DATABASES;
```

## Create the .env inside the VM

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

### Create the data directories on the VM:
```bash
mkdir -p ~/data/db ~/data/wordpress
```

### Add your domain to /etc/hosts on the VM
```bash
echo "127.0.0.1 tkremnov.42.fr" | sudo tee -a /etc/hosts
```

### Shut down the VM
```bash
# On the VM
sudo poweroff
```

### Use local browser to rich the web page
```bash
pkill chrome

google-chrome \
  --host-resolver-rules="MAP tkremnov.42.fr 127.0.0.1" \
  --ignore-certificate-errors \
  --log-level=3 \
  https://tkremnov.42.fr:8443

# or

chromium \
  --host-resolver-rules="MAP tkremnov.42.fr 127.0.0.1" \
  --ignore-certificate-errors \
  --log-level=3 \
  https://tkremnov.42.fr:8443
```

### Check if NGINX is actually listening on 443 inside the container
```bash
docker exec -it nginx ss -tlnp | grep 443

# and/or

docker exec nginx nginx -T | grep listen
```

### Confirm what WordPress thinks its URL is
```bash
docker exec wordpress wp option get home --allow-root
docker exec wordpress wp option get siteurl --allow-root

# Expected:
# https://tkremnov.42.fr:8443
```

### Change the port
```bash
cd /home/tkremnov/inception/srcs   # inside the VM

docker exec wordpress wp option update siteurl 'https://tkremnov.42.fr:8443' --path=/var/www/html --allow-root
docker exec wordpress wp option update home 'https://tkremnov.42.fr:8443' --path=/var/www/html --allow-root
```


```notes
Change port commands WP:
Enter WordPress container.
Go to the root folder of WP.
nginx
-change  nginx config
-change YML
-nginx docker file
-update wordpress URL port
wp --path=/var/www/html option get home --allow-root
wp --path=/var/www/html option get siteurl --allow-root

wp --path=/var/www/html option update home 'https://ipavlov.42.fr:4443' --allow-root
wp --path=/var/www/html option update siteurl 'https://ipavlov.42.fr:4443' --allow-root

Nginx-wordpress
-change nginx default.config - location
-change wordpress - RUN
Check:
Docker exec -it wordpress grep “listen =” /etc/php/7.4/fpm/pool.d/www.conf



Wordpress-mariadb
-add port = XXX in 50-server.cnf
-change setup.sh in wordpress
- until mysql -h mariadb -P XXXX and
- set -i “s/localhost/mariadb:5555/”
- comment out the if statement fi
```

# Verification checklist

1. **Log in as admin (`wpmaster`)**

```bash
https://tkremnov.42.fr/wp-admin/
```
Username: `wpmaster`, Password: `somepassword` (from the `.env`)

2. **Create/edit a post**
Posts → Add New → write something → Publish

3. **Log out**
Top right → your name → Log Out

4. **Log in as regular user (`wpuser`)**
Same login page, username `wpuser`, same password (since you used `${DB_PASSWORD}` for both)

5. **Show a simple action as regular user**
Since `wpuser` has the `author` role (set in your init.sh), they can:

View their dashboard
Edit their own profile (Users → Profile)
Create a draft post (but can't publish others' posts or manage plugins/themes — that's admin-only, which is the correct behavior to demonstrate during defense)



---
---
---
---
---

# Networking, Docker, Virtual Machines, and Ports

## Why are ports 0-1023 special?

Ports **0-1023** are called **privileged ports**.

Examples:

| Port | Service |
| ---- | ------- |
| 22   | SSH     |
| 25   | SMTP    |
| 80   | HTTP    |
| 443  | HTTPS   |

Historically, only processes running as **root** are allowed to bind to these ports.

Example:

```bash
python3 -m http.server 80
```

Normal user:

```text
Permission denied
```

Root:

```bash
sudo python3 -m http.server 80
```

Works.

### Why?

Imagine a multi-user server.

Without this restriction, any user could start a fake SSH server on port 22 and steal credentials.

The privileged-port rule helps prevent this.

---

# Why can NGINX use port 443 inside Docker?

When a container starts, its main process usually starts as root.

NGINX:

1. Starts as root
2. Opens port 443
3. Creates worker processes
4. Drops privileges to `www-data`

This is why the following works:

```nginx
listen 443 ssl;
```

even though NGINX workers are not running as root.

---

# Why does the Inception subject want port 443?

HTTPS normally runs on:

```text
443
```

The subject expects NGINX to serve HTTPS using TLS.

Typical configuration:

```nginx
listen 443 ssl;
```

Inside the container, NGINX should behave like a real HTTPS server.

---

# What is Docker?

Docker containers are **not virtual machines**.

Containers share the host's Linux kernel.

Simplified:

```text
Host Linux Kernel
├── Container A
├── Container B
└── Container C
```

All containers use the same kernel.

This makes containers:

* lightweight
* fast to start
* low memory usage

---

# Does Docker use disk space?

Yes.

Docker stores:

* Images
* Containers
* Volumes
* Networks
* Logs

Usually under:

```text
/var/lib/docker
```

Check usage:

```bash
docker system df
```

Example:

```text
Images      2.5GB
Containers  300MB
Volumes     1.2GB
```

---

# What are Docker volumes?

Volumes provide persistent storage.

Without a volume:

```text
Container deleted
↓
Data deleted
```

With a volume:

```text
Container deleted
↓
Data survives
```

In Inception:

* WordPress files are stored in a volume
* MariaDB data is stored in a volume

This allows data to survive container rebuilds.

---

# What is a Virtual Machine?

A VM is a complete computer running inside another computer.

Example:

```text
Host Computer
└── VirtualBox
    └── Debian VM
```

The VM has:

* Its own operating system
* Its own users
* Its own processes
* Its own filesystem
* Its own networking

From the operating system's perspective, it behaves like a real machine.

---

# Does a VM use disk space?

Yes.

VirtualBox creates a virtual disk file.

Example:

```text
debian.vdi
```

This file contains:

* Debian
* Docker
* Images
* Containers
* Databases
* Logs
* Everything stored inside the VM

Deleting Docker containers does not remove the VM.

Deleting the VM removes everything inside it.

---

# Does a VM use RAM?

Yes.

If VirtualBox allocates:

```text
4 GB RAM
```

Then while the VM is running:

```text
Host RAM
↓
4 GB reserved for VM
```

When the VM is powered off:

```text
RAM returns to the host
```

---

# Does the VM have all ports?

Yes.

The VM is a separate computer.

Inside the VM:

```text
0 - 65535
```

all ports exist.

Examples:

```text
22    SSH
443   HTTPS
3306  MariaDB
9000  PHP-FPM
```

The VM can use these ports independently from the host.

---

# Why can't the host automatically access VM ports?

Because VirtualBox sits between them.

Architecture:

```text
Host Computer
      |
VirtualBox
      |
Guest VM
```

The VM is isolated.

VirtualBox decides which ports are exposed to the host.

---

# What does "Host 8443 → Guest 443" mean?

Example VirtualBox rule:

```text
Host Port: 8443
Guest Port: 443
```

Traffic flow:

```text
Browser
    |
localhost:8443
    |
VirtualBox NAT
    |
VM:443
```

When the browser connects to:

```text
https://localhost:8443
```

VirtualBox forwards traffic to:

```text
VM port 443
```

where NGINX is listening.

---

# Why not use Host 443 → Guest 443?

You can.

Example:

```text
Host 443
↓
Guest 443
```

However:

* Port 443 may already be used on the host
* Low ports sometimes require extra permissions
* Using 8443 avoids conflicts

Many developers use:

```text
Host:8443
Guest:443
```

for local development.

---

# Docker port mapping

Inside the VM you also have Docker port forwarding.

Example:

```bash
docker ps
```

shows:

```text
0.0.0.0:8443->443/tcp
```

Meaning:

```text
VM Port 8443
      ↓
Container Port 443
```

Docker receives traffic on VM port 8443 and forwards it into the container.

---

# Complete traffic path in Inception

Current setup:

```text
Chrome (Host)
      |
      | https://localhost:8443
      |
      V
VirtualBox NAT
      |
      | Host:8443 -> VM:8443
      |
      V
Debian VM
      |
      | Docker mapping
      | 8443 -> 443
      |
      V
NGINX Container
      |
      | fastcgi_pass wordpress:9000
      |
      V
WordPress Container
      |
      V
MariaDB Container
```

---

# Important conclusion

The port you type in the browser is not necessarily the port NGINX listens on.

Example:

Browser:

```text
https://tkremnov.42.fr:8443
```

NGINX:

```nginx
listen 443 ssl;
```

Both are correct because forwarding layers translate:

```text
8443
↓
8443 (VM)
↓
443 (Container)
```

NGINX only sees the final destination:

```text
443
```

and has no idea that the original request came through port 8443.


---
---
---
---
---

# Change NGINX external port (example: 8443 -> 4443)

1. VirtualBox  
   Host Port  : 4443  
   Guest Port : 443

2. docker-compose.yml
```text
   nginx:
     ports:
       - "443:443"
```

(Usually NO change needed here because nginx still listens on 443 inside the container.)

3. nginx.conf  
   If HTTP_HOST is hardcoded:  
     `fastcgi_param HTTP_HOST tkremnov.42.fr:4443;`

4. Restart containers  
   `docker compose down`  
   `docker compose up -d --build`

5. Update WordPress URLs

   From host:
```bash
docker exec wordpress wp option update home \
'https://tkremnov.42.fr:4443' \
--path=/var/www/html --allow-root

docker exec wordpress wp option update siteurl \
'https://tkremnov.42.fr:4443' \
--path=/var/www/html --allow-root
```

6. Verify
```bash
docker exec wordpress wp option get home \
--path=/var/www/html --allow-root

docker exec wordpress wp option get siteurl \
--path=/var/www/html --allow-root
```

7. Open browser

```bash
chromium \
--host-resolver-rules="MAP tkremnov.42.fr 127.0.0.1" \
--ignore-certificate-errors \
--log-level=3 \
https://tkremnov.42.fr:4443/
```
