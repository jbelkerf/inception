FROM debian

WORKDIR /


RUN  apt update && apt install mariadb-server -y
COPY 50-server.cnf /etc/mysql/mariadb.conf.d/

COPY script.sh /usr/bin/script.sh
RUN chmod +x /usr/bin/script.sh

ENTRYPOINT [ "/usr/bin/script.sh" ]