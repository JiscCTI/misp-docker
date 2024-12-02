<!--
SPDX-FileCopyrightText: 2024 Jisc Services Limited
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->

# Deploying MISP in Public Cloud Environments

The images are designed to be cloud-friendly and supporting services such as the MySQL database are
interchangeable with cloud managed services.

Exact services to use will depend on the cloud provider selected and local design principles.

In Amazon Web Services (AWS), MISP can be deployed using these services:

* Certificate Manager for TLS certificate management,
* Elastic Load Balancer to front the `misp-web` containers,
* WAF (Web Application Firewall) to protect the application,
* Aurora MySQL Relational Database Service for the backend database,
* ElastiCache Redis for in-memory caching,
* Elastic File System for persistent file storage,
* Simple Email Service for sending emails,
* Fargate Elastic Container Service for running the containers, and
* CloudWatch for monitoring the deployment.
