FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-curl \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-zip \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install WP-CLI — the WordPress command line tool
RUN curl -o /usr/local/bin/wp \
    https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# Copy php-fpm pool config
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

# Copy entrypoint
COPY tools/init.sh /init.sh
RUN chmod +x /init.sh

# Create the web root
RUN mkdir -p /var/www/html
WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/init.sh"]

# php-mysql			— WordPress talks to MariaDB
# php-curl			— WordPress fetches updates, plugins
# php-gd			— image manipulation (thumbnails)
# php-mbstring		— multibyte string handling
# php-xml / php-zip	— needed for plugin/theme installation

