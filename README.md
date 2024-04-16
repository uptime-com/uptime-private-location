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

1. Retrieve latest stable image version [here](https://hub.docker.com/repository/docker/uptimecom/uptime-private-location/general).
2. Login with Docker credentials via `docker login`
3. Pull latest image via `docker pull uptimecom/uptime-private-location:X.Y`
4. Start the container via

        docker run --rm --detach \
            --env UPTIME_API_TOKEN="<YOUR_UPTIME_API_TOKEN>" \
            --shm-size=2048m \
            --mount type=volume,dst=/usr/local/nagios/var,src=uptime-nagios-var \
            --mount type=volume,dst=/home/uptime/var,src=uptime-var \
            --mount type=volume,dst=/home/uptime/logs,src=uptime-logs \
            --tmpfs /home/uptime/run:uid=1000,gid=1000 \
            --hostname localhost \
            uptimecom/uptime-private-location:X.Y

**Please note**: Directly following container start, some tasks need time to settle.
Some reconfiguration or stalled check detection errors may occur, but these should
correct within ~1 hour after container start/restart.

### Older Docker Versions or Container Runtimes / Azure AKS
If you're running a Docker version older than 20.03 (check with `docker --version`),
you'll need to add the following parameter to the `docker run` command above:

    --sysctl net.ipv4.ip_unprivileged_port_start=0

Kubernetes on Azure AKS also requires a similar configuration at this time. Please see the
`k8s-sample.yaml` file and [Kubernetes section](#kubernetes-troubleshooting) below for details.


## Upgrading from 3.x

**IMPORTANT!**
Please note the run command and k8s sample configuration both contain important changes
compared to version 3.x and will need to be updated per this document and the corresponding
example files.


## Upgrading from 2.x

If you're currently running the 2.x line of Private Locations, there are some significant changes
in this version which should be taken in consideration:

- **IMPORTANT!** The data format has changed, so **you must** delete any existing volumes from 2.x and start
fresh when running 3.x for the first time.

- The `https://localhost:8003/status` URL no longer exists in 3.x, as it is not suitable for
monitoring whether a Private Location is fully functional. For monitoring, we recommend you use
one or more Heartbeat checks on Uptime.com, combined with a HTTP/API/Transaction check running
on the private location which hits the Heartbeat URL. It is still possible to run the status
script via the CLI as described below.

- The new version runs as UID=1000, rather than UID=0 (`root`) that the 2.x line ran as. Please
refrain from running it as a different user as it will fail. Ideally it should not be necessary
to specify which UID to run as, it will default to the correct user.

- It is **no longer necessary or recommended** to provide `--security-opt seccomp=./seccomp-config.json`
when running this new version. Please ensure you remove this from the startup command.

- Running Virus/Malware checks in a private location is no longer supported. This check does
not require any access to internal resources, so there is no benefit from running it from
a private location.


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

### Viewing Startup Logs
You can view the logs of the container's startup sequence to help diagnose errors.

1. Get the PID of a running container via `docker ps`
2. Run `docker logs -f <PID_OF_THE_RUNNING_CONTAINER>`

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


## Running in Kubernetes

It is possible to run the private location in Kubernetes, however please ensure you allocate
sufficient CPU and memory resources to the deployment, otherwise Chrome-based tranaction
checks will fail to run.

A sample kubernetes configuration for the private location is available in
`k8s-sample.yaml` for your reference.

### Kubernetes Troubleshooting

If you receive errors from the pod's log file indicating that apache failed to start
(e.g. `gave up: apache entered FATAL state`), try adding an additional `securityContext`
setting to your kubernetes yaml file, before `containers:`

    spec:
      ...

      template:
        ...

        spec:
          volumes:
            ...

          # *** Add this section *** #
          securityContext:
            sysctls:
              - name: net.ipv4.ip_unprivileged_port_start
                value: "0"

          containers:
            ...
