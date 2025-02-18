#!/bin/bash

/usr/src/chaosd/chaosd server &
cd /opt
java -javaagent:/opt/lib/dd-java-agent.jar -Ddd.logs.injection=true -Ddd.service=sockshop-carts -Ddd.env=sockshop-apm -Djava.security.egd=file:/dev/urandom -Dspring.zipkin.enabled=false -cp "/opt/app.jar:/opt/lib/*" org.springframework.boot.loader.JarLauncher --port=80

