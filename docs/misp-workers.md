# MISP Workers

[![MISP release](https://img.shields.io/github/v/release/MISP/MISP?logo=github&label=MISP%20(source))](https://github.com/MISP/MISP)
[![misp-workers](https://img.shields.io/docker/v/jisccti/misp-workers?sort=semver&logo=docker&label=misp-workers)![misp-workers size](https://img.shields.io/docker/image-size/jisccti/misp-workers/latest?label=%20)](https://hub.docker.com/r/jisccti/misp-workers)

MISP's `SimpleBackgroundJobs` workers with Supervisor exposed on port 9001.

The image is only designed to be used with
[jisccti/misp-web](https://hub.docker.com/r/jisccti/misp-web), as it depends on two volumes set up
by that image.

You should provide a `WORKERS_PASSWORD` environment variable, otherwise it will default to `misp`.
The Supervisor password is set to  `WORKERS_PASSWORD` on every container start, meaning it can be
changed simply by updating the value of `WORKERS_PASSWORD` and restarting the container.

**Source:** [JiscCTI/misp-docker](https://github.com/JiscCTI/misp-docker)
