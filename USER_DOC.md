# User Documentation — Inception

## What Services Are Provided

This stack runs a complete WordPress website with the following components:

| Service | Role | Accessible From |
|---|---|---|
| NGINX | Web server / reverse proxy | Browser via `https://jbelkerf.42.fr` |
| WordPress | CMS application | Via NGINX (not directly) |
| MariaDB | Database | Internal only (not exposed) |

The only service you interact with directly is NGINX through your browser. WordPress and MariaDB are internal  they are not reachable from outside the Docker network.

---

## Starting and Stopping the Project

**Start everything:**
```bash
make
```
This builds all Docker images (if not already built) and starts all three containers in detached mode.

**Stop everything (keeps data):**
```bash
make stop
```
Containers are stopped and removed, but volumes (your WordPress files and database) are preserved.

**Stop everything and delete all data:**
```bash
make fclean
```


**Full rebuild from scratch:**
```bash
make re
```

---

## Accessing the Website and Admin Panel

**Website:**
```
https://jbelkerf.42.fr
```
Your browser will warn about a self-signed certificate  this is expected. Click "Advanced" and proceed.

**WordPress Admin Panel:**
```
https://jbelkerf.42.fr/wp-admin
```
Log in with the admin credentials defined in `srcs/.env`.

---

## Locating and Managing Credentials

All credentials are stored in `srcs/.env`. This file is **never committed to Git**.

| Variable | Purpose |
|---|---|
| `ADMIN_USER` | WordPress administrator username |
| `ADMIN_PASSWORD` | WordPress administrator password |
| `USER_LOGIN` | WordPress author username |
| `USER_PASSWORD` | WordPress author password |
| `SQL_USER` | MariaDB WordPress user |
| `SQL_PASSWORD` | MariaDB WordPress user password |
| `SQL_ROOT_PASSWORD` | MariaDB root password |

To change a credential, edit `srcs/.env`, then do a full rebuild:
```bash
make fclean
make
```

---

## Checking That Services Are Running

**Check container status:**
```bash
docker ps
```
All three containers (`nginx`, `wordpress`, `mariadb`) should show `Up` status. If any shows `Restarting`, something is wrong.

**Check logs for a specific service:**
```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

**Check MariaDB is working:**
```bash
docker exec -it mariadb mariadb -uroot -p"${SQL_ROOT_PASSWORD}" -e "SHOW DATABASES;"
```
You should see `wordpress_db` in the list.

**Check WordPress volume has files:**
```bash
docker exec -it wordpress ls /var/www/html
```
You should see WordPress core files like `wp-config.php`, `wp-login.php`, `wp-includes/`, etc.

**Test HTTPS is working:**
```bash
curl -k https://jbelkerf.42.fr
```
You should get HTML back. The `-k` flag bypasses the self-signed cert warning.
