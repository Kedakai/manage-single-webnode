<?php
     define('DB_NAME', 'MYSQLDATABASENAME');
     define('DB_USER', 'MYSQLUSER');
     define('DB_PASSWORD', 'MYSQLPASSWORD');
     define('DB_HOST', 'localhost');
     define('DB_CHARSET', 'utf8');
     define('DB_COLLATE', '');
     define('FS_METHOD', 'direct');
     define('WP_CACHE', TRUE);
     define('AUTH_KEY',         'RANDOMKEY1');
     define('SECURE_AUTH_KEY',  'RANDOMKEY2');
     define('LOGGED_IN_KEY',    'RANDOMKEY3');
     define('NONCE_KEY',        'RANDOMKEY4');
     define('AUTH_SALT',        'RANDOMKEY5');
     define('SECURE_AUTH_SALT', 'RANDOMKEY6');
     define('LOGGED_IN_SALT',   'RANDOMKEY7');
     define('NONCE_SALT',       'RANDOMKEY8'); 
     $table_prefix  = 'wp_TABLEPREFIX';
     define('WP_DEBUG', false);
     if ( !defined('ABSPATH') )
             define('ABSPATH', dirname(__FILE__) . '/');
     require_once(ABSPATH . 'wp-settings.php');
