# Stage 1: Extract `weaveworksdemos/payment:0.4.3`
#FROM weaveworksdemos/payment:0.4.3 AS base
FROM jokernvt/sockshop-payment:latest AS base
#FROM jokernvt/sockshop-payment:delay AS base


FROM ubuntu:noble AS stage-1

RUN apt update -y \
    && apt install -y curl wget gnupg2 tzdata openssl ca-certificates fontconfig gzip tar findutils ipset iptables iproute2 \
    && apt clean all

WORKDIR /payment
COPY --from=base /app /payment/

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

# Set permissions for the payment service
RUN chmod +x /payment/app \
    && chown -R ${SERVICE_USER}:${SERVICE_GROUP} /payment

# Copy custom startup script
COPY payment-start.sh /payment-start.sh
RUN chmod +x /payment-start.sh
ENV DD_ENV=sockshop-apm
ENV DD_SERVICE=sockshop-payment
ENV DD_RUNTIME_METRICS_ENABLED=true
ENV DD_LOGS_INJECTION=true
ENV DD_VERSION=0.0.3
USER root

# Start the payment service and Chaosd
CMD ["/payment-start.sh"]
