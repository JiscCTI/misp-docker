# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

FROM python:3.10-slim-bullseye AS build
ARG MISP_VERSION=0.0.0 DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical

# Install build dependencies
RUN mkdir -p /usr/local/src/misp_modules /misp_modules &&\
    apt-get update &&\
    apt-get install -y g++ git libpq5 libjpeg-dev tesseract-ocr libpoppler-cpp-dev imagemagick libopencv-dev\
    zbar-tools libzbar0 libzbar-dev libfuzzy-dev

# Install MISP Modules
RUN git clone --branch ${MISP_VERSION} --single-branch https://github.com/MISP/misp-modules.git\
    /usr/local/src/misp_modules
WORKDIR /usr/local/src/misp_modules
RUN python3 -m venv /misp_modules &&\
    /misp_modules/bin/pip3 install --upgrade pip setuptools --no-cache-dir &&\
    /misp_modules/bin/pip3 install greynoise pyeti redis --no-cache-dir &&\
    /misp_modules/bin/pip3 install git+https://github.com/abenassi/Google-Search-API --no-cache-dir &&\
    /misp_modules/bin/pip3 install -I -r REQUIREMENTS --no-cache-dir &&\
    /misp_modules/bin/pip3 install . --no-cache-dir

FROM python:3.10-slim-bullseye AS final
ARG MISP_VERSION=0.0.0 DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical
LABEL org.opencontainers.image.title="misp-modules" org.opencontainers.image.version=${MISP_VERSION}\
    org.opencontainers.image.ref.name="misp-modules"\
    org.opencontainers.image.description="Modules for expansion services, import and export in MISP."\
    org.opencontainers.image.authors="Jisc <CTI.Analysts@jisc.ac.uk"\
    org.opencontainers.image.base.name="hub.docker.com/_/python:3.10-slim-bullseye"
EXPOSE 6666

RUN apt-get update &&\
    apt-get install -y curl libgl1 libglib2.0-0 libpoppler-cpp0v5 libzbar0 &&\
    rm -rf /var/lib/apt/lists/* &&\
    python3 -m pip install --upgrade pip setuptools --no-cache-dir

COPY --from=build /misp_modules/ /misp_modules/
WORKDIR /misp_modules/bin/
ENTRYPOINT ./misp-modules -l 0.0.0.0
HEALTHCHECK --start-period=30s --timeout=3s CMD curl -fk http://127.0.0.1:6666/modules || exit 1
USER nobody
