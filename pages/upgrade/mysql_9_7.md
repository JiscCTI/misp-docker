<!--
SPDX-FileCopyrightText: 2026 Jisc Services Limited
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->
# MySQL 9.7 Upgrade Procedure

MySQL 8.0 has reached End of Life. Therefore, MISP instances deployed using the Jisc CTI images
before June 2026 need their database engine upgrading to MySQL 9.7, which will be supported by
Oracle until April 2034.

The steps in this procedure **must be followed in order** to avoid irrecoverable loss of access to
the database.

To check which database engine your environment is running:

1. Move to the MISP directory using: `cd /opt/misp`
2. List the images in use using: `grep image docker-compose.yml`
    1. if `image: mysql:9.7` is listed - no action is required.
    2. If `image: mysql/mysql-server:8.0` is listed, follow this procedure to upgrade.

## Initial State

If this procedure applies to you, the `db` service in your `docker-compose.yml` file will look like
this:

```yaml title="docker-compose.yml" hl_lines="2 11"
  db:
    command: [mysqld, --default-authentication-plugin=mysql_native_password, --character-set-server=utf8mb4, --collation-server=utf8mb4_unicode_ci, --innodb_monitor_enable=all]
    environment:
      - FQDN=${FQDN:-misp.local}
      - HTTPS_PORT=${HTTPS_PORT:-443}
      - MYSQL_DATABASE=${MYSQL_DBNAME:-misp}
      - MYSQL_USER=${MYSQL_USERNAME:-misp}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD:-misp}
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-misp}
    hostname: ${MYSQL_HOSTNAME:-misp_db}
    image: mysql/mysql-server:8.0
    restart: unless-stopped
    volumes:
      - ./persistent/${COMPOSE_PROJECT_NAME}/db:/var/lib/mysql
```

## Stop MISP

To ensure data consistency it is essential MISP remains shut down throughout the procedure.

Stop MISP using: `docker compose down`

## Back Up

Ensure you take a full [Backup](../management/backups.md) of your instance before following this
procedure.

The database will be irreversibly re-encoded, meaning you will not be able to swap the image back to
MySQL 8.0 if issues arise as it will not be able to read the data files.

## Migrate Password Encoding

Native authentication is not supported by MySQL 9.7. Therefore, you must re-encode the `root` and
`misp` account passwords into a supported format (`caching_sha2_password`) before proceeding.

1. Start only the database service using: `docker compose up -d db`
2. Open an interactive shell inside the container using: `docker compose exec -it db bash`
4. Load the `root` password into the `MYSQL_PWD` variable using:
  `export MYSQL_PWD=$MYSQL_ROOT_PASSWORD`
5. Re-encode the `root` account password using: 
  `echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$MYSQL_ROOT_PASSWORD';" | mysql`
6. Re-encode the `misp` account password using:
  `echo "ALTER USER 'misp'@'%' IDENTIFIED WITH caching_sha2_password BY '$MYSQL_PASSWORD';" | mysql`
7. Exit the shell using: `exit`
8. Stop the database container using: `docker compose down`

## Upgrade Database Files from 8.0 to 8.4

It is not possible to upgrade straight from 8.0 to 9.7, an intermediate step to 8.4 is required
first.

1. Edit the `command` and `image` options and add the `healthcheck` option to the `db` service in
  your `docker-compose.yml` file as below:

```yaml title="docker-compose.yml" hl_lines="2 10 11 13"
  db:
    command: [mysqld, --character-set-server=utf8mb4, --collation-server=utf8mb4_unicode_ci, --innodb_monitor_enable=all]
    environment:
      - FQDN=${FQDN:-misp.local}
      - HTTPS_PORT=${HTTPS_PORT:-443}
      - MYSQL_DATABASE=${MYSQL_DBNAME:-misp}
      - MYSQL_USER=${MYSQL_USERNAME:-misp}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD:-misp}
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-misp}
    healthcheck:
      test: ["CMD", "mysqladmin" ,"ping", "-h", "localhost"]
    hostname: ${MYSQL_HOSTNAME:-misp_db}
    image: mysql:8.4
    restart: unless-stopped
    volumes:
      - ./persistent/${COMPOSE_PROJECT_NAME}/db:/var/lib/mysql
```

2. Start the database server and monitor the startup using: `docker compose up db`
3. Wait for `ready for connections. Version: '8.4.9' ...` to be logged
4. Shutdown the database container by pressing <kbd>CTRL</kbd>+<kbd>C</kbd>

## Upgrade Database Files from 8.4 to 9.7

Now the database files are in 8.4 format, they can be upgraded to 9.7 format.

1. Update the `image` option of the `db` service in your `docker-compose.yml` file as below:

```yaml title="docker-compose.yml" hl_lines="13"
  db:
    command: [mysqld, --character-set-server=utf8mb4, --collation-server=utf8mb4_unicode_ci, --innodb_monitor_enable=all]
    environment:
      - FQDN=${FQDN:-misp.local}
      - HTTPS_PORT=${HTTPS_PORT:-443}
      - MYSQL_DATABASE=${MYSQL_DBNAME:-misp}
      - MYSQL_USER=${MYSQL_USERNAME:-misp}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD:-misp}
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-misp}
    healthcheck:
      test: ["CMD", "mysqladmin" ,"ping", "-h", "localhost"]
    hostname: ${MYSQL_HOSTNAME:-misp_db}
    image: mysql:9.7
    restart: unless-stopped
    volumes:
      - ./persistent/${COMPOSE_PROJECT_NAME}/db:/var/lib/mysql
```

2. Start the database server and monitor the startup using: `docker compose up db`
3. Wait for `ready for connections. Version: '9.7.0' ...` to be logged
4. Shutdown the database container by pressing <kbd>CTRL</kbd>+<kbd>C</kbd>

## Update Connection Encoding

Finally, the encoding used for MySQL connections by MISP needs to be changed in MISP's database
configuration file.

1. Open `persistent/misp/data/config/database.php` for editing
2. Replace the line `'encoding' => 'utf8'` with
  `'encoding' => 'utf8mb4 COLLATE utf8mb4_unicode_ci'`
3. Save and exit the file

## Start MISP

The database migration is now complete. MISP can now be safely started.

1. Start MISP using: `docker compose up -d`
2. Monitor the web containers startup to ensure no errors occur using: `docker compose logs -f web`
