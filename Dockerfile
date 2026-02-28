FROM debian:bullseye-slim
LABEL name="nintendo-dgamer-pi"
LABEL description="Optimized DGamer server for Raspberry Pi (ARM)"

# FIX FOR 2026: Redirect to Debian Archives because Bullseye is End-of-Life
RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i 's|security.debian.org/debian-security|archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    sed -i '/bullseye-updates/d' /etc/apt/sources.list

# Install build dependencies + dnsmasq
RUN apt-get update && apt-get install -y \
    curl build-essential make libz-dev libbz2-dev \
    libreadline-dev libexpat1-dev zlib1g-dev libssl-dev \
    libapr1-dev libaprutil1-dev libpcre3-dev php-cli \
    php-dev libapache2-mod-php dnsmasq \
    && rm -rf /var/lib/apt/lists/*

# DS Compatibility: Force OpenSSL to allow legacy security levels
RUN sed -i 's/CipherString = DEFAULT@SECLEVEL=2/CipherString = DEFAULT@SECLEVEL=0/' /etc/ssl/openssl.cnf

# 1. Compile OpenSSL 1.0.2k (SSLv3 enabled for DS)
WORKDIR /tmp
RUN curl -L https://www.openssl.org/source/openssl-1.0.2k.tar.gz | tar -xzf - \
    && cd openssl-1.0.2k \
    && ./config --prefix=/usr --openssldir=/usr/lib/ssl -fPIC enable-ssl2 enable-ssl3 no-shared \
    && make -j$(nproc) \
    && make install

# 2. Compile PCRE 8.45
RUN curl -L https://sourceforge.net/projects/pcre/files/pcre/8.45/pcre-8.45.tar.bz2/download | tar -xjf - \
    && cd pcre-8.45 \
    && ./configure --prefix=/usr --enable-unicode-properties --enable-pcre16 --enable-pcre32 \
    && make -j$(nproc) \
    && make install

# 3. Compile Apache 2.4.48 (Archive URLs)
RUN curl -L https://archive.apache.org/dist/httpd/httpd-2.4.48.tar.gz | tar -xzf - && mv httpd-2.4.48 httpd \
    && curl -L https://archive.apache.org/dist/apr/apr-1.7.0.tar.gz | tar -xzf - && mv apr-1.7.0 httpd/srclib/apr \
    && curl -L https://archive.apache.org/dist/apr/apr-util-1.6.1.tar.gz | tar -xzf - && mv apr-util-1.6.1 httpd/srclib/apr-util \
    && cd httpd && ./configure \
    --prefix=/usr/local/apache \
    --with-included-apr \
    --enable-ssl \
    --with-ssl=/usr \
    --enable-ssl-staticlib-deps \
    --enable-mods-static=ssl \
    --enable-mods-shared=all \
    --enable-so \
    && make -j$(nproc) \
    && make install

# Create necessary directories
RUN mkdir -p /usr/local/apache/certs /var/www

# Copy your local files
COPY ./sites/ /var/www/
COPY ./configs/apache/ /usr/local/apache/conf/
COPY ./entrypoint.sh /srv/

RUN chmod +x /srv/entrypoint.sh

EXPOSE 80 443 53/tcp 53/udp
WORKDIR /usr/local/apache
CMD ["/srv/entrypoint.sh"]
