#!/bin/bash

cd /front-end/usr/src/app

# Start Chaosd in the background as root
/usr/src/chaosd/chaosd server &

# Switch to myuser and start npm
exec bash -c "exec su myuser -s /bin/sh -c 'npm start'"