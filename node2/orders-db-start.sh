#!/bin/bash

/usr/src/chaosd/chaosd server &
mongod --bind_ip 0.0.0.0