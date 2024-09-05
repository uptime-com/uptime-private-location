#!/usr/bin/env bash

docker run --rm --detach \
    --env UPTIME_API_TOKEN="<YOUR_UPTIME_API_TOKEN>" \
    --shm-size=2048m \
    --mount type=volume,dst=/usr/local/nagios/var,src=uptime-nagios-var \
    --mount type=volume,dst=/home/uptime/var,src=uptime-var \
    --mount type=volume,dst=/home/uptime/logs,src=uptime-logs \
    --tmpfs /home/uptime/run:uid=1000,gid=1000 \
    --hostname localhost \
    uptimecom/uptime-private-location:latest
