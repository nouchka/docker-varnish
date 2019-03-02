ARG  BASE_IMAGE=jessie-slim
FROM debian:${BASE_IMAGE}
LABEL maintainer Jean-Avit Promis "docker@katagena.com"
LABEL org.label-schema.vcs-url="https://github.com/nouchka/docker-varnish"

ARG VARNISH_VERSION=4
## MINOR_TAG=4.0.2-1+deb8u1 5.0.0-7+deb9u2 6.1.1-1+b1

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get -yq install --no-install-recommends varnish=${VARNISH_VERSION}.* cron=* && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY start.sh /start.sh

ENV VCL_CONFIG      /etc/varnish/default.vcl
ENV CACHE_SIZE      64m
ENV VARNISHD_PARAMS -p default_ttl=3600 -p default_grace=3600
ENV VARNISHD_PORT   80

RUN chmod 0755 /start.sh

CMD ["/start.sh"]
