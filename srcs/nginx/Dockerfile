FROM debian:bookworm

RUN apt update && apt install -y nginx openssl && rm -rf /var/lib/apt/lists/*

# Generate SSL certificate (Self-signed)
# Requirement: TLS v1.2 or v1.3
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=MA/L=Tetouan/O=42/OU=Student/CN=jbelkerf.42.fr"

# Copy our config file
COPY conf/nginx.conf /etc/nginx/sites-available/default

# Start NGINX in the foreground
CMD ["nginx", "-g", "daemon off;"]