<?php
include '/var/www/MISPData/config/config.php';

unset($config["Security"]["auth"]);
unset($config["ApacheShibbAuth"]);

file_put_contents("/var/www/MISPData/config/config.php", "<?php\n\$config = " . var_export($config, true) . ";");

$bootstrap = file_get_contents("/var/www/MISPData/config/bootstrap.php");
if (strpos($bootstrap, "CakePlugin::load('ShibbAuth');") !== false) {
    $bootstrap = str_replace("\nCakePlugin::load('ShibbAuth');\n", "", $bootstrap);
    file_put_contents("/var/www/MISPData/config/bootstrap.php", $bootstrap);
}