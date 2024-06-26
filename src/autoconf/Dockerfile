FROM python:3.12.2-alpine3.19@sha256:25a82f6f8b720a6a257d58e478a0a5517448006e010c85273f4d9c706819478c as builder

# Export var for specific actions on linux/arm/v7
ARG TARGETPLATFORM

# Install python dependencies
RUN apk add --no-cache build-base libffi-dev postgresql-dev cargo

# Copy python requirements
COPY src/deps/requirements.txt /tmp/requirements-deps.txt
COPY src/common/gen/requirements.txt /tmp/req/requirements-gen.txt
COPY src/common/db/requirements.txt /tmp/req/requirements-db.txt
COPY src/common/db/requirements.txt.armv7 /tmp/req/requirements-db.txt.armv7

WORKDIR /usr/share/bunkerweb

# Install python requirements
RUN export MAKEFLAGS="-j$(nproc)" && \
  if [ "$TARGETPLATFORM" = "linux/arm/v7" ] ; then mv /tmp/req/requirements-db.txt.armv7 /tmp/req/requirements-db.txt ; fi && \
  pip install --no-cache-dir --require-hashes --break-system-packages -r /tmp/requirements-deps.txt && \
  pip install --no-cache-dir --require-hashes --target deps/python $(for file in $(ls /tmp/req/requirements*.txt) ; do echo "-r ${file}" ; done | xargs)

# Copy files
# can't exclude specific files/dir from . so we are copying everything by hand
COPY src/autoconf autoconf
COPY src/common/api api
COPY src/common/cli cli
COPY src/common/core core
COPY src/common/db db
COPY src/common/helpers helpers
COPY src/common/settings.json settings.json
COPY src/common/utils utils

FROM python:3.12.2-alpine3.19@sha256:25a82f6f8b720a6a257d58e478a0a5517448006e010c85273f4d9c706819478c

# Set default umask to prevent huge recursive chmod increasing the final image size
RUN umask 027

# Copy dependencies
COPY --from=builder --chown=0:101 /usr/share/bunkerweb /usr/share/bunkerweb

WORKDIR /usr/share/bunkerweb

# Add autoconf user, drop bwcli, install runtime dependencies, create data folders and set permissions
RUN apk add --no-cache bash && \
  addgroup -g 101 autoconf && \
  adduser -h /var/cache/autoconf -g autoconf -s /bin/sh -G autoconf -D -H -u 101 autoconf && \
  cp helpers/bwcli /usr/bin/ && \
  echo "Docker" > INTEGRATION && \
  mkdir -p /etc/bunkerweb /var/tmp/bunkerweb /var/run/bunkerweb /var/log/bunkerweb /var/www && \
  mkdir -p /data/cache && ln -s /data/cache /var/cache/bunkerweb && \
  mkdir -p /data/lib && ln -s /data/lib /var/lib/bunkerweb && \
  mkdir -p /data/www && ln -s /data/www /var/www/html && \
  for dir in $(echo "configs plugins") ; do mkdir -p "/data/${dir}" && ln -s "/data/${dir}" "/etc/bunkerweb/${dir}" ; done && \
  for dir in $(echo "configs/http configs/stream configs/server-http configs/server-stream configs/default-server-http configs/default-server-stream configs/modsec configs/modsec-crs") ; do mkdir "/data/${dir}" ; done && \
  chown -R root:autoconf /data && \
  chmod -R 770 /data && \
  chown -R root:autoconf INTEGRATION /var/cache/bunkerweb /var/lib/bunkerweb /etc/bunkerweb /var/tmp/bunkerweb /usr/bin/bwcli && \
  chmod -R 770 /var/cache/bunkerweb /var/lib/bunkerweb /etc/bunkerweb /var/tmp/bunkerweb && \
  chmod 750 cli/main.py helpers/*.sh /usr/bin/bwcli autoconf/main.py deps/python/bin/* && \
  chmod 660 INTEGRATION

# Fix CVEs
# There are no CVEs to fix for this image

LABEL maintainer "Bunkerity <contact@bunkerity.com>"
LABEL version "1.5.6"
LABEL url "https://www.bunkerweb.io"

VOLUME /data

WORKDIR /usr/share/bunkerweb/autoconf

USER autoconf:autoconf

HEALTHCHECK --interval=10s --timeout=10s --start-period=30s --retries=6 CMD /usr/share/bunkerweb/helpers/healthcheck-autoconf.sh

CMD [ "python3", "main.py" ]
