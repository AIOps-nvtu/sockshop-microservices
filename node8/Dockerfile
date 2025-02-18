FROM jokernvt/sockshop-user:latest AS base

# Stage 2: Use Red Hat UBI Minimal as the final base image
FROM ubuntu:noble AS stage-1

# Remove conflicting package and install dependencies, including Node.js 20
RUN apt update -y \
    && apt install -y curl wget gnupg2 tzdata openssl ca-certificates fontconfig gzip tar findutils ipset iptables iproute2 \
    && apt clean all

# Copy Payment Service binary and dependencies from `weaveworksdemos/user:0.4.3`
WORKDIR /user
COPY --from=base /app /user/

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

# Set permissions for the user service
RUN chmod +x /user/app \
    && chown -R ${SERVICE_USER}:${SERVICE_GROUP} /user

# Copy custom startup script
COPY user-start.sh /user-start.sh
RUN chmod +x /user-start.sh
ENV DD_ENV=sockshop-apm
ENV DD_SERVICE=sockshop-user
ENV DD_RUNTIME_METRICS_ENABLED=true
ENV DD_LOGS_INJECTION=true
ENV MONGO_HOST=user-db:27017
ENV HATEAOS=user
ENV USER_DATABASE=mongodb
USER root

# Start the user service and Chaosd
CMD ["/user-start.sh"]
