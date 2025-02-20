FROM jokernvt/sockshop-catalogue:latest AS base

# Stage 2: Use Red Hat UBI Minimal as the final base image
FROM ubuntu:noble AS stage-1

# Remove conflicting package and install dependencies, including Node.js 20
RUN apt update -y \
    && apt install -y curl wget gnupg2 tzdata openssl ca-certificates fontconfig gzip tar findutils ipset iptables iproute2 \
    && apt clean all

# Copy Payment Service binary and dependencies from `weaveworksdemos/catalogue:0.4.3`
WORKDIR /catalogue
COPY --from=base /app /catalogue/
COPY --from=base /images/ /catalogue/images/

# Install Chaosd
RUN mkdir -p /usr/src/chaosd \
    && mkdir -p /usr/src/chaosd/db \
    && curl -Lo /usr/src/chaosd/chaosd.tar.gz https://mirrors.chaos-mesh.org/chaosd-latest-linux-amd64.tar.gz \
    && tar -zxvf /usr/src/chaosd/chaosd.tar.gz -C /usr/src/chaosd --strip-components=1 \
    && chmod +x /usr/src/chaosd/chaosd \
    && chown -R ${SERVICE_USER}:${SERVICE_GROUP} /usr/src/chaosd \
    && chmod -R 777 /usr/src/chaosd/db \
    && rm -f /usr/src/chaosd/chaosd.tar.gz

ENV CHAOSD_HOME=/usr/src/chaosd/db

# Service user and group setup
ENV SERVICE_USER=myuser \
    SERVICE_UID=10001 \
    SERVICE_GROUP=mygroup \
    SERVICE_GID=10001

RUN groupadd -r -g ${SERVICE_GID} ${SERVICE_GROUP} \
    && useradd -r -u ${SERVICE_UID} -g ${SERVICE_GROUP} -m -d /home/${SERVICE_USER} -s /sbin/nologin ${SERVICE_USER}

RUN apt install -y sudo \
    && echo "myuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/myuser
# Install su from util-linux package
RUN apt install -y util-linux \
    && apt clean all

RUN chmod 755 /etc/passwd
RUN chmod 755 /etc/group

# Set permissions for the catalogue service
RUN chmod +x /catalogue/app \
    && chown -R ${SERVICE_USER}:${SERVICE_GROUP} /catalogue

# Copy custom startup script
COPY catalogue-start.sh /catalogue-start.sh
RUN chmod +x /catalogue-start.sh
ENV DD_ENV=sockshop-apm
ENV DD_SERVICE=sockshop-catalogue
ENV DD_RUNTIME_METRICS_ENABLED=true
ENV DD_LOGS_INJECTION=true
USER root

# Start the catalogue service and Chaosd
CMD ["/catalogue-start.sh"]
