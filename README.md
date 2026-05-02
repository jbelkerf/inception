*This project has been created as part of the 42 curriculum by jbelkerf.*

# Inception

## Description

Inception is a system administration project from the 42 curriculum. The goal is to build a small but complete web infrastructure using Docker, where each service runs in its own dedicated container  built from scratch, without pulling pre-made images from Docker Hub.

The stack consists of three services working together:

- **NGINX** — the only entry point into the infrastructure, handling HTTPS with TLS 1.2/1.3 and forwarding PHP requests to WordPress via FastCGI.
- **WordPress + PHP-FPM** — the application layer, running PHP without any web server inside its container.
- **MariaDB** — the database layer, storing all WordPress data, accessible only from within the Docker network.

All containers are connected through a custom Docker bridge network. Data is persisted through two named Docker volumes  one for the WordPress files, one for the database.

### Design Choices

**Why these base images?**
All containers are built from `debian:bookworm` (Debian 12), the current oldstable release. It was chosen for its stability, wide package availability, and long support lifecycle  ideal for a production-like setup.

**Virtual Machines vs Docker**

| | Virtual Machine | Docker Container |
|---|---|---|
| Isolation | Full OS-level isolation | Process-level isolation |
| Size | GBs (full OS) | MBs (just the app + deps) |
| Boot time | Minutes | Milliseconds |
| Resource usage | Heavy (own kernel) | Lightweight (shared kernel) |
| Use case | Full system emulation | App packaging and deployment |

A VM simulates an entire machine including hardware. Docker containers share the host kernel but isolate the process and filesystem. Containers are not VMs  they are closer to isolated processes.

**Secrets vs Environment Variables**

| | `.env` / Environment Variables | Docker Secrets |
|---|---|---|
| Storage | Plain text, injected into env | File mounted at `/run/secrets/` |
| Visible in `docker inspect` | Yes | No |
| Risk if misconfigured | Exposed in process listings | Not exposed |
| Best for | Non-sensitive config (domain, DB name) | Passwords, API keys, tokens |

Environment variables are convenient but expose sensitive data through
`docker inspect`. Docker secrets mount values as files inside containers
 never in the environment  making them significantly more secure for
credentials. In this project, `.env` is used for configuration variables
and is excluded from Git via `.gitignore`. Passwords are passed through
environment variables but would ideally be managed via Docker secrets in
a production environment.

**Docker Network vs Host Network**

|                     | Docker Bridge Network                         | Host Network                                       |
| ------------------- | --------------------------------------------- | -------------------------------------------------- |
| Isolation           | Containers get their own network namespace    | Container shares host's network namespace          |
| Inter-container DNS | By service name (e.g. `mariadb`, `wordpress`) | Must use `localhost` or host IP                    |
| Port exposure       | Explicit via `ports:` mapping                 | Any port the container uses is immediately exposed |
| Security            | Strong  containers can't reach host network   | Weak  no isolation from host                       |
| Subject requirement | Required                                      | Forbidden                                          |

This project uses a custom bridge network called `inception`. Containers communicate by service name. Only NGINX exposes a port (443) to the outside world.

**Docker Volumes vs Bind Mounts**

|                    | Named Volumes              | Bind Mounts                      |
| ------------------ | -------------------------- | -------------------------------- |
| Managed by         | Docker                     | You (host path)                  |
| Portability        | Fully portable             | Depends on host path existing    |
| Subject compliance | Required                   | Forbidden for persistent storage |
| Inspect with       | `docker volume inspect`    | Just `ls` on host                |
| Data location      | `/var/lib/docker/volumes/` | Wherever you specify             |
|                    |                            |                                  |

Named volumes are the Docker-native way to persist data. Bind mounts directly link a host directory into the container  they work but are less portable and explicitly forbidden by this project's subject.

---

## Instructions

### Prerequisites

- A Linux virtual machine (Debian or Ubuntu recommended)
- Docker and Docker Compose installed
- `make` installed
- but the domain jbelkerf.42.fr in `/etc/hosts` pointing to `127.0.0.1`

### Setup

**1. Clone the repository:**
```bash
git clone git@vogsphere.1337.ma:vogsphere/intra-uuid-39bae29a-5506-4b60-ac0d-b314a780cda2-7268853-jbelkerf
cd inception
```

**2. Add your domain to `/etc/hosts` on the VM:**
```bash
echo "127.0.0.1 jbelkerf.42.fr" | sudo tee -a /etc/hosts
```

**3. Create the `.env` file** at `srcs/.env` (see `srcs/.env.example` for the required variables):
```
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

**4. Build and start:**
```bash
make
```

**5. Visit the site:**

Open your browser and go to `https://jbelkerf.42.fr`. Accept the self-signed certificate warning.

### Makefile targets

| Target | Description |
|---|---|
| `make` / `make all` | Build images and start all containers |
| `make stop` | Stop and remove containers and images |
| `make re` | Full rebuild from scratch |

---

## Resources

### Documentation
- [Docker official documentation](https://docs.docker.com/)
- [Docker Compose reference](https://docs.docker.com/compose/compose-file/)
- [Dockerfile best practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [MariaDB documentation](https://mariadb.com/kb/en/documentation/)
- [WordPress CLI (WP-CLI)](https://wp-cli.org/)
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [Debian releases](https://www.debian.org/releases/)
- [Understanding PID 1 in Docker](https://cloud.google.com/architecture/best-practices-for-building-containers#signal-handling)

### AI Usage
AI (Claude by Anthropic) was used during this project for the following:

- **Debugging** — diagnosing container startup failures, interpreting Docker and MariaDB log output, identifying the cause of exit codes (e.g. exit 127).
- **Script review** — reviewing `wp_config.sh` and `script.sh` for logic errors .
- **Documentation** — generating the initial drafts of README.md, USER_DOC.md, and DEV_DOC.md, which were then reviewed and adapted.

All AI-generated content was reviewed, understood, and tested before being included in the project.
