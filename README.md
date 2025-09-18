# Uptime.com Private Location Monitoring Management

Use this README for technical requirements and CLI-based commands and troubleshooting.

For pre-container setup, account prerequisites, and UI-based support, see our article [Getting Started with Private Location Monitoring](https://support.uptime.com/hc/en-us/articles/360012622239-Getting-Started-with-Private-Location-Monitoring).


## Documentation for Older Versions

- [v5.0 README](https://github.com/uptime-com/uptime-private-location/blob/v5.0/README.md)
- [v4.2 README](https://github.com/uptime-com/uptime-private-location/blob/v4.2/README.md)
- [v4.1 README](https://github.com/uptime-com/uptime-private-location/blob/v4.1/README.md)
- [v4.0 README](https://github.com/uptime-com/uptime-private-location/blob/v4.0/README.md)
- [v3.2 README](https://github.com/uptime-com/uptime-private-location/blob/v3.2/README.md)
- [v3.0 README](https://github.com/uptime-com/uptime-private-location/blob/v3.0/README.md)


## Table of Contents
- [Technical Requirements](#technical-requirements)
- [Prerequisites](#prerequisites)
- [Installation Instructions](#installation-instructions)
- [IPv6 Support](#ipv6-support)
- [Environment Variables](#environment-variables)
- [Ports](#ports)
- [Upgrading from 3.x](#upgrading-from-3x)
- [Upgrading from 2.x](#upgrading-from-2x)
- [Usage Commands (via CLI)](#usage-commands-via-cli)
- [Troubleshooting](#troubleshooting)
- [Running in Kubernetes](#running-in-kubernetes)
- [Running in Docker Compose](#running-in-docker-compose)
- [Changelog](#changelog)


## Technical Requirements

- 1GB RAM (2-4 GB is recommended for the container to successfully run multiple transaction checks)
- 15 GB of free disk space (uncompressed image size is ~2 GB)
- 2 CPU cores
- Write permissions to the machine’s drive


## Prerequisites

1. Docker v18+
2. Linux Ubuntu 20.04+ or compatible distribution.

   a. **Please note**: Linux kernel 4.x or 5.x required; Windows Hosts (Docker host, WSL, or VirtualBox) are not officially supported.

   b. While other platforms are not officially supported, some guidelines are provided below.

3. Access to Uptime.com private Docker repository (requested via Support, see [article](https://support.uptime.com/hc/en-us/articles/360012622239-Getting-Started-with-Private-Location-Monitoring#prerequisites_account)).

4. API Token for each probe server (supplied via Support, see [article](https://support.uptime.com/hc/en-us/articles/360012622239-Getting-Started-with-Private-Location-Monitoring#prerequisites_pre_container)).


## Installation Instructions

**Please note**: Directly following container start, some tasks need time to settle.
Some reconfiguration or stalled check detection errors may occur, but these should
correct within ~1 hour after container start/restart.

### Linux (Ubuntu 20.04+ or similar)

1.  Retrieve latest stable image version [here](https://hub.docker.com/repository/docker/uptimecom/uptime-private-location/general).
2.  Pull latest image via `docker pull uptimecom/uptime-private-location:latest`
3.  Start the container via

        docker run --detach \
            --env UPTIME_API_TOKEN="<YOUR_UPTIME_API_TOKEN>" \
            --restart unless-stopped \
            --shm-size=2048m \
            --mount type=volume,dst=/usr/local/nagios/var,src=uptime-nagios-var \
            --mount type=volume,dst=/home/uptime/var,src=uptime-var \
            --mount type=volume,dst=/home/uptime/logs,src=uptime-logs \
            --tmpfs /home/uptime/run:uid=1000,gid=1000 \
            --hostname localhost \
            uptimecom/uptime-private-location:latest

4.  If you need to stop and remove the container (e.g. to reset it):

        # Find the container's ID
        docker ps

        # Stop & remove the container & any related anonymous volumes
        docker rm -fv <container-id>


### Older Docker Versions or Container Runtimes / Azure AKS

If you're running a Docker version older than 20.03 (check with `docker --version`),
you'll need to add the following parameter to the `docker run` command above:

    --sysctl net.ipv4.ip_unprivileged_port_start=0

Kubernetes on Azure AKS also requires a similar configuration at this time. Please see the
`k8s-sample.yaml` file and [Kubernetes section](#kubernetes-troubleshooting) below for details.


### Running in PhotonOS 5.x

#### Deploying PhotonOS with Docker-in-Docker Setup

Vmware provides an official docker image of [Photon OS](https://hub.docker.com/_/photon)

    docker pull photon
    sudo docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock photon:latest

#### Installing Docker Inside PhotonOS Container

    tdnf install -y docker
    systemctl start docker
    systemctl enable docker

#### Start the container

Use the [docker run](#installation-instructions) command form the installation
instructions above.


### Running in Podman

Private Location Monitoring can also run in Podman, a Docker alternative.

#### Prerequisites
1. Podman v4.x.x+
2. Linux Ubuntu 20.04+

Installing Podman on Linux Ubuntu 20.04+

Update your system and install Podman:

```bash
sudo apt-get update
sudo apt-get -y install podman
```

You will be prompted to enter your Docker credentials.

Pull the latest Uptime.com private location image:

```bash
podman pull docker.io/uptimecom/uptime-private-location:latest
```

Once Podman is installed, you can run the Uptime.com private location container with
a similar command to the [docker run](#installation-instructions) above:

```bash
podman run --detach \
    ...
```

### Running on Windows Server

While Private Location Monitoring is not officially supported on Windows, you can run it through WSL 2 on Windows Server 2022.
(Note: You will need a dedicated server or a Windows VM server that supports nested virtualization to enable WSL 2 or Hyper-V.)

#### Running on Windows Server 2022 (with WSL 2)

To run Uptime.com Private Location Monitoring on Windows Server 2022, you need to enable WSL 2 and install a supported Linux distribution (e.g., Ubuntu 20.04):

1. Install WSL 2: Open PowerShell as Administrator and run:

```bash
wsl --install
```

2. Install a Linux distribution: Choose Ubuntu 20.04 LTS:

```bash
wsl --install -d Ubuntu-20.04
```

3. Set up Docker: Inside the WSL 2 terminal (Ubuntu), follow the [instructions](#installation-instructions) to install Docker.

For Windows Server 2019, since WSL 2 is not supported, you can use a Hyper-V Ubuntu VM to run it following the same procedure for Docker.


## IPv6 Support

The PLM supports IPv6, however some additional docker configuration is required to enable
IPv6 support for containers.

**Prerequisite:** A supported host system with outbound IPv6 enabled and operational.

Docker References:
- [Use IPv6 networking](https://docs.docker.com/engine/daemon/ipv6/)
- [Networks](https://docs.docker.com/reference/compose-file/networks/)

### IPv6 Setup Guide

1. Enable IPv6 in the Docker daemon configuration. Edit `/etc/docker/daemon.json`:

        {
          "ipv6": true,
          "fixed-cidr-v6": "fd00:abcd::/64",
          "ip6tables": true,
          "experimental": true
        }

2. Restart Docker:

        sudo systemctl daemon-reload
        sudo systemctl restart docker

3. Tear down your Docker containers & networks, and recreate them.

### IPv6 in Docker Compose

If you're using Docker Compose to run the PLM, some additional configuration is required
in your `compose.yaml`:

    networks:
      default:
        enable_ipv6: true
        ipam:
          config:
            - subnet: fd00:abcf::/64


## Environment Variables

**Use --env for docker run or add as env in kubernetes yaml file.**

<table>
  <thead>
    <tr>
      <th style="text-align:center;">Name</th>
      <th style="text-align:center;">Default</th>
      <th style="text-align:center;">Description</th>
    </tr>
  <tbody>
    <tr >
      <td >UPTIME_TXN_LIMIT_BROWSERS</td>
      <td >3</td>
      <td >The number of Chrome instances to run in this private location. Running more transaction checks will require more instances, and subsequently use more resources (CPU and Memory). A rough maximum for this is 3 Chrome instances per CPU core + 2GB RAM.</td>
    </tr>
    <tr>
      <td >UPTIME_TXN_MAX_EXEC_TIME</td>
      <td >65000</td>
      <td >The maximum execution time of checks running in this private location. The default is usually sufficient unless you are running Extended Transaction checks whose runtime and timeout can exceed 60 seconds.</td>
    </tr>
    <tr>
      <td >UPTIME_NAGIOS_SERVICE_CHECK_TIMEOUT</td>
      <td >92000</td>
      <td >The maximum execution time of any check running in this private location. The default is sufficient unless you have increased UPTIME_TXN_MAX_EXEC_TIME , in which case you should set this value slightly larger than that.</td>
    </tr>
        <tr>
      <td >UPTIME_AVAILABLE_CPU_CORES</td>
      <td >auto-detected</td>
      <td >Specifies the number of CPU cores available to the Private Location container, auto-detected by default. This value is used for configuring check concurrency and internal status checks. We advise this value to be set accurately when running under Kubernetes or if the Private Location is reporting errors incorrectly (for example, reporting high load when the actual load is reasonable).</td>
    </tr>
  </tbody>
</table>


## Ports

The PLM requires outgoing HTTP(S) internet access on ports 80 and 443, plus access
to any services you would like it to monitor.

The PLM internally uses ports 8080, 8443 and 5666. It is possible to map
8443 back to the host to access the Nagios UI.


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
Once configured, confirm that the container can access `internal.uptime.com:443`,
`credentials.produs.upsentinel.net:443`, and also `https://sqs.us-east-2.amazonaws.com/`.


## Usage Commands (via CLI)

### Stopping the Container

1. Get the PID of a running container via `docker ps`
2. Run `docker stop <PID_OF_THE_RUNNING_CONTAINER>`

### Update to Latest Image

**Please note**: Containers running outdated images may experience errors.

1. Check for the latest version number at [Dockerhub](https://hub.docker.com/repository/docker/uptimecom/uptime-private-location/tags?page=1&ordering=last_updated)
2. Login via `docker login`
3. Run `docker pull uptimecom/uptime-private-location:latest`


## Troubleshooting

### Viewing Startup Logs

You can view the logs of the container's startup sequence to help diagnose errors.

1. Get the PID of a running container via `docker ps`
2. Run `docker logs -f <PID_OF_THE_RUNNING_CONTAINER>`

### Accesing Application Logs

You can view the application logs inside the container.

1. Get the PID of a running container via `docker ps`
2. sudo docker exec -it "container-id" /bin/bash
3. Logs are located at /home/uptime/logs/ example command:
          `tail -f /home/uptime/logs/taskqueue.log`

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


## Running in Docker Compose

It is possible to run the privaye location with Docker Compose. A sample configuration
is provided in `compose-sample.yaml` for your reference.


## Changelog
### 5.3
- Support for RDAP check
- Chome version upgrade to 139

### 5.2
- Support for FTP/S, SFTP checks

### 5.1
- Vault TOTP credentials support
- Chrome version upgrade

### 5.0
- Added support for vault credentials
