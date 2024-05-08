<!--
SPDX-FileCopyrightText: 2024 Jisc Services Limited
SPDX-FileContributor: Joe Pitt

SPDX-License-Identifier: GPL-3.0-only
-->
<?php

/**
 * SPDX-FileCopyrightText: 2023-2024 Jisc Services Limited
 * SPDX-FileContributor: Joe Pitt
 *
 * SPDX-License-Identifier: GPL-3.0-only
 */
include '/var/www/MISPData/config/config.php';

$config["Security"]["auth"] = array("ShibbAuth.ApacheShibb");
$config["ApacheShibbAuth"] = array(
    'MailTag' => 'mail',
    'OrgTag' => 'org',
    'GroupTag' => 'memberOf',
    'GroupSeparator' => ';',
    'GroupRoleMatching' => array(
        getenv("SHIBB_ADMIN_ROLE") => 1,
        getenv("SHIBB_ORG_ADMIN_ROLE") => 2,
        getenv("SHIBB_USER_ROLE") => 3,
        getenv("SHIBB_PUBLISHER_ROLE") => 4,
        getenv("SHIBB_SYNC_ROLE") => 5,
        getenv("SHIBB_READONLY_ROLE") => 6,
    ),
    'DefaultOrg' => getenv("ORG_NAME"),
);

if (!in_array(getenv("SHIBB_DEFAULT_ROLE"), array("false", "False", "0"))) {
    $config["ApacheShibbAuth"]["DefaultRole"] = getenv("SHIBB_DEFAULT_ROLE");
}
if (in_array(getenv("SHIBB_BLOCK_ROLE_CHANGE"), array("true", "True", "1"))) {
    $config["ApacheShibbAuth"]["BlockRoleModifications"] = true;
} else {
    $config["ApacheShibbAuth"]["BlockRoleModifications"] = false;
}
if (in_array(getenv("SHIBB_BLOCK_ORG_CHANGE"), array("true", "True", "1"))) {
    $config["ApacheShibbAuth"]["BlockOrgModifications"] = true;
} else {
    $config["ApacheShibbAuth"]["BlockOrgModifications"] = false;
}

file_put_contents("/var/www/MISPData/config/config.php", "<?php\n\$config = " . var_export($config, true) . ";");


$bootstrap = file_get_contents("/var/www/MISPData/config/bootstrap.php");
if (strpos($bootstrap, "CakePlugin::load('ShibbAuth');") === false) {
    $bootstrap = $bootstrap . "\nCakePlugin::load('ShibbAuth');\n";
    file_put_contents("/var/www/MISPData/config/bootstrap.php", $bootstrap);
}
