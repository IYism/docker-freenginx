# FreeNGINX Docker Image

Built on **Rocky Linux 9**, this repository provides a custom Docker image for FreeNGINX, designed for high-performance web applications. It supports Lua scripting, PCRE2, and HTTP/3 with QUIC (via OpenSSL). 

## Features

- **Lua Scripting**: Use LuaJIT with the lua-nginx-module for dynamic request handling and flexible configuration.
- **PCRE2 Support**: Enhanced regular expressions with JIT compilation for improved performance.
- **QUIC and HTTP/3 Support**: Faster, reliable connections with modern protocols.
- **Brotli Compression**: Efficient compression for faster loading of static resources.

## Components

* **FreeNGINX**: Version `1.27.4`
* **zlib**: Version `1.3.1`
* **PCRE2**: Version `10.44`
* **geoip-api-c**: Version `1.6.12`
* **brotli**: Version `1.0.9`
* **ngx_brotli**: Version `master`
* **ngx_http_geoip2_module**: Version `3.4`
* **ngx_devel_kit**: Version `0.3.3`
* **OpenSSL**: Version `3.3.2`
* **LuaJIT**: Version `2.1-20240815`
* **echo-nginx-module**: Version `0.63`
* **lua-nginx-module**: Version `0.10.27`
* **lua-cjson**: Version `2.1.0.14`
* **lua-resty-core**: Version `0.1.29`
* **lua-resty-lock**: Version `0.09`
* **lua-resty-lrucache**: Version `0.14`

## Quick Start

### Build the Docker Image

Build the Docker image locally:
```sh
docker build -t freenginx:latest .
```

### Run the Container

You can run the FreeNGINX container using the following command:
```sh
docker run -d -p 80:80 -p 443:443 --name freenginx freenginx:latest
```

This will start FreeNGINX with the default configuration.

### Custom NGINX Configuration

You can customize the NGINX configuration by mounting your own configuration files into the container:
```sh
docker run -d \
  -v /etc/nginx:/etc/nginx \
  -v /data/public:/data/public \
  -p 80:80/tcp \
  -p 443:443/tcp \
  -p 443:443/udp \
  --name freenginx \
  freenginx:latest
```

You can also include custom Lua scripts, or other configuration options as needed.

## Contributing

Contributions are welcome! Please feel free to submit issues, pull requests, or suggestions.
