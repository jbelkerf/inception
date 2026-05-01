FROM debian:trixie

WORKDIR /var/www/html

RUN apt update && apt install -y wget php-fpm php-mysql mariadb-client && rm -rf /var/lib/apt/lists/* 

RUN mkdir -p /run/php

COPY wp_config.sh /usr/local/bin/

RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp &&\
    chmod +x /usr/local/bin/wp_config.sh

COPY www.conf /etc/php/8.4/fpm/pool.d/www.conf

ENTRYPOINT ["/usr/local/bin/wp_config.sh"]



