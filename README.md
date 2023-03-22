# Uptime.com Private Location Monitoring Management

Use this README for technical requirements and CLI-based commands and troubleshooting.

For pre-container setup, account prerequisites, and UI-based support, see our article [Getting Started with Private Location Monitoring](https://support.uptime.com/hc/en-us/articles/360012622239-Getting-Started-with-Private-Location-Monitoring).


## Technical Requirements

- 1GB RAM (2-4 GB is recommended for the container to successfully run multiple transaction checks)
- 15 GB of free disk space (uncompressed image size is ~2 GB)
- 2 CPU cores
- Write permissions to the machine’s drive


## Prerequisites

1. Docker v18+
2. Linux Ubuntu 20.04+

    a. **Please note**: Linux kernel 4.x or 5.x required; Windows Hosts (Docker host, WSL, or VirtualBox) are not officially supported.

3. Access to Uptime.com private Docker repository (requested via Support, see [article](https://support.uptime.com/hc/en-us/articles/360012622239-Getting-Started-with-Private-Location-Monitoring#prerequisites_account)).

4. API Token for each probe server (supplied via Support, see [article](https://support.uptime.com/hc/en-us/articles/360012622239-Getting-Started-with-Private-Location-Monitoring#prerequisites_pre_container)).


## Installation Instructions

1. Login with Docker credentials via `docker login`
2. Pull latest image via `docker pull uptimecom/uptime-private-location:X.Y`
3. Start the container via

	```
	docker run --rm --detach \
    --env UPTIME_API_TOKEN="<YOUR_UPTIME_API_TOKEN>" \
    --shm-size=2048m \
    --mount type=volume,dst=/usr/local/nagios/etc/hosts,src=uptime-nagios-hosts \
    --mount type=volume,dst=/usr/local/nagios/var,src=uptime-nagios-var \
    --mount type=volume,dst=/home/uptime/logs,src=uptime-logs \
    --mount type=volume,dst=/home/uptime/alerts,src=uptime-alerts \
    --hostname localhost \
    uptimecom/uptime-private-location:X.Y
	```

**Please note**: Directly following container start, some tasks need time to settle. Some reconfiguration or stalled check detection errors may occur, but these should correct within ~1 hour after container start/restart.


### Using a Proxy Server

To connect to a proxy server, make sure that the proxy is configured in the Docker client as described in the [Official Docker Guide](https://docs.docker.com/network/proxy/).
Once configured, confirm that the container can access `internal.uptime.com:443` as well as `https://sqs.us-east-2.amazonaws.com/`


## Usage Commands (via CLI)

### Stopping the Container

1. Get the PID of a running container via `docker ps`
2. Run `docker stop <PID_OF_THE_RUNNING_CONTAINER>`


### Update to Latest Image

**Please note**: Containers running outdated images may experience errors.

1. Check for the latest version number at [Dockerhub](https://hub.docker.com/repository/docker/uptimecom/uptime-private-location/tags?page=1&ordering=last_updated)
2. Login via `docker login`
3. Run `docker pull uptimecom/uptime-private-location:X.Y`


## Troubleshooting

### Getting Private Location Status (via CLI)
Check the status of a running container in a JSON payload via the CLI.

**Note:** It is expected that some of these checks may fail upon start/restart, and they should clear within 60 minutes.

1. Get the PID of a running container via `docker ps`
2. Run `docker exec <PID_OF_THE_RUNNING_CONTAINER> /home/uptime/status.sh`

   If you have `jq` installed, you can get pretty output as well:
   `docker exec <PID_OF_THE_RUNNING_CONTAINER> /home/uptime/status.sh | jq`


### Create a `backup.tgz` log file for troubleshooting
1. Get the PID of a running container via `docker ps`
2. Run `docker run --rm --volumes-from <RUNNING_CONTAINER_PID> -v $(pwd):/backup ubuntu:latest tar -zcvf /backup/backup.tgz /home/uptime/logs /usr/local/nagios/etc /usr/local/nagios/var`
3. Send the log file tarball to Uptime.com support for analysis.


### Further Assistance
For further troubleshooting help, see our [support article](https://support.uptime.com/hc/en-us/articles/360012622239-Getting-Started-with-Private-Location-Monitoring) or contact <support@uptime.com>
