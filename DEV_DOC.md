# Developer Documentation — Inception

## Setting Up the Environment from Scratch

### Prerequisites

Make sure the following are installed on your VM:

```bash
# Check Docker
docker --version        # should be 20.x or higher

# Check Docker Compose
docker compose version  # should be v2.x

# Check Make
make --version
```

If Docker is not installed:
```bash
sudo apt update && sudo apt install -y docker.io docker-compose-plugin make
sudo usermod -aG docker $USER   # add yourself to docker group
newgrp docker                   # apply group without logout
```

### Repository Structure

```
inception/
├── Makefile                        # Build entrypoint
├── README.md                       # Project overview
├── USER_DOC.md                     # End-user documentation
├── DEV_DOC.md                      # This file
└── srcs/
    ├── .env                        # Environment variables (never commit)
    ├── docker-compose.yml          # Service orchestration
    ├── nginx/
    │   ├── Dockerfile
    │   └── conf/nginx.conf
    ├── WordPress/
    │   ├── Dockerfile
    │   ├── wp_config.sh            # Entrypoint script
    │   └── www.conf                # PHP-FPM pool config
    └── MariaDB/
        ├── Dockerfile
        ├── script.sh               # Entrypoint script
        └── 50-server.cnf           # MariaDB config
```

### Configuration Files

**1. Create `srcs/.env`** — copy and fill in all values:
```bash
DOMAIN_NAME=jbelkerf.42.fr
SITE_TITLE=Inception
SQL_DATABASE=wordpress_db
SQL_USER=wp_user
SQL_PASSWORD=yourpassword
SQL_ROOT_PASSWORD=yourrootpassword
ADMIN_USER=wpmaster
ADMIN_PASSWORD=youradminpass
ADMIN_EMAIL=wpmaster@jbelkerf.42.fr
USER_LOGIN=wp_author
USER_EMAIL=author@jbelkerf.42.fr
USER_PASSWORD=yourauthorpass
```

Rules from the subject:
- `ADMIN_USER` must NOT contain `admin`, `Admin`, `administrator`, or `Administrator`
- Never commit `.env` to Git  it is listed in `.gitignore`

**2. Add your domain to `/etc/hosts` on the VM:**
```bash
echo "127.0.0.1 jbelkerf.42.fr" | sudo tee -a /etc/hosts
```

---

## Building and Launching with Makefile and Docker Compose

**First build and start:**
```bash
make
```
Internally runs:
```bash
docker compose -f ./srcs/docker-compose.yml up -d --build
```
- `--build` forces image rebuild even if cached
- `-d` runs in detached (background) mode

**Full clean rebuild:**
```bash
make re
```
Stops containers, removes images, then rebuilds from scratch.

**Nuclear reset (wipe everything including data):**
```bash
docker compose -f ./srcs/docker-compose.yml down -v && docker system prune -af
make
```

---

## Container Management Commands

**See running containers:**
```bash
docker ps
```

**See all containers including stopped:**
```bash
docker ps -a
```

**Follow logs in real time:**
```bash
docker logs -f wordpress
docker logs -f mariadb
docker logs -f nginx
```

**Shell into a running container:**
```bash
docker exec -it wordpress bash
docker exec -it mariadb bash
docker exec -it nginx bash
```

**Restart a single service:**
```bash
docker restart wordpress
```

**Rebuild and restart a single service only:**
```bash
docker compose -f ./srcs/docker-compose.yml up -d --build wordpress
```

**Inspect the Docker network:**
```bash
docker network inspect srcs_inception
```

---

## Data Storage and Persistence

### Named Volumes

The project uses two Docker named volumes:

| Volume | Mounted at | Contains |
|---|---|---|
| `srcs_wp_data` | `/var/www/html` in wordpress and nginx | WordPress core files, themes, plugins, uploads |
| `srcs_db_data` | `/var/lib/mysql` in mariadb | All MariaDB database files |

**Inspect a volume:**
```bash
docker volume inspect srcs_wp_data
docker volume inspect srcs_db_data
```

**List all volumes:**
```bash
docker volume ls
```

### How Persistence Works

When you run `docker compose down` (without `-v`), containers are destroyed but volumes remain. On the next `make`, containers are recreated and reattach to the existing volumes  all WordPress content and database data survives.

The init scripts are idempotent:
- `script.sh` checks `if [ ! -d "/var/lib/mysql/${SQL_DATABASE}" ]` — skips DB setup if already initialized
- `wp_config.sh` checks `if [ ! -f /var/www/html/wp-config.php ]` — skips WordPress install if already configured

**Delete volumes (all data lost):**
```bash
docker compose -f ./srcs/docker-compose.yml down -v
```

### Where Docker Stores Volume Data on the Host

it is stored on /home/jbelkerf/data/ and you can check by runing this 

```bash
# Find the actual path on the host:
docker volume inspect srcs_wp_data 
#or 
docker volume inspect srcs_db_data 
# Returns something like: /var/lib/docker/volumes/srcs_wp_data/_data
```

---

## How the Startup Sequence Works

Understanding the boot order helps debug issues:

```
1. MariaDB container starts
   └── script.sh runs
       ├── If fresh volume: initializes DB, creates user, sets root password
       └── exec mysqld (becomes PID 1, ready for connections on port 3306)

2. WordPress container starts (depends_on: mariadb)
   └── wp_config.sh runs
       ├── Patience loop: pings MariaDB every 2s until ready
       ├── If fresh volume: downloads WordPress, creates wp-config.php, installs WP, creates users
       └── exec php-fpm8.2 -F (becomes PID 1, listens on port 9000)

3. NGINX container starts (depends_on: wordpress)
   └── nginx -g 'daemon off;' (becomes PID 1, listens on port 443)
       └── Forwards .php requests to wordpress:9000 via FastCGI
```

---

## Common Debug Commands

```bash
# Check if MariaDB DB was created:
docker exec -it mariadb mariadb -uroot -p"{root password here}" -e "SHOW DATABASES;"

# Check WordPress files exist:
docker exec -it wordpress ls /var/www/html

# Check wp-config.php was created:
docker exec -it wordpress cat /var/www/html/wp-config.php | head -20

# Check PHP-FPM is listening on 9000:
docker exec -it wordpress ss -tlnp | grep 9000

# Check NGINX config is valid:
docker exec -it nginx nginx -t

# Check TLS certificate:
openssl s_client -connect jbelkerf.42.fr:443 -tls1_2
```
