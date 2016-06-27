# managelinux

!!! This Script is far away from finishing
Help does print wrong usage and some functions will not work or even damage
or delete things on you'r system. !!!


Script should be used for:

Setting up a Server's Software for Web-Based applications:
- php5
- nginx
- mysql (later mariadb)

It will also give the option to setup the following software:
- logrotate (for nginx)

Manage virtual-hosts (with presets) and manage all hosts FTP-accounts from one virtual host.
 - disable will give the option to set mode = issue to disable the site, but show up another site for the domain. (e.x: Someone hasen't payed and the web page should be blocked, but the users informed)
 - add wordpress can setup wordpress fully automatic. It creates the Database in mysql (or later mariadb) and will modify the wp_config.php so that the admin doesn't need to do anything. (Client can do the rest via Web)

Setting up proftpd with an sqlite3 Database.
