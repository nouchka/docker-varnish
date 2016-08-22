#!/bin/bash

exec varnishd -F -f $VCL_CONFIG -s malloc,$CACHE_SIZE $VARNISHD_PARAMS -a 0.0.0.0:${VARNISHD_PORT}
