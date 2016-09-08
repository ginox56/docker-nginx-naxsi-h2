FROM debian:jessie

ENV NGINX_VERSION 1.11.3
ENV NGINX_KEY 520A9993A1C052F8
ENV LIBRESSL_VERSION 2.4.2
ENV LIBRESSL_KEY 1FFAA0B24B708F96

WORKDIR /usr/src

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
                git-core \
                curl \
                ca-certificates \
                build-essential \
                libpcre3-dev \
                zlib1g-dev \
	&& curl -O https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
	&& curl -O https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz.asc \
	&& gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys ${NGINX_KEY} \
	&& gpg --batch --verify nginx-${NGINX_VERSION}.tar.gz.asc nginx-${NGINX_VERSION}.tar.gz \
	&& tar -zxf nginx-${NGINX_VERSION}.tar.gz \
	&& rm nginx-${NGINX_VERSION}.tar.gz.asc nginx-${NGINX_VERSION}.tar.gz \
	&& curl -O http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VERSION}.tar.gz \
	&& curl -O http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VERSION}.tar.gz.asc \
	&& gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys ${LIBRESSL_KEY} \
	&& gpg --batch --verify libressl-${LIBRESSL_VERSION}.tar.gz.asc libressl-${LIBRESSL_VERSION}.tar.gz \
	&& tar -zxf libressl-${LIBRESSL_VERSION}.tar.gz \
	&& rm libressl-${LIBRESSL_VERSION}.tar.gz.asc libressl-${LIBRESSL_VERSION}.tar.gz \
	&& git clone https://github.com/nbs-system/naxsi \
	&& cd naxsi \
	&& git fetch origin pull/309/head:build \
	&& git checkout build \
	&& cd .. \
	&& cd nginx-${NGINX_VERSION} \
	&& ./configure \
                --prefix=/etc/nginx \
                --sbin-path=/usr/sbin/nginx \
                --conf-path=/etc/nginx/nginx.conf \
                --error-log-path=/var/log/nginx/error.log \
                --http-log-path=/var/log/nginx/access.log \
                --with-http_auth_request_module \
                --with-http_gzip_static_module \
                --with-http_realip_module \
                --with-http_ssl_module \
                --with-http_stub_status_module \
                --with-ipv6 \
                --with-http_v2_module \
                --add-module=/usr/src/naxsi/naxsi_src \
                --with-openssl=/usr/src/libressl-${LIBRESSL_VERSION} \
                --with-pcre-jit \
                --pid-path=/var/run/nginx.pid \
                --lock-path=/var/run/nginx.lock \
                --http-client-body-temp-path=/var/cache/nginx/client_temp \
                --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
                --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
                --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
                --without-http_scgi_module \
	&& make && make install \
	&& mkdir /var/cache/nginx \
	&& cd .. \
	&& rm -rf nginx-${NGINX_VERSION} naxsi libressl-${LIBRESSL_VERSION} \
	&& apt-get purge -y --auto-remove \
                git-core \
                curl \
                ca-certificates \
                build-essential \
                libpcre3-dev \
                zlib1g-dev \
	&& rm -rf /var/lib/apt/lists/*

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
