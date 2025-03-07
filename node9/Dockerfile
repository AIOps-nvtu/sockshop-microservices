FROM openjdk:8 AS builder

USER 0

# Decided to split the steps here to avoid rebuilding/cloning needlessly.
RUN apt install -y tar gzip \
    && curl -L -o o.tgz "https://github.com/google/go-containerregistry/releases/download/v0.15.2/go-containerregistry_Linux_$(arch | sed 's|aarch64|arm64|g').tar.gz" \
    && tar xvf o.tgz \
    && ln -s /usr/lib/jvm/java-1.8-openjdk/jre/lib/amd64/server/libjvm.so /lib/libjvm.so \
    && ln -s /usr/lib/jvm/java-1.8-openjdk/lib/amd64/jli/libjli.so /lib/libjli.so \
    && ./crane export weaveworksdemos/queue-master:0.3.1 x.tar \
    && tar xvf x.tar usr/src/app/app.jar

USER 1001

FROM ubuntu:noble

ENV     SERVICE_USER=myuser \
    SERVICE_UID=10001 \
    SERVICE_GROUP=mygroup \
    SERVICE_GID=10001

USER 0
RUN apt update -y \
    && apt install -y curl wget openjdk-8-jdk openjdk-8-jre maven tzdata openssl ca-certificates fontconfig gzip tar findutils iproute2 ipset iptables \
    && groupadd -r -g ${SERVICE_GID} ${SERVICE_GROUP} \
    && useradd -r -u ${SERVICE_UID} -g ${SERVICE_GROUP} -m -d /home/${SERVICE_USER} -s /sbin/nologin ${SERVICE_USER}

WORKDIR /

# Download and install chaosd to /usr/src/chaosd
RUN mkdir -p /usr/src/chaosd \
    && curl -Lo /usr/src/chaosd/chaosd.tar.gz https://mirrors.chaos-mesh.org/chaosd-latest-linux-amd64.tar.gz \
    && tar -zxvf /usr/src/chaosd/chaosd.tar.gz -C /usr/src/chaosd --strip-components=1 \
    && chmod +x /usr/src/chaosd/chaosd \
    && rm -f /usr/src/chaosd/chaosd.tar.gz

# Set CHAOSD_HOME to point to /usr/src/chaosd/db
ENV CHAOSD_HOME=/usr/src/chaosd/db
ENV JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk
ENV PATH=$PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin

RUN mkdir -p /opt
COPY --from=builder /usr/src/app/*.jar /opt/app.jar
RUN     chown -R ${SERVICE_USER}:${SERVICE_GROUP} /opt/app.jar

# Override a jaxb error as it's not included in JDK 11
RUN mkdir -p /opt/lib \
    && wget -O /opt/lib/dd-java-agent.jar 'https://dtdg.co/latest-java-tracer' \
    && chmod 755 /opt/lib/*.jar \
    && ln -s /usr/lib/jvm/java-1.8-openjdk/jre/lib/amd64/server/libjvm.so /opt/lib/libjvm.so \
    && ln -s /usr/lib/jvm/java-1.8-openjdk/lib/amd64/jli/libjli.so /opt/lib/libjli.so

COPY queue-master-start.sh /
RUN chmod a+x /queue-master-start.sh
USER root

CMD ["/queue-master-start.sh"]