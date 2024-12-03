<!--
SPDX-FileCopyrightText: 2024 Jisc Services Limited
SPDX-FileContributor: Clive Bream
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->

# Forwarding Logs to Splunk

The [misp-splunk-forwarder](https://hub.docker.com/r/jisccti/misp-splunk-forwarder) component
monitors the apache and MISP logs and forwards them to your Splunk instance, enabling you to index
and consolidate that information using Splunk.

**NOTE:** By default, following the below steps, TLS verification is disabled as Splunk defaults to
a self-signed certificate. In production environments, the Splunk HEC listener should be configured
to use a trusted certificate, then `splunk-insecureskipverify` in Configure Docker Logging should be
set to `"false"` and `SPLUNK_HEC_VERIFY` in `.env` should be set to `true`.

## Configure Docker Logging

Configure Docker to forward logs to the HTTP Event Collector, by either:

- Configuring the Docker Engine's default log profile in `/etc/docker/daemon.json`, or
- Configuring logging for each service in `docker-compose.yml`.

### Docker Engine Default

Add the following into /etc/docker/daemon.json.

```json
{
    "log-driver": "splunk",
    "log-opts": {
        "splunk-token": "00000000-1111-2222-3333-444444444444",
        "splunk-url": "https://splunk.example.com:8088",
        "splunk-insecureskipverify": "true",
        "splunk-sourcetype": "_json",
        "splunk-index": "default",
        "tag": "image={{.ImageName}} containerId={{.ID}}",
        "labels": "org.opencontainers.image.title,org.opencontainers.image.version",
        "env": "FQDN,HTTPS_PORT"
    }
}
```

Restart the Docker Engine with `systemctl restart docker`.

### Per Service Configuration

for each service in `docker-compose.yml` add these lines:

```yaml
    logging:
      driver: splunk
      options:
        splunk-token: 00000000-1111-2222-3333-444444444444
        splunk-url: https://splunk.example.com:8088
        splunk-insecureskipverify: true
        splunk-sourcetype: _json
        splunk-index: default
        tag: image={{.ImageName}} containerId={{.ID}}
        labels: org.opencontainers.image.title,org.opencontainers.image.version
        env: FQDN,HTTPS_PORT
```

## Configure Environment Variables

Add the required environment variables to your `.env` file. It is strongly recommended you override
all of these settings.

| Option Name | Description | Default Value |
|-------------|-------------|---------------|
| SPLUNK_HEC_KEY | The HTTP Event Collector key to use. | `00000000-1111-2222-3333-444444444444` |
| SPLUNK_HEC_URI | The HTTP Event Collector URI to use. | `https://splunk.example.com:8088` |
| SPLUNK_HEC_VERIFY | Case-sensitive `true` or `false` for whether the HTTPS certificate should be verified for the HTTP Event Collector. | `false` |
| SPLUNK_INDEX | The index logs should be written to. | `default` |
| SPLUNK_PASSWORD | A password to use when creating the admin account on the Splunk Universal Forwarder. | `ChangeMeChangeMeChangeMe` |

## Add Splunk Forwarder 

At the bottom of `docker-compose.yml`, add:

```yaml
  splunk-forwarder:
    depends_on:
      web:
        condition: service_healthy
    environment:
      - FQDN=${FQDN:-misp.local}
      - HTTPS_PORT=${HTTPS_PORT:-443}
      - SPLUNK_HEC_KEY=${SPLUNK_HEC_KEY:-00000000-1111-2222-3333-444444444444}
      - SPLUNK_HEC_URI=${SPLUNK_HEC_URI:-https://splunk.example.com:8088}
      - SPLUNK_HEC_VERIFY=${SPLUNK_HEC_VERIFY:-false}
      - SPLUNK_INDEX=${SPLUNK_INDEX:-default}
      - SPLUNK_PASSWORD=${SPLUNK_PASSWORD:-ChangeMeChangeMeChangeMe}
      - SPLUNK_START_ARGS=--accept-license
    hostname: misp_splunk
    image: jisccti/misp-splunk-forwarder:latest
    restart: unless-stopped
    volumes:
      # Map base image's volumes
      - ./persistent/${COMPOSE_PROJECT_NAME}/splunk/etc/:/opt/splunkforwarder/etc/
      - ./persistent/${COMPOSE_PROJECT_NAME}/splunk/var/:/opt/splunkforwarder/var/
      # Mount MISP-specific volume
      - ./persistent/${COMPOSE_PROJECT_NAME}/data/:/opt/misp_docker/:ro
```

## Start Splunk Forwarder

Once the above steps are complete you can start MISP as normal. If MISP is already running, this
command should add the Splunk Forwarder without impacting the already running containers.

```sh
docker compose up -d
```
