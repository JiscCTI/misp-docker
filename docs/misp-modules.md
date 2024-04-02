# MISP Modules

[![MISP-Modules release](https://img.shields.io/github/v/tag/MISP/misp-modules?logo=github&label=MISP-Modules%20(source))](https://github.com/MISP/misp-modules)
[![misp-modules](https://img.shields.io/docker/v/jisccti/misp-modules?sort=semver&logo=docker&label=misp-modules)![misp-modules size](https://img.shields.io/docker/image-size/jisccti/misp-modules/latest?label=%20)](https://hub.docker.com/r/jisccti/misp-modules)

Python 3.10 running MISP's modules server, exposed on port 6666.

The image is designed to be used with [jisccti/misp-web](https://hub.docker.com/r/jisccti/misp-web),
but should work with any MISP instance.

To configure a MISP instance to use a container running this image you'll need to set
`Plugin.Enrichment_services_url` `Plugin.Import_services_url` `Plugin.Export_services_url` and
`Plugin.Action_services_url` to `http://{MODULES_HOSTNAME}` where `{MODULES_HOSTNAME}` is the IP or
DNS name of your docker host.

if you are exposing the container on a port other than `6666`, you'll also need to set
`Plugin.Enrichment_services_port`, `Plugin.Import_services_port`, `Plugin.Export_services_port`, and
`Plugin.Action_services_port` to the exposed port.

**Source:** [JiscCTI/misp-docker](https://github.com/JiscCTI/misp-docker)
