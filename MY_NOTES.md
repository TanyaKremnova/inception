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