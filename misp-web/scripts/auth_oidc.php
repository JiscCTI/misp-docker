<?php
include '/var/www/MISPData/config/config.php';

$config["Security"]["auth"] = array("OidcAuth.Oidc");
$config["OidcAuth"] = array(
    'provider_url' => getenv('OIDC_PROVIDER'),
    'client_id' => getenv('OIDC_CLIENT_ID'),
    'client_secret' => getenv('OIDC_CLIENT_SECRET'),
    'authentication_method' => getenv('OIDC_AUTH_METHOD'),
    'code_challenge_method' => getenv('OIDC_CODE_CHALLENGE_METHOD'),
    'redirect_uri' => getenv('MISP_URL') . '/users/login',
    'role_mapper' =>
    array(
        getenv('OIDC_ADMIN_ROLE') => 1,
        getenv('OIDC_ORG_ADMIN_ROLE') => 2,
        getenv('OIDC_USER_ROLE') => 3,
        getenv('OIDC_PUBLISHER_ROLE') => 4,
        getenv('OIDC_SYNC_ROLE') => 5,
        getenv('OIDC_API_ROLE') => 'User with API access',
    ),
    'default_org' => getenv('ORG_NAME'),
);
file_put_contents("/var/www/MISPData/config/config.php", "<?php\n\$config = " . var_export($config, true) . ";");

$bootstrap = file_get_contents("/var/www/MISPData/config/bootstrap.php");
if (strpos($bootstrap, "CakePlugin::load('OidcAuth');") === false) {
    $bootstrap = $bootstrap . "\nCakePlugin::load('OidcAuth');";
    file_put_contents("/var/www/MISPData/config/bootstrap.php", $bootstrap);
}
