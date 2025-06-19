<!--
SPDX-FileCopyrightText: 2024-2025 Jisc Services Limited
SPDX-FileContributor: James Ellor
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->

# System Requirements

A Linux system is essential for this deployment method, we have not attempted to create a Windows
version of this project and it is currently not a planned update (though the project should
theoretically work using Docker Desktop running in Windows Subsystem for Linux (WLS) mode).

## Hardware Requirements

Due to the nature of MISP, it is difficult to give definitive numbers for what hardware to use.
Resource requirements will depend on the number of feeds coming in, the number of servers being
synchronised with and the number of security tools integrated into MISP.

As a starting point, we would suggest:

* 4 vCPUs
* 8GB RAM
* 100GB Storage

When testing our images, the lowest spec system able to run the project had:

- 2 vCPUs
- 8GB RAM
- 50GB Storage

We are aware of instances of MISP running with at least:

* 8 vCPUs
* 64GB RAM
* 150GB Storage

It may be possible to run a MISP instance on a lower spec, however this is not advisable and has not
been tested. As mentioned in the [Introduction](index.md) it is strongly recommended that initial
deployments of MISP are deployed in a dev environment and are not used in a production sense
straight away, it is also not recommended to convert the dev instance into a production instance.

## Runtime Dependencies

The created Docker images contain only the MISP components and depend on several services being present:

- ClamAV TCP Endpoint. Tested against Docker image: `clamav/clamav:1.0_base`. The ClamAV module is
    used to scan attachments that are imported to MISP, such as malware samples.
- MySQL/MariaDB server (5.7 or 8.0). Tested against Docker image: `mysql/mysql-server:8.0`. This is
    used for the database storage of the MISP instance.
- Redis server (6, 7 or 8). Tested against Docker image: `redis:8`. Redis is used for the in-memory
    caching of the MISP instance.
    - Redis over TLS is supported.
    - Redis over Mutual TLS (mTLS) is **NOT** supported.
- An SMTP service. We have tested against Postfix.
    - Only **authenticated** mail relays are supported.
