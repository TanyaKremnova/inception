FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

# Copy nginx config
COPY conf/nginx.conf.template /etc/nginx/nginx.conf.template

# Copy entrypoint
COPY tools/init.sh /init.sh
RUN chmod +x /init.sh

EXPOSE 443

ENTRYPOINT ["/init.sh"]
