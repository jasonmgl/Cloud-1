FROM debian:bookworm

# Debian bullseye only ships PHP 7.4; add the Sury repository for PHP 8.4
RUN apt update -y && apt install -y \
	ca-certificates \
	curl \
	gnupg \
	lsb-release \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://packages.sury.org/php/apt.gpg -o /etc/apt/trusted.gpg.d/php.gpg \
	&& echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

# Install wordpress & php
RUN apt update -y && apt-get install -y \
	mariadb-client \
	php8.4 \
	php8.4-fpm \
	php8.4-mysql \
	wget \
	&& apt-get clean && rm -rf /var/lib/apt/lists/*

EXPOSE 9000

# Update PHP configuration
COPY ./conf/www.conf /etc/php/8.4/fpm/pool.d/www.conf

# Set wordpress configuration
COPY ./tools/wp_init.sh /usr/local/bin/wp_init.sh
RUN chmod +x /usr/local/bin/wp_init.sh

ENTRYPOINT ["/usr/local/bin/wp_init.sh"]
