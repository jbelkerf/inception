NAME=inception


all:
	@ mkdir -p /home/jbelkerf/data/mariadb
	@ mkdir -p /home/jbelkerf/data/wordpress
	docker compose -f ./srcs/docker-compose.yml up -d --build

stop:
	docker compose -f ./srcs/docker-compose.yml down

sync:
	scp -rP 3333 ~/Desktop/inception jbelkerf@localhost:~ 


clean: stop

fclean: clean 
	docker compose -f ./srcs/docker-compose.yml down -v
	sudo rm -rf /home/jbelkerf/data/
startvm:
	VBoxManage startvm khdem --type headless

re: fclean all

ssh:
	ssh -p 3333 jbelkerf@localhost
