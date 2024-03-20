#!/bin/bash

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

$CAKE Admin setSetting "MISP.python_bin" "/var/www/MISP/venv/bin/python"
$CAKE Admin setSetting "Session.autoRegenerate" 0
$CAKE Admin setSetting "Session.timeout" 600
$CAKE Admin setSetting "Session.cookieTimeout" 3600
$CAKE Admin setSetting "MISP.tmpdir" "/var/www/MISPData/tmp"
$CAKE Admin setSetting "MISP.manage_workers" false
$CAKE Admin setSetting "Security.enable_svg_logos" true
# Enable GnuPG
$CAKE Admin setSetting "GnuPG.homedir" "/var/www/MISPGnuPG"
$CAKE Admin setSetting "GnuPG.obscure_subject" true
$CAKE Admin setSetting "GnuPG.onlyencrypted" true
$CAKE Admin setSetting "GnuPG.bodyonlyencrypted" true
$CAKE Admin setSetting "GnuPG.key_fetching_disabled" false
# Enable installer org and tune some configurables
$CAKE Admin setSetting "MISP.host_org_id" 1
$CAKE Admin setSetting "MISP.disablerestalert" true
$CAKE Admin setSetting "MISP.showCorrelationsOnIndex" true
$CAKE Admin setSetting "MISP.default_event_tag_collection" 0
# Provisional Cortex tunes
$CAKE Admin setSetting "Plugin.Cortex_services_enable" false
$CAKE Admin setSetting "Plugin.Cortex_services_url" "http://127.0.0.1"
$CAKE Admin setSetting "Plugin.Cortex_services_port" 9000
$CAKE Admin setSetting "Plugin.Cortex_timeout" 120
$CAKE Admin setSetting "Plugin.Cortex_authkey" false
$CAKE Admin setSetting "Plugin.Cortex_ssl_verify_peer" false
$CAKE Admin setSetting "Plugin.Cortex_ssl_verify_host" false
$CAKE Admin setSetting "Plugin.Cortex_ssl_allow_self_signed" true
# Various plugin sightings settings
$CAKE Admin setSetting "Plugin.Sightings_policy" 0
$CAKE Admin setSetting "Plugin.Sightings_anonymise" false
$CAKE Admin setSetting "Plugin.Sightings_anonymise_as" 1
$CAKE Admin setSetting "Plugin.Sightings_range" 365
$CAKE Admin setSetting "Plugin.Sightings_sighting_db_enable" false
# Set API_Required modules to false
$CAKE Admin setSetting "Plugin.Enrichment_cuckoo_submit_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_vmray_submit_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_circl_passivedns_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_circl_passivessl_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_domaintools_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_eupi_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_farsight_passivedns_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_passivetotal_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_passivetotal_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_virustotal_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_whois_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_shodan_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_geoip_asn_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_geoip_city_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_geoip_country_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_iprep_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_otx_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_vulndb_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_crowdstrike_falcon_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_onyphe_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_xforceexchange_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_vulners_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_macaddress_io_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_intel471_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_backscatter_io_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_hibp_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_greynoise_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_joesandbox_submit_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_virustotal_public_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_apiosintds_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_urlscan_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_securitytrails_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_apivoid_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_assemblyline_submit_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_assemblyline_query_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_ransomcoindb_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_lastline_query_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_sophoslabs_intelix_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_cytomic_orion_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_censys_enrich_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_trustar_enrich_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.Enrichment_recordedfuture_enabled" false 2> /dev/null
$CAKE Admin setSetting "Plugin.ElasticSearch_logging_enable" false 2> /dev/null
$CAKE Admin setSetting "Plugin.S3_enable" false 2> /dev/null
# Plugin CustomAuth tuneable
$CAKE Admin setSetting "Plugin.CustomAuth_disable_logout" false
# RPZ Plugin settings
$CAKE Admin setSetting "Plugin.RPZ_policy" 0
$CAKE Admin setSetting "Plugin.RPZ_walled_garden" "127.0.0.1"
$CAKE Admin setSetting "Plugin.RPZ_serial" "\$date00"
$CAKE Admin setSetting "Plugin.RPZ_refresh" "2h"
$CAKE Admin setSetting "Plugin.RPZ_retry" "30m"
$CAKE Admin setSetting "Plugin.RPZ_expiry" "30d"
$CAKE Admin setSetting "Plugin.RPZ_minimum_ttl" "1h"
$CAKE Admin setSetting "Plugin.RPZ_ttl" "1w"
$CAKE Admin setSetting "Plugin.RPZ_ns" "localhost."
$CAKE Admin setSetting "Plugin.RPZ_ns_alt" false
$CAKE Admin setSetting "Plugin.RPZ_email" "root.localhost"
# Kafka settings
$CAKE Admin setSetting "Plugin.Kafka_enable" false
$CAKE Admin setSetting "Plugin.Kafka_brokers" "kafka:9092"
$CAKE Admin setSetting "Plugin.Kafka_rdkafka_config" "/etc/rdkafka.ini"
$CAKE Admin setSetting "Plugin.Kafka_include_attachments" false
$CAKE Admin setSetting "Plugin.Kafka_event_notifications_enable" false
$CAKE Admin setSetting "Plugin.Kafka_event_notifications_topic" "misp_event"
$CAKE Admin setSetting "Plugin.Kafka_event_publish_notifications_enable" false
$CAKE Admin setSetting "Plugin.Kafka_event_publish_notifications_topic" "misp_event_publish"
$CAKE Admin setSetting "Plugin.Kafka_object_notifications_enable" false
$CAKE Admin setSetting "Plugin.Kafka_object_notifications_topic" "misp_object"
$CAKE Admin setSetting "Plugin.Kafka_object_reference_notifications_enable" false
$CAKE Admin setSetting "Plugin.Kafka_object_reference_notifications_topic" "misp_object_reference"
$CAKE Admin setSetting "Plugin.Kafka_attribute_notifications_enable" false
$CAKE Admin setSetting "Plugin.Kafka_attribute_notifications_topic" "misp_attribute"
$CAKE Admin setSetting "Plugin.Kafka_shadow_attribute_notifications_enable" false
$CAKE Admin setSetting "Plugin.Kafka_shadow_attribute_notifications_topic" "misp_shadow_attribute"
$CAKE Admin setSetting "Plugin.Kafka_tag_notifications_enable" false
$CAKE Admin setSetting "Plugin.Kafka_tag_notifications_topic" "misp_tag"
$CAKE Admin setSetting "Plugin.Kafka_sighting_notifications_enable" false
$CAKE Admin setSetting "Plugin.Kafka_sighting_notifications_topic" "misp_sighting"
$CAKE Admin setSetting "Plugin.Kafka_user_notifications_enable" false
$CAKE Admin setSetting "Plugin.Kafka_user_notifications_topic" "misp_user"
$CAKE Admin setSetting "Plugin.Kafka_organisation_notifications_enable" false
$CAKE Admin setSetting "Plugin.Kafka_organisation_notifications_topic" "misp_organisation"
$CAKE Admin setSetting "Plugin.Kafka_audit_notifications_enable" false
$CAKE Admin setSetting "Plugin.Kafka_audit_notifications_topic" "misp_audit"
# ZeroMQ settings
$CAKE Admin setSetting "Plugin.ZeroMQ_host" "127.0.0.1"
$CAKE Admin setSetting "Plugin.ZeroMQ_port" 50000
$CAKE Admin setSetting "Plugin.ZeroMQ_redis_host" "localhost"
$CAKE Admin setSetting "Plugin.ZeroMQ_redis_port" 6379
$CAKE Admin setSetting "Plugin.ZeroMQ_redis_database" 1
$CAKE Admin setSetting "Plugin.ZeroMQ_redis_namespace" "mispq"
$CAKE Admin setSetting "Plugin.ZeroMQ_event_notifications_enable" false
$CAKE Admin setSetting "Plugin.ZeroMQ_object_notifications_enable" false
$CAKE Admin setSetting "Plugin.ZeroMQ_object_reference_notifications_enable" false
$CAKE Admin setSetting "Plugin.ZeroMQ_attribute_notifications_enable" false
$CAKE Admin setSetting "Plugin.ZeroMQ_sighting_notifications_enable" false
$CAKE Admin setSetting "Plugin.ZeroMQ_user_notifications_enable" false
$CAKE Admin setSetting "Plugin.ZeroMQ_organisation_notifications_enable" false
$CAKE Admin setSetting "Plugin.ZeroMQ_include_attachments" false
$CAKE Admin setSetting "Plugin.ZeroMQ_tag_notifications_enable" false
# Force defaults to make MISP Server Settings less RED
$CAKE Admin setSetting "MISP.language" "eng"
$CAKE Admin setSetting "MISP.proposals_block_attributes" false
# Redis block
$CAKE Admin setSetting "MISP.redis_port" 6379
# Force defaults to make MISP Server Settings less YELLOW
$CAKE Admin setSetting "MISP.ssdeep_correlation_threshold" 40
$CAKE Admin setSetting "MISP.extended_alert_subject" false
$CAKE Admin setSetting "MISP.default_event_threat_level" 4
$CAKE Admin setSetting "MISP.newUserText" "Dear new MISP user,\\n\\nWe would hereby like to welcome you to the \$org MISP community.\\n\\n Use the credentials below to log into MISP at \$misp, where you will be prompted to manually change your password to something of your own choice.\\n\\nUsername: \$username\\nPassword: \$password\\n\\nIf you have any questions, don't hesitate to contact us at: \$contact.\\n\\nBest regards,\\nYour \$org MISP support team"
$CAKE Admin setSetting "MISP.passwordResetText" "Dear MISP user,\\n\\nA password reset has been triggered for your account. Use the below provided temporary password to log into MISP at \$misp, where you will be prompted to manually change your password to something of your own choice.\\n\\nUsername: \$username\\nYour temporary password: \$password\\n\\nIf you have any questions, don't hesitate to contact us at: \$contact.\\n\\nBest regards,\\nYour \$org MISP support team"
$CAKE Admin setSetting "MISP.enableEventBlocklisting" true
$CAKE Admin setSetting "MISP.enableOrgBlocklisting" true
$CAKE Admin setSetting "MISP.log_client_ip" true
$CAKE Admin setSetting "MISP.log_auth" false
$CAKE Admin setSetting "MISP.log_user_ips" true
$CAKE Admin setSetting "MISP.log_user_ips_authkeys" true
$CAKE Admin setSetting "MISP.disableUserSelfManagement" false
$CAKE Admin setSetting "MISP.disable_user_login_change" false
$CAKE Admin setSetting "MISP.disable_user_password_change" false
$CAKE Admin setSetting "MISP.disable_user_add" false
$CAKE Admin setSetting "MISP.block_event_alert" false
$CAKE Admin setSetting "MISP.block_event_alert_tag" "no-alerts=\"true\""
$CAKE Admin setSetting "MISP.block_old_event_alert" false
$CAKE Admin setSetting "MISP.event_alert_republish_ban" false
$CAKE Admin setSetting "MISP.event_alert_republish_ban_threshold" 5
$CAKE Admin setSetting "MISP.event_alert_republish_ban_refresh_on_retry" false
$CAKE Admin setSetting "MISP.incoming_tags_disabled_by_default" false
$CAKE Admin setSetting "MISP.maintenance_message" "Great things are happening! MISP is undergoing maintenance, but will return shortly. You can contact the administration at \$email."
$CAKE Admin setSetting "MISP.attachments_dir" "/var/www/MISPData/attachments"
$CAKE Admin setSetting "MISP.download_attachments_on_load" true
$CAKE Admin setSetting "MISP.event_alert_metadata_only" false
$CAKE Admin setSetting "MISP.title_text" "MISP"
$CAKE Admin setSetting "MISP.terms_download" false
$CAKE Admin setSetting "MISP.showorgalternate" false
$CAKE Admin setSetting "MISP.event_view_filter_fields" "id, uuid, value, comment, type, category, Tag.name"
$CAKE Admin setSetting "MISP.log_new_audit" true
# Force defaults to make MISP Server Settings less GREEN
$CAKE Admin setSetting "debug" 0
$CAKE Admin setSetting "Security.auth_enforced" false
$CAKE Admin setSetting "Security.log_each_individual_auth_fail" false
$CAKE Admin setSetting "Security.rest_client_baseurl" ""
$CAKE Admin setSetting "Security.password_policy_length" 12
$CAKE Admin setSetting "Security.password_policy_complexity" '/^((?=.*\d)|(?=.*\W+))(?![\n])(?=.*[A-Z])(?=.*[a-z]).*$|.{16,}/'
# Appease the security audit, #hardening
$CAKE Admin setSetting "Security.disable_browser_cache" true
$CAKE Admin setSetting "Security.check_sec_fetch_site_header" true
$CAKE Admin setSetting "Security.csp_enforce" true
$CAKE Admin setSetting "Security.advanced_authkeys" true
$CAKE Admin setSetting "Security.do_not_log_authkeys" true
# Appease the security audit, #loggin
$CAKE Admin setSetting "Security.username_in_response_header" true
# Enable Enrichment, set better timeouts
$CAKE Admin setSetting "Plugin.Enrichment_services_enable" true
$CAKE Admin setSetting "Plugin.Enrichment_hover_enable" true
$CAKE Admin setSetting "Plugin.Enrichment_hover_popover_only" false
$CAKE Admin setSetting "Plugin.Enrichment_hover_timeout" 150
$CAKE Admin setSetting "Plugin.Enrichment_timeout" 300
$CAKE Admin setSetting "Plugin.Enrichment_bgpranking_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_countrycode_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_cve_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_cve_advanced_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_cpe_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_dns_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_eql_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_btc_steroids_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_ipasn_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_reversedns_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_yara_syntax_validator_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_yara_query_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_wiki_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_threatminer_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_threatcrowd_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_hashdd_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_rbl_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_sigma_syntax_validator_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_stix2_pattern_syntax_validator_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_sigma_queries_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_dbl_spamhaus_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_btc_scam_check_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_macvendors_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_qrcode_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_ocr_enrich_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_pdf_enrich_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_docx_enrich_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_xlsx_enrich_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_pptx_enrich_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_ods_enrich_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_odt_enrich_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_urlhaus_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_malwarebazaar_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_html_to_markdown_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_socialscan_enabled" true
$CAKE Admin setSetting "Plugin.Enrichment_services_port" 6666
# Enable Import modules, set better timeout
$CAKE Admin setSetting "Plugin.Import_services_enable" true
$CAKE Admin setSetting "Plugin.Import_services_port" 6666
$CAKE Admin setSetting "Plugin.Import_timeout" 300
$CAKE Admin setSetting "Plugin.Import_ocr_enabled" true
$CAKE Admin setSetting "Plugin.Import_mispjson_enabled" true
$CAKE Admin setSetting "Plugin.Import_openiocimport_enabled" true
$CAKE Admin setSetting "Plugin.Import_threatanalyzer_import_enabled" true
$CAKE Admin setSetting "Plugin.Import_csvimport_enabled" true
# Enable Export modules, set better timeout
$CAKE Admin setSetting "Plugin.Export_services_enable" true
$CAKE Admin setSetting "Plugin.Export_services_port" 6666
$CAKE Admin setSetting "Plugin.Export_timeout" 300
$CAKE Admin setSetting "Plugin.Export_pdfexport_enabled" true
$CAKE Admin setSetting "LinOTPAuth.enabled" false
# Enable Action modules
$CAKE Admin setSetting "Plugin.Action_services_enable" true
$CAKE Admin setSetting "Plugin.Action_services_port" 6666
$CAKE Admin setSetting "Plugin.Action_timeout" 300
$CAKE Admin setSetting "Plugin.Action_mattermost_enabled" false
$CAKE Admin setSetting "Plugin.Action_testaction_enabled" false
# Disable publish alerts by default
$CAKE Admin setSetting "MISP.default_publish_alert" false
# Clear placeholder texts
$CAKE Admin setSetting "MISP.welcome_text_top" "" --force
$CAKE Admin setSetting "MISP.welcome_text_bottom" "" --force
$CAKE Admin setSetting "MISP.footermidleft" "" --force
$CAKE Admin setSetting "MISP.footermidright" "" --force
