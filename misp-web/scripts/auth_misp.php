<?php
include '/var/www/MISPData/config/config.php';

unset($config["Security"]["auth"]);
unset($config["ApacheShibbAuth"]);
unset($config["OidcAuth"]);
file_put_contents("/var/www/MISPData/config/config.php", "<?php\n\$config = " . var_export($config, true) . ";");

$bootstrap = file_get_contents("/var/www/MISPData/config/bootstrap.php");
$bootstrap_changed = false;
if (strpos($bootstrap, "CakePlugin::load('ShibbAuth');") !== false) {
    $bootstrap = str_replace("\nCakePlugin::load('ShibbAuth');\n", "", $bootstrap);
    $bootstrap_changed = true;
}
if (strpos($bootstrap, "CakePlugin::load('OidcAuth');") !== false) {
    $bootstrap = str_replace("\nCakePlugin::load('OidcAuth');\n", "", $bootstrap);
    $bootstrap_changed = true;
}
if ($bootstrap_changed) {
    file_put_contents("/var/www/MISPData/config/bootstrap.php", $bootstrap);
}