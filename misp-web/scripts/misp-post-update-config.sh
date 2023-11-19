#!/bin/bash

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

$CAKE Admin setSetting "Plugin.Enrichment_clamav_enabled" true
$CAKE Admin setSetting "MISP.attachment_scan_module" "clamav"
$CAKE Admin setSetting "MISP.correlation_engine" "Default"
$CAKE Admin setSetting "MISP.log_auth" true
$CAKE Admin setSetting "MISP.log_new_audit_compress" true
$CAKE Admin setSetting "MISP.log_skip_access_logs_in_application_logs" true
$CAKE Admin setSetting "MISP.self_update" false
$CAKE Admin setSetting "MISP.store_api_access_time" true
$CAKE Admin setSetting "MISP.thumbnail_in_redis" true
$CAKE Admin setSetting "MISP.unpublishedprivate" false
$CAKE Admin setSetting "Security.otp_required" true
