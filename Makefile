NAME=inception


all:
	@sudo mkdir -p /home/jbelkerf/data/mariadb
	@sudo mkdir -p /home/jbelkerf/data/wordpress
	docker compose -f ./srcs/docker-compose.yml up -d --build