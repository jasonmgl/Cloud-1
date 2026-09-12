FROM debian:bookworm

RUN apt update -y && apt install -y \
	nginx \
	net-tools \
	gettext-base \
	&& rm -rf /var/lib/apt/lists/*

# Congigure Nginx
RUN mkdir -p /var/run/nginx
COPY ./conf/nginx.conf.template /etc/nginx/nginx.conf.template

# Set the permission
RUN chmod -R 755 /var/www/html/
# Set the ownership
RUN chown -R www-data:www-data /var/www/html/

# Render nginx.conf from the template using $DOMAIN_NAME at container start,
# then keep Nginx in the foreground
COPY ./tools/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
