#!/bin/bash

/usr/src/chaosd/chaosd server &
/payment/app -port=80
