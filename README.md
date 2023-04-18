# Uptime.com Private Location Monitoring Management

Use this README for technical requirements and CLI-based commands and troubleshooting.

For pre-container setup, account prerequisites, and UI-based support, see our article [Getting Started with Private Location Monitoring](https://support.uptime.com/hc/en-us/articles/360012622239-Getting-Started-with-Private-Location-Monitoring).


## Technical Requirements

- 1GB RAM (2-3 GB is recommended) for the container to successfully run multiple transaction checks
- 15 GB of free disk space (image size is ~3 GB)
- 2 CPU cores
- Write permissions to the machine’s drive

## Prerequisites

1. Docker v18+
2. Linux Ubuntu 20.04+

    a. **Please note**: Linux kernel 4.x or 5.x required; Windows Hosts (Docker host, WSL, or VirtualBox) are not supported.

3. Access to Uptime.com private Docker repository (requested via Support, see [article](https://support.uptime.com/hc/en-us/articles/360012622239-Getting-Started-with-Private-Location-Monitoring#prerequisites_account)).
4. API Key for each probe server (supplied via Support, see [article](https://support.uptime.com/hc/en-us/articles/360012622239-Getting-Started-with-Private-Location-Monitoring#prerequisites_pre_container)).

## Installation Instructions

1. Download raw `seccomp-config.json` file [here](https://raw.githubusercontent.com/uptime-com/uptime-private-location/master/seccomp-config.json), right click “Save Page As…”, save to working directory
2. Login with Docker credentials via `docker login`
3. Pull latest image 2.5 via `docker pull uptimecom/uptime-private-location:2.5`
4. Start the container via

	```
	docker run -it \
    --env UPTIME_API_TOKEN="YOUR_UPTIME_API_TOKEN" \
    --shm-size=2048m \
    --mount type=volume,dst=/usr/local/nagios/etc/hosts,src=uptime-nagios-hosts \
    --mount type=volume,dst=/usr/local/nagios/var/,src=uptime-nagios-var \
    --mount type=volume,dst=/home/webapps/uptime/logs/,src=uptime-logs \
    --mount type=volume,dst=/home/webapps/uptime/data/,src=uptime-data \
    --security-opt seccomp=./seccomp-config.json \
    --hostname localhost \
    uptimecom/uptime-private-location:2.5
	```

**Please note**: Directly following container start, some tasks need time to settle. Some reconfiguration or stalled check detection errors may occur, but these should correct within ~1 hour after container start/restart.

### Using a Proxy Server

To connect to a proxy server, make sure that the proxy is configured in the Docker client as described in the [Official Docker Guide](https://docs.docker.com/network/proxy/).
Once configured, confirm that the container can access `internal.uptime.com:443` as well as `https://sqs.us-east-2.amazonaws.com/`

## Usage Commands (via CLI)

### Stopping the Container

1. Get the PID of a running container via `docker ps`
2. Run `docker kill PID_OF_THE_RUNNING_CONTAINER`

### Create `backup.tar` log file

1. Get the PID of a running container via `docker ps`
2. Run `docker run --rm --volumes-from RUNNING_CONTAINER_PID -v $(pwd):/backup ubuntu:latest tar -cvf /backup/backup.tar /home/webapps/uptime /usr/local/nagios`

### Pull Latest Image

**Please note**: Containers running outdated images (2.4 or less) may experience errors. 

1. Login via `docker login`
2. Run `docker pull uptimecom/uptime-private-location:2.5`

## Troubleshooting (via CLI)

Check the status of a running container in a JSON payload via exposed port and HTTP(s) call, or via CLI:

### Network/HTTP(s) Call

1. Stop the container (if running)
2. Check the status of a running container in a JSON payload via exposed port `8003` and HTTP(s) call, or via CLI:

	```
	docker run -it \
    --env UPTIME_API_TOKEN="YOUR_UPTIME_API_TOKEN" \
    --shm-size=2048m \
    --mount type=volume,dst=/usr/local/nagios/etc/hosts,src=uptime-nagios-hosts \
    --mount type=volume,dst=/usr/local/nagios/var/,src=uptime-nagios-var \
    --mount type=volume,dst=/home/webapps/uptime/logs/,src=uptime-logs \
    --mount type=volume,dst=/home/webapps/uptime/data/,src=uptime-data \
    --security-opt seccomp=./seccomp-config.json \
    --hostname localhost \
    -p 8003:443 \
    uptimecom/uptime-private-location:2.5
	```
3. Make HTTP(s) call to `https://localhost:8003/status`. Below is an example via cURL:

	```
	curl -k https://127.0.0.1:8003/status
	```

### CLI Command

1. Get the PID of a running container via `docker ps`
2. Run `docker exec -it PID_OF_THE_RUNNING_CONTAINER /status.sh`

### Status JSON Payload

Either method will return a JSON payload. An example payload is here:

	{
	   "details": {
	      "check_load": {
	         "status": "OK",
	         "description": "OK - load average: 0.16, 0.09, 0.03"
	      },
	      "check_total_procs": {
	         "status": "OK",
	         "description": "PROCS OK: 37 processes | procs=37;500;750;0;\n"
	      },
	      "check_nag": {
	         "status": "OK",
	         "description": "PROCS OK: 6 processes"
	      },
	      "check_mem": {
	         "status": "OK",
	         "description": "OK - 77.5% (1586788 kB) free."
	      },
	      "check_txn_manager": {
	         "status": "OK",
	         "description": "OK - 0 checks executed, 0 waiting, 0 declined"
	      },
	      "check_alert_queue": {
	         "status": "OK",
	         "description": "OK - 1 files in dir\n"
	      },
	      "check_send_alert_errors": {
	         "status": "OK",
	         "description": "OK - No errors found\n"
	      },
	      "check_perfdata_log": {
	         "status": "ERROR",
	         "description": "WARNING - Unable to match pattern: ### WEB API CALL COMPLETE"
	      },
	      "check_reconfig_log": {
	         "status": "ERROR",
	         "description": "WARNING - Unable to match pattern: ### CHECK FOR CONFIG UPDATE"
	      },
	      "check_stalled_check_detection_log": {
	         "status": "ERROR",
	         "description": "WARNING - Unable to match pattern: ### STALLED CHECK"
	      },
	      "last_check_times": {
	         "status": "OK",
	         "description": "OK: Last check ran 0:00:07 secs ago at 2020-01-15 16:15:56 UTC"
	      }
	   },
	   "status": "ERROR",
	   "description": "One or more checks have returned errors."
	}

---

For further troubleshooting help, see our [support article](https://support.uptime.com/hc/en-us/articles/360012622239-Getting-Started-with-Private-Location-Monitoring) or contact <support@uptime.com>


## Kubernetes

While not officially supported, a sample kubernetes configuration may be found
in `k8s-sample.yaml` for reference.
