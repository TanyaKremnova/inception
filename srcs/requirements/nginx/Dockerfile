FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Copy nginx config
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Copy entrypoint
COPY tools/init.sh /init.sh
RUN chmod +x /init.sh

EXPOSE 443

ENTRYPOINT ["/init.sh"]
