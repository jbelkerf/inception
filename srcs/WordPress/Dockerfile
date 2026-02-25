FROM debian

WORKDIR /var/www/html

RUN apt update && apt install -y wget php7.4-fpm php7.4-mysql mariadb-client

RUN mkdir -p /run/php

RUN wget https://raw.githubusercontent.com/wp-cli/builds/medial/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

COPY ./conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
COPY ./tools/wp_config.sh /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/wp_config.sh"]
