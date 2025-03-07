FROM mongo:5.0

RUN apt update -y \
    && apt install -y curl wget tzdata openssl ca-certificates fontconfig gzip tar findutils ipset iptables iproute2

RUN mkdir -p /usr/src/chaosd \
    && curl -Lo /usr/src/chaosd/chaosd.tar.gz https://mirrors.chaos-mesh.org/chaosd-latest-linux-amd64.tar.gz \
    && tar -zxvf /usr/src/chaosd/chaosd.tar.gz -C /usr/src/chaosd --strip-components=1 \
    && chmod +x /usr/src/chaosd/chaosd \
    && rm -f /usr/src/chaosd/chaosd.tar.gz

ENV CHAOSD_HOME=/usr/src/chaosd/db
COPY orders-db-start.sh /
RUN chmod +x /orders-db-start.sh \
    && chown -R root:root /data/db /data/configdb

EXPOSE 27017
USER root
ENV DD_SERVICE=sockshop-orders-db
ENV DD_ENV=sockshop-apm
ENV DD_VERSION=0.0.1

CMD ["/orders-db-start.sh"]