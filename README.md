*This project has been created as part of the 42 curriculum by tkremnov.*

# Inception

## Description

Inception is a system administration project focused on containerization using Docker.

The goal is to build a small infrastructure composed of multiple Docker containers running different services while following security and isolation principles.

The stack includes:

- NGINX with TLSv1.2/TLSv1.3
- WordPress with PHP-FPM
- MariaDB
- Docker volumes for persistent data
- Docker network for inter-container communication

The services run in separate containers and communicate through a dedicated Docker bridge network.

## Architecture

Client  
↓ HTTPS (443)  
NGINX  
↓ FastCGI (9000)  
WordPress (PHP-FPM)  
↓ TCP (3306)  
MariaDB

### Services

#### NGINX
- Entry point of the infrastructure
- Handles HTTPS connections
- Terminates TLS
- Forwards PHP requests to WordPress

#### WordPress
- PHP-FPM application server
- Serves WordPress content
- Connects to MariaDB

#### MariaDB
- Stores WordPress data
- Uses a dedicated persistent volume

## WordPress Users

Two users are created automatically on first run:
- Administrator: username does not contain "admin" (per subject requirement)
- Regular user: author role

Credentials are defined via `.env` variables `MYSQL_ADMIN_USER` and `MYSQL_USER`.

## Design Choices

## Virtual Machines vs Docker

### Virtual Machine
- Runs a full OS with its own kernel
- Strong isolation, heavier resource usage
- Slower startup
- Required by subject (VM environment)

### Docker
- Shares host kernel
- Lightweight and fast
- Each service runs in a separate container
- Managed via Docker Compose

**Summary:**
VM provides isolation layer, Docker provides service isolation inside it.

## Secrets vs Environment Variables

### Environment Variables
- Simple key-value configuration (`.env`)
- Used for all configuration in this project (domain, DB credentials, ports)
- Visible inside container environment

### Docker Secrets
- Designed for sensitive data, mounted as files at runtime (e.g. `/run/secrets/`)
- Not used for passwords in this implementation — `.env` was used instead per project minimum requirements
- Would be the recommended production approach for credentials

**Summary:**
This project satisfies the mandatory `.env` requirement. Docker secrets were considered but not implemented; `.env` was used for all configuration including passwords, which the subject explicitly allows as the minimum requirement.

## Docker Network vs Host Network

### Bridge Network (used)
- Containers communicate via service names
- Isolated from host
- Recommended default

### Host Network
- Shares host network directly
- No isolation, possible port conflicts

**Summary:**
Bridge network ensures isolation and safe container communication.

## Docker Volumes vs Bind Mounts

### Volumes (used)
- Managed by Docker
- Persistent and portable
- Best for databases and production data

### Bind Mounts
- Direct host folder mapping
- Useful for development
- Less portable and less safe

**Summary:**  
Volumes = safe persistence, Bind mounts = development convenience.

## Instructions

### Clone repository

```bash
git clone <repository-url>
cd inception
```

### Configure environment

Create or edit:
```bash
srcs/.env
```

Configure:
```bash
DOMAIN_NAME=tkremnov.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_ADMIN_USER=wpmaster
DB_PASSWORD=somepassword
DB_ROOT_PASSWORD=somerootpassword
```

Build and run
```bash
make
make down    #Stop containers
make fclean  #Remove everything
```

## Project Structure
```bash
srcs/
├── docker-compose.yml
├── .env
└── requirements/
    ├── nginx/
    ├── wordpress/
    └── mariadb/
```

## Resources

### Article
[A Dive into Docker and Docker-Compose](https://medium.com/@afatir.ahmedfatir/unveiling-42-the-network-inception-a-dive-into-docker-and-docker-compose-cfda98d9f4ac)

### Video
[The Only Docker Tutorial You Need To Get Started](https://www.youtube.com/watch?v=DQdB7wFEygo)

### Docker

https://docs.docker.com/  
https://docs.docker.com/compose/

### NGINX

https://nginx.org/en/docs/

### WordPress

https://developer.wordpress.org/

### MariaDB

https://mariadb.com/kb/en/


### AI Usage

AI tools were used as supplementary learning resources for:

- Docker concepts
- NGINX configuration explanations
- MariaDB configuration explanations
- Documentation review
- Troubleshooting and debugging assistance

All implementation decisions, code integration, testing, and validation were performed manually.