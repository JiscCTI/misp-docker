# Shibboleth 2 Service Provider for MISP

A shibboleth Service Provider module for
[jisccti/misp-web](https://hub.docker.com/r/jisccti/misp-web).

## 1 - Environment Variables

To use Shibboleth for authentication you need to add some some environment variables to your `.env`
file. You only need to add those that you will change from their default value. The items in
**bold** are highly recommended.

| Option Name | Description | Default Value |
| ----------- | ----------- | ------------- |
| **AUTH_METHOD** | The authentication engine to use, must be changed to `shibb`. | `misp` |
| SHIBB_ADMIN_ROLE | The shibboleth group / role to be granted the MISP admin role. | `misp-admin-access` |
| SHIBB_BLOCK_ORG_CHANGE | If shibboleth should be prevented from changing a user's organisation. | `false` |
| SHIBB_BLOCK_ROLE_CHANGE | If shibboleth should be prevented from changing a user's role. | `false` |
| SHIBB_DEFAULT_ROLE | The default role to assign to users who are not given one by shibboleth. `false` = no role. | `false` |
| SHIBB_EMAIL_FORMAT | The Name Format of the attribute containing a user's email address. | `urn:oasis:names:tc:SAML:2.0:attrname-format:uri` |
| SHIBB_EMAIL_NAME | The Name (not Friendly Name) of the attribute containing a user's email address. | `urn:oid:0.9.2342.19200300.100.1.3` |
| SHIBB_GROUP_FORMAT | The Name Format of the attribute containing a user's groups / roles. | `urn:oasis:names:tc:SAML:2.0:attrname-format:uri` |
| SHIBB_GROUP_NAME | The Name (not Friendly Name) of the attribute containing a user's groups / roles. | `urn:oid:1.3.6.1.4.1.5923.1.5.1.1` |
| SHIBB_HOSTNAME | The hostname of the Shibboleth service container. | `misp_shibb` |
| **SHIBB_IDP_ENTITY_ID** | The entity ID of the shibboleth identity provider. | `https://idp.example.org/idp/shibboleth` |
| **SHIBB_IDP_METADATA_URL** | The URL of the shibboleth identity provider's metadata file. `false` = use `./persistent/${COMPOSE_PROJECT_NAME}/shibb/etc/idp-metadata.xml` | `false` |
| SHIBB_ORG_ADMIN_ROLE | The shibboleth group / role to be granted the MISP org admin role. | `misp-org-admin-access` |
| SHIBB_ORG_FORMAT | The Name Format of the attribute containing a user's organisation. | `urn:oasis:names:tc:SAML:2.0:attrname-format:uri` |
| SHIBB_ORG_NAME | The Name (not Friendly Name) of the attribute containing a user's organisation. | `urn:oid:1.3.6.1.4.1.25178.1.2.9` |
| SHIBB_PUBLISHER_ROLE | The shibboleth group / role to be granted the MISP publisher role. | `misp-publisher-access` |
| SHIBB_SP_ENCRYPT_REQUESTS | If the MISP Service Provider should encrypt the shibboleth requests. | `true` |
| SHIBB_SP_ENTITY_ID | The entity ID of MISP's Service Provider. `default` = `https://{FQDN}[]:{HTTPS_PORT}]/shibboleth`. | `default` |
| SHIBB_SP_SHARE_KEY | If the MISP Service Provider should use the same key for signing and encryption (`true`) or generate separate keys (`false`). | `true` |
| SHIBB_SP_SIGN_REQUESTS | If the MISP Service Provider should sign the shibboleth requests. | `true` |
| SHIBB_SYNC_ROLE | The shibboleth group / role to be granted the MISP sync user role. | `misp-sync-access` |
| SHIBB_USER_ROLE | The shibboleth group / role to be granted the MISP user role. | `misp-access` |

## 2 - Docker Compose

To use shibboleth, you need to use [docker-compose-shibb.yml](../docker-compose-shibb.yml) as your
`docker-compose.yml` file.

## 3 - Identity Provider (IdP) Metadata

IdP metadata can either be provided by setting a `SHIBB_IDP_METADATA_URL` in `.env`, or by saving
the IdP's metadata file to `./persistent/${COMPOSE_PROJECT_NAME}/shibb/etc/idp-metadata.xml`
(Where `${COMPOSE_PROJECT_NAME}` defaults to `misp`).

If `SHIBB_IDP_METADATA_URL` is set then during startup the URL will be fetched replacing
`./persistent/${COMPOSE_PROJECT_NAME}/shibb/etc/idp-metadata.xml` - ensure `SHIBB_IDP_METADATA_URL`
is not set in `.env` or is explicitly set to `false` to prevent this. If the URL is invalid, the
container will not start.

## 4 - Service Provider (SP) Metadata

To generate the Service Provider metadata, start MISP as normal using `docker compose up -d`.

Once the `shibb` service has finished starting,
`./persistent/${COMPOSE_PROJECT_NAME}/shibb/etc/misp-metadata.xml` will have been created / updated
and can be imported into the Identity Provider manually.

## 5 - Accessing MISP

Once MISP has been enrolled into the Identify Provider, access `https://{FQDN}:{HTTPS_PORT}` and you
will be redirected to authenticate against the Identity Provider before being redirected back to
MISP.
