#!/usr/bin/env bash

docker run -it \
    --env UPTIME_API_TOKEN="YOUR_API_TOKEN" \
    --shm-size=2048m \
    --mount type=volume,dst=/usr/local/nagios/etc/hosts,src=uptime-nagios-hosts \
    --mount type=volume,dst=/usr/local/nagios/var/,src=uptime-nagios-var \
    --mount type=volume,dst=/home/webapps/uptime/logs/,src=uptime-logs \
    --mount type=volume,dst=/home/webapps/uptime/data/,src=uptime-data \
    --security-opt seccomp=./seccomp-config.json \
    --hostname localhost \
    uptimecom/uptime-private-location:2.1
