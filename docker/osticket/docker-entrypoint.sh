#!/bin/bash
set -e

OST_CONFIG="/var/www/html/include/ost-config.php"
OST_SAMPLE="/var/www/html/include/ost-sampleconfig.php"

echo "Starting osTicket container..."

# Recreate configuration from the original template
cp "$OST_SAMPLE" "$OST_CONFIG"

# Validate required environment variables
required_vars=(
    DB_HOST
    DB_NAME
    DB_USER
    DB_PASSWORD
    SECRET_SALT
    TABLE_PREFIX
    ADMIN_EMAIL
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "ERROR: Environment variable $var is not defined"
        exit 1
    fi
done

# Replace osTicket template placeholders safely
php <<'PHP'
<?php

$file = '/var/www/html/include/ost-config.php';

$content = file_get_contents($file);
$content = str_replace(
    "define('OSTINSTALLED',FALSE);",
    "define('OSTINSTALLED',TRUE);",
    $content
);

if ($content === false) {
    fwrite(STDERR, "ERROR: Unable to read ost-config.php\n");
    exit(1);
}

$values = [
    '%CONFIG-SIRI'   => getenv('SECRET_SALT'),
    '%CONFIG-DBHOST' => getenv('DB_HOST'),
    '%CONFIG-DBNAME' => getenv('DB_NAME'),
    '%CONFIG-DBUSER' => getenv('DB_USER'),
    '%CONFIG-DBPASS' => getenv('DB_PASSWORD'),
    '%CONFIG-PREFIX' => getenv('TABLE_PREFIX'),
    '%ADMIN-EMAIL' => getenv('ADMIN_EMAIL'),
];

foreach ($values as $placeholder => $value) {

    if ($value === false || $value === '') {
        fwrite(STDERR, "ERROR: Missing value for {$placeholder}\n");
        exit(1);
    }

    /*
     * The values live inside single-quoted PHP strings
     * in ost-config.php, therefore escape \ and '.
     */
    $value = str_replace(
        ['\\', "'"],
        ['\\\\', "\\'"],
        $value
    );

    $content = str_replace(
        $placeholder,
        $value,
        $content
    );
}

if (strpos($content, '%CONFIG-') !== false) {
    fwrite(STDERR, "ERROR: Configuration contains unresolved placeholders\n");

    preg_match_all('/%CONFIG-[A-Z]+/', $content, $matches);

    foreach (array_unique($matches[0]) as $placeholder) {
        fwrite(STDERR, "UNRESOLVED: {$placeholder}\n");
    }

    exit(1);
}

if (file_put_contents($file, $content) === false) {
    fwrite(STDERR, "ERROR: Unable to write ost-config.php\n");
    exit(1);
}

echo "osTicket configuration generated successfully\n";
PHP

# Secure configuration file
chown www-data:www-data "$OST_CONFIG"
chmod 0644 "$OST_CONFIG"

echo "osTicket configuration ready."

exec apache2-foreground