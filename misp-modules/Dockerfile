# SPDX-FileCopyrightText: 2023-2024 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

FROM python:3.12-slim-bullseye AS build
ARG MISP_VERSION=0.0.0 DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical
RUN apt-get update -yq &&\
    apt-get install -yq g++ git libpoppler-cpp-dev &&\
    python3 -m venv /misp_modules &&\
    . /misp_modules/bin/activate &&\
    python3 -m pip install --upgrade  --no-cache-dir --quiet \
        misp-modules==${MISP_VERSION}\
        ODTReader\
        pip\
        setuptools\
        trustar\
        git+https://github.com/abenassi/Google-Search-API\
        git+https://github.com/onyphe/pyonyphe\
        git+https://github.com/sebdraven/pydnstrails.git &&\
    sed -i "s|print \"Could not find 'content.xml': {}\".format(str(e))|print(\"Could not find 'content.xml': {}\".format(str(e)))|" /misp_modules/lib/python3.12/site-packages/ODTReader/odtreader.py &&\
    sed -i "s|print output|print(output)|" /misp_modules/lib/python3.12/site-packages/ODTReader/odtreader.py

FROM python:3.12-slim-bullseye AS final
ARG MISP_VERSION=0.0.0 DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical REDIS_BACKEND=misp_redis REDIS_DATABASE=1
LABEL org.opencontainers.image.title="misp-modules" org.opencontainers.image.version=${MISP_VERSION}\
    org.opencontainers.image.ref.name="misp-modules"\
    org.opencontainers.image.description="Modules for expansion services, import and export in MISP."\
    org.opencontainers.image.authors="Jisc <CTI.Analysts@jisc.ac.uk"\
    org.opencontainers.image.base.name="hub.docker.com/_/python:3.12-slim-bullseye"
EXPOSE 6666

RUN apt-get update &&\
    apt-get install -y curl libglib2.0-0 libpoppler-cpp0v5 libzbar0 libgl1 &&\
    rm -rf /var/lib/apt/lists/* &&\
    python3 -m pip install --upgrade pip setuptools --no-cache-dir

COPY --from=build /misp_modules/ /misp_modules/
WORKDIR /misp_modules/bin/
ENTRYPOINT ["./misp-modules", "-l", "0.0.0.0"]
HEALTHCHECK --start-period=30s --timeout=3s CMD ["sh", "-c", "curl -fk http://127.0.0.1:6666/modules || exit 1"]
USER nobody
