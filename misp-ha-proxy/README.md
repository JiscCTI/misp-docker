<!--
SPDX-FileCopyrightText: 2023 Jisc Services Limited
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->
# MISP HAProxy Demo Image

Simple HAProxy load balancer for running the High Availability demo.

## Building

Built on demand by Docker Compose.

## Volumes

### `/tls`

Requires one file `haproxy.pem`, if the file is missing or invalid the container will enter a restart loop.

`haproxy.pem` must include (in order):

1. The certificate,
2. The unencrypted private key,
3. full chain to the root CA, and
4. (Optional, but recommended) The content of https://ssl-config.mozilla.org/ffdhe2048.txt.
