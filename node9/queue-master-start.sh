#!/bin/bash

/usr/src/chaosd/chaosd server &
# java -Djava.security.egd=file:/dev/urandom -Dspring.zipkin.enabled=false -cp "/opt/app.jar:/opt/lib/*" org.springframework.boot.loader.JarLauncher --port=80
java -javaagent:/opt/lib/dd-java-agent.jar -Ddd.logs.injection=true -Ddd.service=sockshop-queue-master -Ddd.env=sockshop-apm -Djava.security.egd=file:/dev/urandom -cp "/opt/app.jar:/opt/lib/*" org.springframework.boot.loader.JarLauncher --port=80
