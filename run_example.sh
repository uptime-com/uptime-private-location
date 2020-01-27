#!/usr/bin/env bash

docker run -it \
    --env UPTIME_API_TOKEN="YOUR_API_TOKEN" \
    --mount type=bind,source=/sys/fs/cgroup,target=/sys/fs/cgroup \
    --mount type=volume,dst=/usr/local/nagios/etc/hosts,src=uptime-nagios-hosts \
    --mount type=volume,dst=/usr/local/nagios/var/,src=uptime-nagios-var \
    --mount type=volume,dst=/home/webapps/uptime/logs/,src=uptime-logs \
    --mount type=volume,dst=/home/webapps/uptime/data/,src=uptime-data \
    --security-opt seccomp=./seccomp-config.json \
    --hostname localhost \
    uptimecom/uptime-private-location:latest
