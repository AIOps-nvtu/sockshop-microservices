FROM weaveworksdemos/front-end:0.3.12 AS base

# Use Ubuntu as the base image
FROM ubuntu:noble AS stage-1

# Remove conflicting package and install dependencies, including Node.js 20
RUN apt update -y \
    && apt install -y curl gnupg2 \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt install -y nodejs tzdata openssl ca-certificates fontconfig gzip tar findutils ipset iptables iproute2 \
    && node -v \
    && npm -v \
    && apt clean all

# Set working directory
WORKDIR /front-end

# Copy application files from the base image
COPY --from=base / /front-end/

# Install Chaosd
RUN mkdir -p /usr/src/chaosd \
    && curl -Lo /usr/src/chaosd/chaosd.tar.gz https://mirrors.chaos-mesh.org/chaosd-latest-linux-amd64.tar.gz \
    && tar -zxvf /usr/src/chaosd/chaosd.tar.gz -C /usr/src/chaosd --strip-components=1 \
    && chmod +x /usr/src/chaosd/chaosd \
    && rm -f /usr/src/chaosd/chaosd.tar.gz

# Service user and group setup
ENV SERVICE_USER=myuser \
    SERVICE_UID=10001 \
    SERVICE_GROUP=mygroup \
    SERVICE_GID=10001

# Create user and group before `chown`
RUN groupadd -r -g ${SERVICE_GID} ${SERVICE_GROUP} \
    && useradd -r -u ${SERVICE_UID} -g ${SERVICE_GROUP} -m -d /home/${SERVICE_USER} -s /sbin/nologin ${SERVICE_USER}

RUN apt install -y sudo \
    && echo "myuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/myuser
# Install su from util-linux package
RUN apt install -y util-linux \
    && apt clean all

# Verify Node.js version and install npm@11
RUN node -v \
    && npm -v \
    && npm install -g npm@11
RUN chmod 755 /etc/passwd
RUN chmod 755 /etc/group

RUN mkdir -p /opt/app-root/src/.npm \
    && npm config set strict-ssl false \
    && npm install -g yarn@1.22.19 \
    && chown -R myuser:mygroup /opt/app-root/src/ \
    && chown -R myuser:mygroup /front-end/usr/src/

# Copy the startup script
COPY front-end-start.sh /
# Ensure the script is executable
RUN chmod +x /front-end-start.sh
RUN cd /front-end/usr/src/app \
    && npm install dd-trace --save \
    && npm install @datadog/browser-rum --save \
    && sed -i "1s/^/const tracer = require('dd-trace').init({env: 'sockshop-apm', service: 'sockshop-frontend', version: '0.0.3'});\n/" server.js
#    && sed -i "1s/^/import { core } from 'lodash';\n/" server.js
#    && cat /datadog.js server.js > temp.js \
#    && cat temp.js > server.js \
#    && rm temp.js

ENV DD_ENV=sockshop-apm
ENV DD_SERVICE=sockshop-frontend
ENV DD_LOGS_INJECTION=true
ENV DD_TRACE_STARTUP_LOGS=true
ENV DD_RUNTIME_METRICS_ENABLED=true
ENV DD_VERSION=0.0.2
USER root

# Run the start script
CMD ["/front-end-start.sh"]
