#!/bin/bash

# SPDX-FileCopyrightText: 2023 Jisc Services Limited
# SPDX-FileContributor: Joe Pitt
#
# SPDX-License-Identifier: GPL-3.0-only

$CAKE Admin setSetting "Plugin.Enrichment_clamav_enabled" true
$CAKE Admin setSetting "MISP.attachment_scan_module" "clamav"
$CAKE Admin setSetting "MISP.correlation_engine" "Default"
$CAKE Admin setSetting "MISP.log_new_audit_compress" true
$CAKE Admin setSetting "Security.otp_required" true
$CAKE Admin setSetting "MISP.self_update" false

# Workaround diagnostics page issue introduced in v2.4.175 (https://github.com/MISP/MISP/pull/9230)
$CAKE Admin setSetting "MISP.online_version_check" false
