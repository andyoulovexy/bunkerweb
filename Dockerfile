FROM nginx:stable-alpine AS builder

COPY nginx-keys/ /tmp/nginx-keys
COPY compile.sh /tmp/compile.sh
RUN chmod +x /tmp/compile.sh && \
    /tmp/compile.sh && \
    rm -rf /tmp/*

FROM nginx:stable-alpine

COPY --from=builder /*.so /usr/local/nginx/modules/
COPY entrypoint.sh /opt/entrypoint.sh
COPY confs/ /opt/confs
COPY scripts/ /opt/scripts
COPY fail2ban/ /opt/fail2ban
COPY logs/ /opt/logs
COPY lua/ /opt/lua

RUN apk --no-cache add php7-fpm certbot libstdc++ libmaxminddb geoip pcre yajl fail2ban clamav apache2-utils rsyslog openssl lua libgd && \
    chmod +x /opt/entrypoint.sh /opt/scripts/* && \
    mkdir /opt/entrypoint.d

VOLUME /www /http-confs /server-confs /modsec-confs /modsec-crs-confs

EXPOSE 80/tcp 443/tcp

ENTRYPOINT ["/opt/entrypoint.sh"]
