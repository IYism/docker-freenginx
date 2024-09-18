# Dockerfile - Rocky Linux 9
FROM rockylinux:9

LABEL maintainer="iYism <admin@iyism.com>"

ENV USER       nginx
ENV CONF_DIR   /etc/nginx
ENV DATA_DIR   /var/lib/nginx
ENV HOME_DIR   /opt/freenginx
ENV LUALIB     /opt/freenginx/lualib
ENV BUILD_DIR  /tmp/.build.freenginx

ENV ZLIB_VERSION            1.3.1
ENV PCRE2_VERSION           10.44
ENV OPENSSL_VERSION         3.3.2
ENV LUAJIT_VERSION          2.1-20240815
ENV FREENGINX_VERSION       1.27.4
ENV NGX_LUA_VERSION         0.10.27
ENV RESTY_CORE_VERSION      0.1.29
ENV RESTY_LRUCACHE_VERSION  0.14

# Switching to root to install the required packages
USER root

WORKDIR ${BUILD_DIR}

RUN set -x \
# Add nginx user
    && getent group $USER >/dev/null || groupadd -r $USER -g 101 \
    && getent passwd $USER >/dev/null || useradd -r -u 101 -g $USER -s /sbin/nologin \
        -d ${DATA_DIR} -m -c "$USER user" $USER \
    && dnf install -y make gcc gcc-c++ perl \
        diffutils gd-devel libxslt-devel libxml2-devel \
# install zlib
    && curl -LO --output-dir ${BUILD_DIR} https://www.zlib.net/zlib-${ZLIB_VERSION}.tar.gz \
    && tar zxf zlib-${ZLIB_VERSION}.tar.gz \
    && cd zlib-${ZLIB_VERSION} \
    && ./configure --prefix=${HOME_DIR}/zlib \
    && make -j`nproc` \
    && make install \
    && cd ${BUILD_DIR} \
# install pcre2
    && curl -LO --output-dir ${BUILD_DIR} https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE2_VERSION}/pcre2-${PCRE2_VERSION}.tar.gz \
    && tar zxf pcre2-${PCRE2_VERSION}.tar.gz \
    && cd pcre2-${PCRE2_VERSION} \
    && ./configure --prefix=${HOME_DIR}/pcre2 \
        --enable-jit \
        --enable-pcre2-16 \
        --enable-pcre2-32 \
    && make -j`nproc` \
    && make install \
    && cd ${BUILD_DIR} \
# install openssl
    && curl -LO --output-dir ${BUILD_DIR} https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz \
    && tar zxf openssl-${OPENSSL_VERSION}.tar.gz \
    && cd openssl-${OPENSSL_VERSION} \
    && ./Configure --prefix=${HOME_DIR}/openssl33 \
        shared zlib \
        --libdir=lib64 \
        -I${HOME_DIR}/zlib/include \
        -L${HOME_DIR}/zlib/lib \
        -Wl,-rpath,${HOME_DIR}/zlib/lib:${HOME_DIR}/openssl33/lib64 \
    && make -j`nproc` \
    && make install_sw \
    && cd ${BUILD_DIR} \
    && ls ${HOME_DIR}/openssl33/ \
# install luajit
    && curl -LJO --output-dir ${BUILD_DIR} https://github.com/openresty/luajit2/archive/refs/tags/v${LUAJIT_VERSION}.tar.gz \
    && tar zxf luajit2-${LUAJIT_VERSION}.tar.gz \
    && cd luajit2-${LUAJIT_VERSION} \
    && make -j`nproc` XCFLAGS='-DLUAJIT_ENABLE_GC64' \
    && make install PREFIX=${HOME_DIR}/luajit \
    && cd ${BUILD_DIR} \
# download lua-nginx-module
    && curl -LJO --output-dir ${BUILD_DIR} https://github.com/openresty/lua-nginx-module/archive/refs/tags/v${NGX_LUA_VERSION}.tar.gz \
    && tar zxf lua-nginx-module-${NGX_LUA_VERSION}.tar.gz \
    && cd ${BUILD_DIR} \
# install freenginx
    && curl -LO --output-dir ${BUILD_DIR} https://freenginx.org/download/freenginx-${FREENGINX_VERSION}.tar.gz \
    && tar zxf freenginx-${FREENGINX_VERSION}.tar.gz \
    && cd freenginx-${FREENGINX_VERSION} \
    && export LUAJIT_LIB=${HOME_DIR}/luajit/lib \
    && export LUAJIT_INC=${HOME_DIR}/luajit/include/luajit-2.1 \
    && ./configure \
       --prefix=${HOME_DIR}/nginx \
       --conf-path=${CONF_DIR}/nginx.conf \
       --sbin-path=/usr/sbin/nginx \
       --error-log-path=/var/log/nginx/error.log \
       --http-log-path=/var/log/nginx/access.log \
       --pid-path=/run/nginx.pid \
       --lock-path=/run/nginx.lock \
       --http-client-body-temp-path=${DATA_DIR}/client_temp \
       --http-proxy-temp-path=${DATA_DIR}/proxy_temp \
       --http-fastcgi-temp-path=${DATA_DIR}/fastcgi_temp \
       --http-uwsgi-temp-path=${DATA_DIR}/uwsgi_temp \
       --http-scgi-temp-path=${DATA_DIR}/scgi_temp \
       --user=$USER \
       --group=$USER \
       --with-compat \
       --with-file-aio \
       --with-threads \
       --with-http_addition_module \
       --with-http_auth_request_module \
       --with-http_dav_module \
       --with-http_flv_module \
       --with-http_gunzip_module \
       --with-http_gzip_static_module \
       --with-http_mp4_module \
       --with-http_random_index_module \
       --with-http_realip_module \
       --with-http_secure_link_module \
       --with-http_slice_module \
       --with-http_ssl_module \
       --with-http_stub_status_module \
       --with-http_sub_module \
       --with-http_v2_module \
       --with-http_v3_module \
       --with-http_xslt_module \
       --with-http_image_filter_module \
       --with-http_degradation_module \
       --with-stream \
       --with-stream_realip_module \
       --with-stream_ssl_module \
       --with-stream_ssl_preread_module \
       --with-pcre \
       --with-pcre-jit \
       --add-module=${BUILD_DIR}/lua-nginx-module-${NGX_LUA_VERSION} \
       --with-cc-opt="-O2 -DNGX_LUA_ABORT_AT_PANIC -I${HOME_DIR}/zlib/include -I${HOME_DIR}/pcre2/include -I${HOME_DIR}/openssl33/include" \
       --with-ld-opt="-Wl,-rpath,${HOME_DIR}/luajit/lib -L${HOME_DIR}/zlib/lib -L${HOME_DIR}/pcre2/lib -L${HOME_DIR}/openssl33/lib64 -Wl,-rpath,${HOME_DIR}/zlib/lib:${HOME_DIR}/pcre2/lib:${HOME_DIR}/openssl33/lib64" \
   && make -j`nproc` \
   && make install \
   && cd ${BUILD_DIR} \
# install lua-resty-core
    && curl -LJO --output-dir ${BUILD_DIR} https://github.com/openresty/lua-resty-core/archive/refs/tags/v${RESTY_CORE_VERSION}.tar.gz \
    && tar zxf lua-resty-core-${RESTY_CORE_VERSION}.tar.gz \
    && mkdir -p ${LUALIB} \
    && cp -fr lua-resty-core-${RESTY_CORE_VERSION}/lib/* ${LUALIB} \
    && cd ${BUILD_DIR} \
# install lua-resty-lrucache
    && curl -LJO --output-dir ${BUILD_DIR} https://github.com/openresty/lua-resty-lrucache/archive/refs/tags/v${RESTY_LRUCACHE_VERSION}.tar.gz \
    && tar zxf lua-resty-lrucache-${RESTY_LRUCACHE_VERSION}.tar.gz \
    && cp -fr lua-resty-lrucache-${RESTY_LRUCACHE_VERSION}/lib/* ${LUALIB} \
    && cd ${HOME_DIR} \
# clean tmp
    && rm -fr ${BUILD_DIR} \
    && dnf remove -y gcc gcc-c++ make perl \
    && dnf clean all

WORKDIR ${CONF_DIR}
EXPOSE 80

COPY nginx.conf /etc/nginx/nginx.conf

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]

STOPSIGNAL SIGQUIT
