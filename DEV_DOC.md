# Developer Documentation

## Prerequisites

Required software:

- Docker
- Docker Compose
- GNU Make

Verify installation:

```bash
docker --version
docker compose version
make --version
```

## Initial Setup

Clone repository:

```bash
git clone <repository-url>
cd inception
```

Create configuration:

```bash
srcs/.env
```

## Secrets and Environment Variables

This project uses a `.env` file (mandatory per project requirements) to store all configuration, including database credentials:

```bash
srcs/.env
```

Example variables:
```bash
DOMAIN_NAME=tkremnov.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_ADMIN_USER=wpmaster
DB_PASSWORD=somepassword
DB_ROOT_PASSWORD=somerootpassword
```

The `.env` file is excluded from Git via `.gitignore` and must be created manually before first run.

A `secrets/` folder exists in the repository structure but is not actively used by the entrypoint scripts in this implementation — all credentials are passed via environment variables, which satisfies the subject's mandatory requirement. Docker secrets were considered as the recommended production-grade approach but were not implemented for this project.

## Build and Launch

Build all services:

```bash
make
```

Rebuild:

```bash
make re
```

## Useful Commands

Show containers:

```bash
docker ps
```

Enter NGINX container:

```bash
docker exec -it nginx sh
```

Enter WordPress container:

```bash
docker exec -it wordpress sh
```

Enter MariaDB container:

```bash
docker exec -it mariadb bash
```

View logs:

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

## Data Persistence

### WordPress Volume

Stores:
- WordPress files
- Uploads
- Plugins
- Themes

Mounted at:

```bash
/var/www/html
```

### MariaDB Volume

Stores:

- Database files
- User data
- WordPress content

Mounted at:

```bash
/var/lib/mysql
```

Volumes remain available after container recreation.

## Networking

Containers communicate through:

```bash
inception
```

Docker bridge network.

Service discovery uses container names:

```bash
wordpress
mariadb
nginx
```

Examples:

- nginx → wordpress:9000
- wordpress → mariadb:3306

## Cleanup

Remove containers:

```bash
make down
```

Remove containers and volumes:

```bash
make fclean
```

Remove unused Docker resources:

```bash
docker system prune -a
```