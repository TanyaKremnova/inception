# User Documentation

## Provided Services

The infrastructure provides:

- HTTPS website through NGINX
- WordPress CMS
- MariaDB database backend

## Starting the Project

```bash
make
```

## Stopping the Project
```bash
make down
```

## Accessing the Website

```bash
# Open:

https://<DOMAIN_NAME>

# Example:

https://tkremnov.42.fr
```

## Accessing WordPress Administration
```bash
# Open:

https://<DOMAIN_NAME>/wp-admin

# Example:

https://tkremnov.42.fr/wp-admin
```

## Credentials

Credentials are defined in:

```bash
srcs/.env
```

and secret files.

Examples:

- WordPress administrator
- WordPress user
- MariaDB user

Check logs:

- docker logs nginx
- docker logs wordpress
- docker logs mariadb

## Checking Service Health

Check all containers are running:
```bash
docker ps
```
All three (mariadb, wordpress, nginx) should show status "Up".

Check website responds:
```bash
curl -k https://tkremnov.42.fr
```

## Local Testing Note (Codam Environment)

Due to Codam's security policy preventing non-root binding to port 443, this project maps NGINX's port 443 to host port 8443 for local testing (`8443:443` in VirtualBox port forwarding). NGINX itself only ever listens on 443 inside the container/VM, satisfying the project requirement. To browse locally:

```bash
chromium /
--host-resolver-rules="MAP tkremnov.42.fr 127.0.0.1" /
--ignore-certificate-errors https://tkremnov.42.fr:8443
```