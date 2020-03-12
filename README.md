# Running an Uptime.com Private Location Monitoring Server with Docker

## Prerequisites

1. Docker v. 18+

2. Private docker hub repository credentials (supplied by Uptime.com)

3. API key (supplied by Uptime.com)

4. Download `seccomp-config.json` to the working directory.

5. Log in to your Docker Hub (use `docker login`) with your Docker Hub credentials

6. Pull the latest image (use `docker pull uptimecom/uptime-private-location:latest`)

## Running Your Monitoring Server

### Starting the Container

Start the container with the command:

```bash
docker run -it \
    --env UPTIME_API_TOKEN="YOUR_UPTIME_API_TOKEN" \
    --mount type=bind,source=/sys/fs/cgroup,target=/sys/fs/cgroup \
    --mount type=volume,dst=/usr/local/nagios/etc/hosts,src=uptime-nagios-hosts \
    --mount type=volume,dst=/usr/local/nagios/var/,src=uptime-nagios-var \
    --mount type=volume,dst=/home/webapps/uptime/logs/,src=uptime-logs \
    --mount type=volume,dst=/home/webapps/uptime/data/,src=uptime-data \
    --security-opt seccomp=./seccomp-config.json \
    --hostname localhost \
    uptimecom/uptime-private-location:latest

```

### Stopping the Container

- Get the PID of a running container with the command: `docker ps`
- Run `docker kill PID_OF_THE_RUNNING_CONTAINER`



## Memory and CPU requirements

- At least 1GB of memory is required (2-3GB is recommended) for the container to successfully run multiple transaction checks
- At least 2 CPU cores is recommended



## Status and Troubleshooting

It is possible to check the status of a running container, either by exposing a port and making a HTTP(S) call or by running a CLI command.

1. Using CLI

   - Get the PID of the running container by running the command `docker ps`
   - Run `docker exec -it PID_OF_THE_RUNNING_CONTAINER /status.sh`

2. Using a Network Call

   - Stop the container if it is running

   - Change the run script for the container and add an option to expose a port; the command below will expose a container's HTTP(S) port on local `8003` port:

     ```bash
     docker run -it \
         --env UPTIME_API_TOKEN="YOUR_UPTIME_API_TOKEN" \
         --mount type=bind,source=/sys/fs/cgroup,target=/sys/fs/cgroup \
         --mount type=volume,dst=/usr/local/nagios/etc/hosts,src=uptime-nagios-hosts \
         --mount type=volume,dst=/usr/local/nagios/var/,src=uptime-nagios-var \
         --mount type=volume,dst=/home/webapps/uptime/logs/,src=uptime-logs \
         --mount type=volume,dst=/home/webapps/uptime/data/,src=uptime-data \
         --security-opt seccomp=./seccomp-config.json \
         --hostname localhost \
         -p 8003:443 \
         uptimecom/uptime-private-location:latest
     ```

   - Make a HTTP(S) call to `https://localhost:8003/status`; below is a cURL example:

     ```bash
     curl -k https://127.0.0.1:8003/status
     ```

     

Both of these methods will return a JSON payload, in the form of:

```json
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
```

Note that right after the container starts, some tasks that need time to settle (e.g. reconfiguration or stalled check detection) may fail. They should all become OK within approximately one hour after the container started.