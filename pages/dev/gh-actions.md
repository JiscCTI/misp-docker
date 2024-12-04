<!--
SPDX-FileCopyrightText: 2024 Jisc Services Limited
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->
# GitHub Actions

The project uses GitHub Actions to automate some steps, these are detailed below.

## Development Images

The Development Images (dev-images) workflow runs on request and when a pull request is created or
updated.

Once triggered, this workflow:

* For PRs, add a comment that images will be built.
* Configure the environment.
* Build the containers
* Attempt to spin up a new instance of MISP.
* If the new instance starts successfully, push the images to their respective -dev images on
DockerHub.
* For PRs, add a comment that the dev images are available.

## Production Images (production-images)

The Production Images (production-images) workflow runs on request, on pushes to the `main` branch
and on a cron schedule of every six hours at quarter past the hour.

Once triggered, this workflow:

* For cron, check upstream if new images need to be built - stop if not.
* Configure the environment.
* Build the containers
* Attempt to spin up a new instance of MISP.
* If the new instance starts successfully, push the images to their respective images on DockerHub.

## Update DockerHub (update-dockerhub)

The Update DockerHub (update-dockerhub) workflow runs on request and on pushes to the `main` branch.

It updates each image's DockerHub page using the markdown files in `/docs/`.

## Update GitHub Pages (github-pages)

The Update GitHub Pages (github-pages) workflow runs on request and on pushes to the `main` branch.

It updates this site based on `mkdocs.yml` and the pages in `/pages/`.
