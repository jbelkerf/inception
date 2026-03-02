NAME=inception


all:
	@ mkdir -p /home/jbelkerf/data/mariadb
	@ mkdir -p /home/jbelkerf/data/wordpress
	docker compose -f ./srcs/docker-compose.yml up -d --build

stop:
	docker stop nginx wordpress mariadb
	docker rm  nginx wordpress mariadb
	docker rmi  srcs-nginx srcs-wordpress srcs-mariadb
sync:
	scp -rP 3333 ~/Desktop/inception jbelkerf@localhost:~ 