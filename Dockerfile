FROM debian:bullseye-slim
LABEL name="nintendo-dgamer-pi"
LABEL description="Optimized DGamer server for Raspberry Pi (ARM)"

# Updated dependencies for successful Apache + PHP compilation
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    make \
    libz-dev \
    libbz2-dev \
    libreadline-dev \
    libexpat1-dev \
    zlib1g-dev \
    libssl-dev \
    libapr1-dev \
    libaprutil1-dev \
    libpcre3-dev \
    php-cli \
    php-dev \
    libapache2-mod-php \
    && rm -rf /var/lib/apt/lists/*

# Fix OpenSSL Security Level for DS Compatibility
RUN sed -i 's/CipherString = DEFAULT@SECLEVEL=2/CipherString = DEFAULT@SECLEVEL=0/' /etc/ssl/openssl.cnf

# 1. Compile OpenSSL 1.0.2k from source (Enable SSLv3 for DS)
WORKDIR /tmp
RUN curl -L https://www.openssl.org/source/openssl-1.0.2k.tar.gz | tar -xzf - \
    && cd openssl-1.0.2k \
    && ./config --prefix=/usr --openssldir=/usr/lib/ssl enable-ssl2 enable-ssl3 no-shared \
    && make depend \
    && make -j$(nproc) \
    && make install

# 2. Compile PCRE 8.45 (Using SourceForge mirror as the original FTP is dead)
RUN curl -L https://sourceforge.net/projects/pcre/files/pcre/8.45/pcre-8.45.tar.bz2/download | tar -xjf - \
    && cd pcre-8.45 \
    && ./configure --prefix=/usr \
        --enable-unicode-properties \
        --enable-pcre16 \
        --enable-pcre32 \
        --enable-pcregrep-libz \
        --enable-pcregrep-libbz2 \
        --enable-pcretest-libreadline \
        --disable-static \
    && make -j$(nproc) \
    && make install

# 3. Compile Apache 2.4.48
# Note: Using Archive URLs to ensure they stay up
RUN curl -L https://archive.apache.org/dist/httpd/httpd-2.4.48.tar.gz | tar -xzf - \
    && mv httpd-2.4.48 httpd
RUN curl -L https://archive.apache.org/dist/apr/apr-1.7.0.tar.gz | tar -xzf - \
    && mv apr-1.7.0 httpd/srclib/apr
RUN curl -L https://archive.apache.org/dist/apr/apr-util-1.6.1.tar.gz | tar -xzf - \
    && mv apr-util-1.6.1 httpd/srclib/apr-util

RUN cd httpd && ./configure \
    --prefix=/usr/local/apache \
    --with-included-apr \
    --enable-ssl \
    --with-ssl=/usr/lib/ssl \
    --enable-ssl-staticlib-deps \
    --enable-mods-static=ssl \
    --enable-modules=all \
    --enable-so \
    && make -j$(nproc) \
    && make install

# Create necessary directories
RUN mkdir -p /usr/local/apache/certs /var/www

# Copy your local files into the image
# Ensure these folders exist in your GitHub repo!
COPY ./sites/ /var/www/
COPY ./certs/ /usr/local/apache/certs/
COPY ./certs/ /usr/local/apache/certs/p
COPY ./configs/apache/ /usr/local/apache/conf/
COPY ./entrypoint.sh /srv/

RUN chmod +x /srv/entrypoint.sh

EXPOSE 80/tcp 443/tcp 53/tcp 53/udp

WORKDIR /usr/local/apache
CMD ["/srv/entrypoint.sh"]
