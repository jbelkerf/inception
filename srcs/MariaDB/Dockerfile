FROM debian

WORKDIR /


RUN  apt update && apt install mariadb-server -y
RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld
COPY 50-server.cnf /etc/mysql/mariadb.conf.d/

COPY script.sh /usr/bin/script.sh
RUN chmod +x /usr/bin/script.sh

ENTRYPOINT [ "/usr/bin/script.sh" ]