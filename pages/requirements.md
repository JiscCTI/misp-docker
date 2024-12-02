<!--
SPDX-FileCopyrightText: 2024 Jisc Services Limited
SPDX-FileContributor: James Ellor

SPDX-License-Identifier: GPL-3.0-only
-->

# System Requirements

A Linux system is essential for this deployment method, we have not attempted to create a Windows version of this project and it is currently not a planned update.

When testing our images, the lowest spec system we tried utilised;

- 2 Cores
- 8GB RAM
- 50GB Storage (Dependant upon ingested feeds and events, the storage space used by MISP may grow significantly, it is advised to provide a generous amount of dedicated storage to the MISP instance)

It may be possible to run a MISP instance on a lower spec, however this is not advisable and has not been tested. As mentioned in the [Introduction](index.md) it is strongly recommended that initial deployments of MISP are deployed in a dev environment and are not used in a production sense straight away, it is also not recommended to convert the dev instance into a production instance without tearing the instance down, applying necessary resources to the system and then bringing a new instance up that can be used in production.

# Build Dependencies

Our images have been built and tested against Docker Engine v27, however they should build on any Linux-based Docker Engine which supports multi-stage images. The built images should run on any Linux-based Docker Engine.

# Runtime Dependencies

The created Docker images contain only the MISP components and depend on several services being present:

- ClamAV TCP Endpoint. Tested against Docker image: `clamav/clamav:1.0_base`. The ClamAV module is used to scan attachments that are imported to MISP, such as malware samples.
- MySQL/MariaDB server (5.7 or 8.0). Tested against Docker image: `mysql/mysql-server:8.0`. This is used for the database storage of the MISP instance.
- Redis server (v6 or v7). Tested against Docker image: `redis:7`. Redis is used for the in-memory caching of the MISP instance.
- An SMTP service. We have tested against Postfix.
