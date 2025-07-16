FROM openjdk:11 AS builder

USER 0

# Original code pulled in a transitive dependency that made it very hard to use sprint-boot.

#RUN apt install -y git \
#    && mkdir -p /src/ \
#    && cd /src/ \
#    && git clone https://github.com/microservices-demo/carts

# Decided to split the steps here to avoid rebuilding/cloning needlessly.
#RUN cd /src/carts && mvn clean package -DskipTests

# Workaround: To update the code and pull out the jar we're using crane to grab the existing jar

RUN apt install -y tar gzip \
    && curl -L -o o.tgz "https://github.com/google/go-containerregistry/releases/download/v0.15.2/go-containerregistry_Linux_$(arch | sed 's|aarch64|arm64|g').tar.gz" \
    && tar xvf o.tgz \
    && ./crane export weaveworksdemos/carts:0.4.8 x.tar \
    && tar xvf x.tar usr/src/app/app.jar
#    && mv usr/src/app/app.jar app.jar

USER 1001

FROM ubuntu:noble

ENV     SERVICE_USER=myuser \
    SERVICE_UID=10001 \
    SERVICE_GROUP=mygroup \
    SERVICE_GID=10001

USER 0
RUN apt update -y \
    && apt install -y curl wget openjdk-11-jdk maven tzdata openssl ca-certificates fontconfig gzip tar findutils ipset iptables iproute2 \
    && groupadd -r -g ${SERVICE_GID} ${SERVICE_GROUP} \
    && useradd -r -u ${SERVICE_UID} -g ${SERVICE_GROUP} -m -d /home/${SERVICE_USER} -s /sbin/nologin ${SERVICE_USER}


# Create a dedicated directory for chaosd under /usr/src
RUN mkdir -p /usr/src/chaosd \
    && mkdir -p /usr/src/chaosd/db

# Download and install chaosd to /usr/src/chaosd
RUN curl -Lo /usr/src/chaosd/chaosd.tar.gz https://mirrors.chaos-mesh.org/chaosd-latest-linux-amd64.tar.gz \
    && tar -zxvf /usr/src/chaosd/chaosd.tar.gz -C /usr/src/chaosd --strip-components=1 \
    && chmod +x /usr/src/chaosd/chaosd \
    && rm -f /usr/src/chaosd/chaosd.tar.gz \
    && chown -R ${SERVICE_USER}:${SERVICE_GROUP} /usr/src/chaosd \
    && chmod -R 777 /usr/src/chaosd/db

# Set CHAOSD_HOME to point to /usr/src/chaosd/db
ENV CHAOSD_HOME=/usr/src/chaosd/db
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/

WORKDIR /
EXPOSE 8080
EXPOSE 31767


RUN mkdir -p /opt
COPY --from=builder /usr/src/app/app.jar /opt/app.jar
RUN     chown -R ${SERVICE_USER}:${SERVICE_GROUP} /opt/app.jar


# Override a jaxb error as it's not included in JDK 11
RUN mkdir -p /opt/lib \
    && curl -L -o /opt/lib/jaxb-api-2.3.1.jar https://repo1.maven.org/maven2/javax/xml/bind/jaxb-api/2.3.1/jaxb-api-2.3.1.jar \
    # && curl -L -o /opt/lib/jaxb-runtime-3.0.1.redhat-00001.jar https://maven.repository.redhat.com/ga/org/glassfish/jaxb/jaxb-runtime/3.0.1.redhat-00001/jaxb-runtime-3.0.1.redhat-00001.jar \
    && curl -L -o /opt/lib/jaxb-runtime-3.0.1.jar https://repo1.maven.org/maven2/org/glassfish/jaxb/jaxb-runtime/3.0.1/jaxb-runtime-3.0.1.jar \
    && wget -O /opt/lib/aws-opentelemetry-agent.jar 'https://github.com/aws-observability/aws-otel-java-instrumentation/releases/latest/download/aws-opentelemetry-agent.jar' \
    #    && wget -O /opt/lib/dd-java-agent.jar 'https://dtdg.co/latest-java-tracer' \
    && chmod 755 /opt/lib/*.jar

COPY carts-start.sh /
RUN chmod a+x /carts-start.sh

ENV OTEL_METRICS_EXPORTER=none \
    OTEL_LOGS_EXPORTER=none \
    OTEL_AWS_APPLICATION_SIGNALS_ENABLED=true \
    OTEL_AWS_APPLICATION_SIGNALS_EXPORTER_ENDPOINT=http://host.docker.internal:4316/v1/metrics \
    OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf \
    OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://host.docker.internal:4316/v1/traces \
    OTEL_RESOURCE_ATTRIBUTES="aws.log.group.names=APPLICATION-ApplicationInsights-sockshop,service.name=sockshop-carts"
#ENV DD_SERVICE=sockshop-carts
#ENV DD_ENV=sockshop-apm
#ENV DD_LOGS_INJECTION=true
#ENV DD_RUNTIME_METRICS_ENABLED=true

USER root

CMD ["/carts-start.sh"]