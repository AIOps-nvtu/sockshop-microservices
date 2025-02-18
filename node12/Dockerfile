FROM openjdk:11 AS builder

USER 0
#RUN mkdir -p /src/ && cd /src/ \
#    && apt install -y git \
#    && git clone https://github.com/ocp-power-demos/sock-shop-orders \
#    && mv sock-shop-orders orders

# Decided to split the steps here to avoid rebuilding/cloning needlessly.

# RUN cd /src/orders && mvn clean package -DskipTests && find . -iname '*.jar'

RUN apt install -y tar gzip \
    && curl -L -o o.tgz "https://github.com/google/go-containerregistry/releases/download/v0.15.2/go-containerregistry_Linux_$(arch | sed 's|aarch64|arm64|g').tar.gz" \
    && tar xvf o.tgz \
    && ./crane export weaveworksdemos/orders:0.4.7 x.tar \
    && tar xvf x.tar usr/src/app/app.jar

USER 1001

FROM ubuntu:noble

ENV     SERVICE_USER=myuser \
    SERVICE_UID=10001 \
    SERVICE_GROUP=mygroup \
    SERVICE_GID=10001

USER 0
RUN apt update -y \
    && apt install -y curl wget tzdata openssl ca-certificates fontconfig gzip tar findutils ipset iptables iproute2 openjdk-11-jdk maven \
    && groupadd -r -g ${SERVICE_GID} ${SERVICE_GROUP} \
    && useradd -r -u ${SERVICE_UID} -g ${SERVICE_GROUP} -m -d /home/${SERVICE_USER} -s /sbin/nologin ${SERVICE_USER}

WORKDIR /
EXPOSE 8126

# Download and install chaosd to /usr/src/chaosd
RUN mkdir -p /usr/src/chaosd \
    && curl -Lo /usr/src/chaosd/chaosd.tar.gz https://mirrors.chaos-mesh.org/chaosd-latest-linux-amd64.tar.gz \
    && tar -zxvf /usr/src/chaosd/chaosd.tar.gz -C /usr/src/chaosd --strip-components=1 \
    && chmod +x /usr/src/chaosd/chaosd \
    && rm -f /usr/src/chaosd/chaosd.tar.gz
#    && chown -R ${SERVICE_USER}:${SERVICE_GROUP} /usr/src/chaosd
# && chmod -R 777 /usr/src/chaosd/db

# Set CHAOSD_HOME to point to /usr/src/chaosd/db
ENV CHAOSD_HOME=/usr/src/chaosd/db
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/

COPY --from=builder /usr/src/app/*.jar /opt/app.jar
RUN     chown -R ${SERVICE_USER}:${SERVICE_GROUP} /opt/app.jar

# Override a jaxb error as it's not included in JDK 11
RUN mkdir -p /opt/lib \
    && curl -L -o /opt/lib/jaxb-api-2.3.1.jar https://repo1.maven.org/maven2/javax/xml/bind/jaxb-api/2.3.1/jaxb-api-2.3.1.jar \
    && curl -L -o /opt/lib/jaxb-runtime-3.0.1.jar https://repo1.maven.org/maven2/org/glassfish/jaxb/jaxb-runtime/3.0.1/jaxb-runtime-3.0.1.jar \
    && wget -O /opt/lib/dd-java-agent.jar 'https://dtdg.co/latest-java-tracer' \
    && chmod 755 /opt/lib/*.jar

COPY orders-start.sh /
RUN chmod a+x /orders-start.sh
LABEL com.datadoghq.tags.service="sockshop-orders"
ENV DD_SERVICE=sockshop-orders
ENV DD_ENV=sockshop-apm
ENV DD_LOGS_INJECTION=true
USER root

CMD ["/orders-start.sh"]
