#!/usr/bin/env bash

docker run --rm --detach \
    --env UPTIME_API_TOKEN="<YOUR_UPTIME_API_TOKEN>" \
    --shm-size=2048m \
    --mount type=volume,dst=/usr/local/nagios/etc/hosts,src=uptime-nagios-hosts \
    --mount type=volume,dst=/usr/local/nagios/var,src=uptime-nagios-var \
    --mount type=volume,dst=/home/uptime/logs,src=uptime-logs \
    --mount type=volume,dst=/home/uptime/alerts,src=uptime-alerts \
    --hostname localhost \
    uptimecom/uptime-private-location:3.2
