FROM debian:bullseye-slim

# Update packages and install necessary dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpcre3-dev \
    zlib1g-dev \
    libssl-dev \
    wget \
    libgeoip-dev \
    git \
    curl \
    autoconf \
    libtool \
    pkg-config \
    libmaxminddb0 \
    libmaxminddb-dev \
    mmdb-bin

# Download and compile the ngx_http_geoip2_module
RUN git clone https://github.com/leev/ngx_http_geoip2_module /usr/src/ngx_http_geoip2_module

# Download and extract Nginx source to compile GeoIP2 as a dynamic module
RUN wget http://nginx.org/download/nginx-1.18.0.tar.gz
RUN tar -xzf nginx-1.18.0.tar.gz
WORKDIR /nginx-1.18.0
RUN ./configure --with-compat --add-dynamic-module=/usr/src/ngx_http_geoip2_module
RUN make modules
RUN make install

RUN ln -s /usr/local/nginx/sbin/nginx /usr/sbin/nginx

# Move the module to the appropriate directory
RUN mkdir /usr/share/nginx/
RUN mkdir /usr/share/nginx/modules/
RUN cp objs/ngx_http_geoip2_module.so /usr/share/nginx/modules/

RUN apt-get remove --purge -y build-essential git wget && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /nginx-1.18.0 /ngx_http_geoip2_module
# Copy GeoIP2 databases
COPY nginx.conf /etc/nginx/nginx.conf
COPY GeoLite2-Country.mmdb /usr/share/GeoIP/
CMD ["nginx", "-c", "/etc/nginx/nginx.conf", "-g", "daemon off;"]
