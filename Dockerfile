FROM buyanydeal/docker-alpine-base:latest

LABEL maintainer="Ruud van Engelenhoven <ruud.vanengelenhoven@gmail.com>"

ENV PHPIZE_DEPS \
	autoconf \
	dpkg-dev dpkg \
	file \
	g++ \
	gcc \
	libc-dev \
	make \
	pcre-dev \
	pkgconf \
	re2c

# Add s6-overlay
ENV S6_OVERLAY_VERSION=v1.22.1.0
ENV NGINX_VERSION=nginx-1.16.0
ENV S6_FIX_ATTRS_HIDDEN=1
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV TZ="Asia/Dubai"

RUN rm -rf /var/cache/apk/* && \
	rm -rf /tmp/*

RUN apk update

RUN set -xe \
	&& apk add --no-cache --virtual .build-deps \
	postgresql-dev \
	icu-dev \
	libpng-dev \
	libjpeg-turbo-dev \
	freetype-dev \
	libxslt-dev \
	libmcrypt-dev \
	curl-dev \
	bzip2-dev \
	readline-dev \
	libedit-dev \
	recode-dev \
	imagemagick-dev  \
	geoip-dev \
	$PHPIZE_DEPS \
	&& apk add --no-cache \
	libpng \
	zlib-dev \
	libzip-dev \
	libjpeg \
	freetype \
	icu-libs \
	libmcrypt \
	libxslt \
	libbz2 \
	imagemagick \
	geoip \
	# readline \ warning: readline (readline.so) is already loaded!
	libtool \
	recode \
	# set timezone to Dubai
	tzdata \
	&& cp /usr/share/zoneinfo/$TZ /etc/localtime \
	&& echo "$TZ" >  /etc/timezone \
	&& apk del tzdata \
	# Extra PHP extensions (no extra configuration)
	&& docker-php-ext-install \
	bcmath \
	bz2 \
	intl \
	# iconv \ warning: iconv (iconv.so) is already loaded!
	# json \ warning: json (json.so) is already loaded!
	# mbstring \ warning: mbstring (mbstring.so) is already loaded!
	# pdo \ warning: pdo (pdo.so) is already loaded!
	pdo_mysql \
	pdo_pgsql \
	pgsql \
	mysqli \
	readline \
	recode \
	# simplexml \ warning: simplexml (simplexml.so) is already loaded!
	soap \
	xmlrpc \
	xsl \
	exif \
	# install mcrypt via pecl
	&& pecl install mcrypt-1.0.2 \
	&& docker-php-ext-enable mcrypt \
	# install zip via pecl
	&& pecl install zip-1.15.4 \
	&& docker-php-ext-enable zip \
	# install imagick via pecl
	&& pecl install imagick-3.4.4 \
	&& docker-php-ext-enable imagick \
	# install redis via pecl
	&& pecl install -o -f redis-4.3.0 \
	&&  docker-php-ext-enable redis \
	# install geoip via pecl
	&& pecl install -o -f geoip-1.1.1 \
	&&  docker-php-ext-enable geoip \
	# install igbinary via pecl
	&& pecl install -o -f igbinary \
	&& docker-php-ext-enable igbinary \
	# GD extension
	&& docker-php-ext-configure gd \
	--with-freetype-dir=/usr/include/ \
	--with-jpeg-dir=/usr/include \
	&& docker-php-ext-install gd \
	# opcache config
	&& docker-php-ext-configure opcache --enable-opcache \
	&& docker-php-ext-install opcache \
	&& cd /usr/local/etc/php/conf.d \
	&& echo "opcache.enable=1" >> docker-php-ext-opcache.ini \
	&& echo "opcache.enable_cli=1" >> docker-php-ext-opcache.ini \
	&& echo "opcache.memory_consumption=512" >> docker-php-ext-opcache.ini \
	&& echo "opcache.interned_strings_buffer=12" >> docker-php-ext-opcache.ini \
	&& echo "opcache.fast_shutdown=1" >> docker-php-ext-opcache.ini \
	&& echo "opcache.revalidate_freq=0" >> docker-php-ext-opcache.ini \
	&& echo "opcache.max_accelerated_files=65406" >> docker-php-ext-opcache.ini \
	# install nginx
	&& apk --update add openssl-dev pcre-dev zlib-dev build-base \
	&& mkdir -p /tmp/src \
	&& cd /tmp/src \
	&& curl http://nginx.org/download/${NGINX_VERSION}.tar.gz > ${NGINX_VERSION}.tar.gz \
	&& tar -zxvf ${NGINX_VERSION}.tar.gz \
	&& cd /tmp/src/${NGINX_VERSION} \
	&& ./configure \
	--with-http_ssl_module \
	--with-http_realip_module \
	--with-http_geoip_module \
	--with-http_gzip_static_module \
	--prefix=/etc/nginx \
	--http-log-path=/var/log/nginx/access.log \
	--error-log-path=/var/log/nginx/error.log \
	--sbin-path=/usr/local/sbin/nginx \
	&& make \
	&& make install \
	&& apk del build-base \
	&& rm -rf /tmp/src \
	# install other stuff
	&&  apk add --no-cache \
	vim  \
	nginx \
	ssmtp \
	dcron \
	curl \
	sudo \
	git \
	jq \
	# install s6
	&& curl -sSL https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz \
	| tar xfz - -C / \
	# install composer
	&& curl -sS https://getcomposer.org/installer | php -- --filename=composer --install-dir=/usr/local/bin \
	# Delete build dependencies to save space
	&& apk del .build-deps \
	# remove pear cache
	&& rm -rf /tmp/pear \
	# Remove apk cache
	&& rm -rf /var/cache/apk/*
