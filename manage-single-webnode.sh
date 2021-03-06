#!/bin/bash

##### UID GID MANAGEMENT FOR NGINX AND PROFTPD (USER: Web1)
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 74
fi

service=$1
asked_if_variables_are_correct=false

#################################################################################
#                                                                               #
#               Here is the config for logging                                  #                                               
#                                                                               #
#################################################################################

logdir="/var/log/manage-single-webnode.log" # Log for this script

#################################################################################
#                                                                               #
#               Here is the config for needed directories                       #                                               
#                                                                               #
#################################################################################

path_to_nginx_conf="/home/etc/nginx/sites/" # path to nginx configuration files
path_to_nginx_work="/home/web/" # Path where all the website data should be put in
configsamples="/home/samples" # directory where configsamples should be put in

#################################################################################
#                                                                               #
#               Here is the config for database                                 #                                               
#                                                                               #
#################################################################################

proftpd_sqlite3_database_lcoation="/var/www/proftpd/proftpddatabase.db" # This is for the FTP Users
mysql_root_pw="OhMyGodThatDatabasePWissoHArd!!" # MYSQL root password for creating databases for example for wordpress

#################################################################################
#                                                                               #
#               Here is the config for premium costumers                        #
#		Does only take effect if premiumenabled=true                    #
#										#
#################################################################################

premiumenabled=false
normal_costumer_speed=3000 # If premiumenabled=false no limit will be set.
premium_costumer_speed=10000  # kbit/s right here
only_premium_ftp_interface=false # Only premium costumers are allowed to use FTP-Manage interface

#################################################################################
#The Premium Feature was disabled in 0.1 because it's useless in this state.    #
#premiumenabled=true                                                            #
#                                                                               #
#                               Version 0.1                                     #
#################################################################################

function setup_script(){
        if [ ! -d $configsamples ] && [ ! -f /usr/local/sbin/manage-single-webnode ]; then
                echo "Script does not seem do be setup or some directories changed. I will start the script setup, is that okay? [yes]"
                read answer
                if [ "$answer" != "yes" ]; then
                        echo "Cannot work with non-setup Script. Aborting any actions."
                        exit 555
                else
                        if [ ! -f "`which git`" ]; then
                                echo "You need git to apply features. Should i install it? [yes]"
                                read $answer
                                if [ "$answer" != "yes" ]; then
                                        echo "Cannot work with non-setup Script. Aborting any actions."
                                        exit 555
                                else
                                        apt-get -qq install git
                                fi
                        fi
			cur_dir=$(pwd)
			useradd --uid 1010 web1 -d /home
                        mkdir -p $configsamples
                        cd $configsamples
                        git clone https://github.com/Kedakai/manage-single-webnode
                        mv manage-single-webnode/configsamples/* .
                        rm -rf manage-single-webnode
			cd $cur_dir
                        cp `pwd`/manage-single-webnode.sh /usr/local/sbin/manage-single-webnode
                        mkdir -p `dirname $logdir`/nginx
			chmod 660 -R `dirname $logdir`
			chown web1:web1 -R `dirname $logdir`
			/bin/bash -c "sleep 5 ; rm manage-single-webnode.sh" &
                fi
        fi
}

function check_quiet_and_verbose_lvl() {
        message="$1"
        mode="$2"
        if [ "$verbose_level" = "0" ] || [ "$verbose_level" = "quiet" ]; then
               :
        elif [ "$mode" = "1" ] && [ "$verbose_level" -me "1" ]; then
                echo "$message"
        elif [ "$mode" = "2" ] && [ "$verbose_level" -me "2" ]; then
                echo "$message"
        elif [ "$mode" = "3" ] && [ "$verbose_level" -me "3" ]; then
                echo "$message"
        fi
}

function print_version() {
        echo "manage-single-webnode v0.2"
}

function get_log_date() {
        date "+[%d/%m/%y   %H:%M:%S]"
}

function print_main_help() {
        echo '%%manage-single-webnode%%

                The following commands are available:

                manage-single-webnode nginx
                manage-single-webnode proftpd
                manage-single-webnode server

                If you want to see help for this command type help after above commands'
}

function print_nginx_help() {
        echo '%%manage-single-webnode nginx%%

                The following Commands are available:

                manage-single-webnode nginx add $DOMAINNAME $IS_WORDPRESS $PREMIUM_COSTUMER $MYSQL_NEEDED
                EXAMPLE: manage-single-webnode nginx add google.de wordpress yes yes
                         manage-single-webnode nginx add google.com other no no
                         
                        !! $MYSQL_NEEDED DOES ONLY TAKES EFFECT WITH $IS_WORDPRESS=yes !!


                manage-single-webnode nginx delete $DOMAINNAME
                EXAMPLE: manage-single-webnode delete google.de

                manage-single-webnode nginx disable $DOMAINNAME
                EXAMPLE: manage-single-webnode disable google.de (all/one)

                manage-single-webnode nginx enable $DOMAINNAME
                EXAMPLE: manage-single-webnode enable google.de (all/one)

		manage-single-webnode nginx block $DOMAINNAME (all/one)
		EXAMPLE: manage-single-webnode block google.de (all/one) <- $3

		manage-single-webnode nginx unblock $DOMAINNAME (all/one)
                EXAMPLE: manage-single-webnode unblock google.de (all/one) <- $3

                If you use all as $3 with enable/disable command, it will disable/enable all domain/subdomains matching the name you entered'
}


function print_proftpd_help() {
        echo '%%manage-single-webnode proftpd%%
                 
                The following Commands are available:

                manage-single-webnode proftpd add $DOMAINNAME $DIRECTORY $USERNAME $PASSWORD
                EXAMPLE: manage-single-webnode proftpd add google.de /var/www/google.de/ftp admin 
		(Note: Without providing a password we generate a safe 24 digit random password)
		EXAMPLE: manage-single-webnode proftpd add google.de /var/www/google.de/ftp admin --i-really-want-to-choose-my-password-by-myself
		(Note: With "--i-really-want-to-choose-my-password-by-myself you are allowed to set the password yourself"

		manage-single-webnode proftpd disable $USERNAME one/all $Domainname
		EXAMPLE: manage-single-webnode proftpd disable admin one ($Domainname is not used)
		EXAMPLE: manage-single-webnode proftpd disable none all google.de
		(Note: If you use "all" username has to be "none" and $Domainame the same you antered when created these accounts)

		manage-single-webnode proftpd enable $USERNAME one/all $Domainname
                EXAMPLE: manage-single-webnode proftpd enable admin one ($Domainname is not used)
                EXAMPLE: manage-single-webnode proftpd enable none all google.de
                (Note: If you use "all" username has to be "none" and $Domainame the same you antered when created these accounts)

		manage-single-webnode proftpd delete $USERNAME one/all $Domainname
                EXAMPLE: manage-single-webnode proftpd delete admin one ($Domainname is not used)
                EXAMPLE: manage-single-webnode proftpd delete none all google.de
                (Note: If you use "all" username has to be "none" and $Domainame the same you antered when created these accounts)'
}

function disable_all_nginx_confs() {
        disable_domainname_nginx_confs=$1
        for files in $(ls $path_to_nginx_conf | grep $disable_domainname_nginx_confs); do
                mv $path_to_nginx_conf$files $path_to_nginx_conf$files.off
        done
}

function enable_all_nginx_confs() {
        enable_domainname_nginx_confs=$1
        for files in $(ls $path_to_nginx_conf | grep $enable_domainname_nginx_confs); do
                enable_domainname_nginx_confs_fin=$(echo $files | sed 's/.off//g')
                mv $path_to_nginx_conf$files $path_to_nginx_conf$enable_domainname_nginx_confs_fin.conf
        done
}

function create_nginx_conf_add() {
        domainname_create_nginx_conf=$1
        is_wordpress_create_nginx_conf=$2
        premium_customer_create_nginx_conf=$3
                if [ "$is_wordpress_create_nginx_conf" != "ftp" ]; then
                        echo ""
                        echo "Is there more then one Domainname should be accepted by nginx? (example: www.lala.moe and lala.moe) if not default domainname will be used."
                        echo 'If this is the case please type in the domainname seperated by whitespace (Example: "lala.moe www.lala.moe")'
                        echo 'ALWAYS PUT MAIN TLD IN FIRST ORDER (google.de www.google.de) or (www.google.de www2.google.de) AND NOT MORE THAT 2 DOMAINNAMES'
                        echo 'FIRST DOMAINNAME WILL BE USED AS WORKING DIR FOR THE WHOLE SKRIPT AND ALL FUNCTIONS'
                        read domainname_create_nginx_conf2

                elif [ "$(echo "$is_wordpress_create_nginx_conf" | tr '.' '\n' |grep "ftp-manage" | wc -l)" != "1" ]; then
                        echo ""
                        echo 'DOMAINNAME NOT VALID. IT HAST TO BE ftp-manage.$COSTUMER'
                        echo 'Please do ONLY use TLD (ex. google.de) in manage-single-webnode proftpd add command! It will be set to ftp-manage.$COSTUMER'
                        exit 5
                fi

                if ( [ "$is_wordpress_create_nginx_conf" = "wordpress" ] && [ "$premium_customer_create_nginx_conf" = "yes" ] ) ; then
                        cp $configsamples/nginx/default_prem.conf /home/etc/nginx/sites/$domainname_create_nginx_conf.conf
                elif ( [ "$is_wordpress_create_nginx_conf" = "wordpress" ] && [ "$premium_customer_create_nginx_conf" = "no" ] ); then
                        cp $configsamples/nginx/default.conf /home/etc/nginx/sites/$domainname_create_nginx_conf.conf
                elif ( [ "$is_wordpress_create_nginx_conf" = "other" ] && [ "$premium_customer_create_nginx_conf" = "yes" ] ); then
                        cp $configsamples/nginx/default.conf /home/etc/nginx/sites/$domainname_create_nginx_conf.conf
                elif ( [ "$is_wordpress_create_nginx_conf" = "other" ] && [ "$premium_customer_create_nginx_conf" = "no" ] ); then
                        cp $configsamples/nginx/default.conf /home/etc/nginx/sites/$domainname_create_nginx_conf.conf
                elif [ "$is_wordpress_create_nginx_conf" = "ftp" ]; then
                        cp $configsamples/nginx/default.conf /home/etc/nginx/sites/$domainname_create_nginx_conf.conf
                fi


                if [ "$domainname_create_nginx_conf2" = "" ]; then
                        sed -i "s:SAMPLEDOMAINNAMES:$domainname_create_nginx_conf:g" /home/etc/nginx/sites/$domainname_create_nginx_conf.conf
                        sed -i "s:SAMPLEDOMAINNAME1.access.log:$domainname_create_nginx_conf.access.log:g" /home/etc/nginx/sites/$domainname_create_nginx_conf.conf
                        sed -i "s:SAMPLEDOMAINNAME1.error.log:$domainname_create_nginx_conf.error.log:g" /home/etc/nginx/sites/$domainname_create_nginx_conf.conf
                        if [ "$is_wordpress_create_nginx_conf" = "ftp" ]; then
                                sed -i "s:SAMPLEDIRECTORY:$path_to_nginx_work$domainname_create_nginx_conf/htdocs/FTP:g" /home/etc/nginx/sites/$domainname_create_nginx_conf.conf
                        fi
                else
                        domainname1_create_nginx_conf=`echo $domainname_create_nginx_conf2 | tr ' ' '\n' | head -1`
                        domainname2_create_nginx_conf=`echo $domainname_create_nginx_conf2 | tr ' ' '\n' | tail -1`
                        sed -i "s:SAMPLEDOMAINNAMES:$domainname_create_nginx_conf2:g" /home/etc/nginx/sites/$domainname_create_nginx_conf.conf
                        sed -i "s:SAMPLEDOMAINNAME1.access.log:$domainname1_create_nginx_conf.access.log:g" /home/etc/nginx/sites/$domainname_create_nginx_conf.conf
                        sed -i "s:SAMPLEDOMAINNAME1.error.log:$domainname1_create_nginx_conf.error.log:g" /home/etc/nginx/sites/$domainname_create_nginx_conf.conf
                        sed -i "s:SAMPLEDIRECTORY:$path_to_nginx_work$domainname_create_nginx_conf/htdocs:g" /home/etc/nginx/sites/$domainname_create_nginx_conf.conf
                fi

                echo "Config created for $domainname_create_nginx_conf"
                echo "`get_log_date` nginx Config created for $domainname_create_nginx_conf" >> $logdir
}

function mysql_create_database() {
        mysqlname=$1
        mysqlpw=$2
        mysqluser=$3
        EXPECTED_ARGS=3
        E_BADARGS=5
        MYSQL=`which mysql`

        Q1="CREATE DATABASE IF NOT EXISTS $mysqlname CHARACTER SET utf8 COLLATE utf8_general_ci;"
        Q2="GRANT ALL ON $mysqlname.* TO '$mysqluser'@'localhost' IDENTIFIED BY '$mysqlpw';"
        Q3="FLUSH PRIVILEGES;"
        SQL="${Q1}${Q2}${Q3}"
        if [ $# -ne $EXPECTED_ARGS ]; then
                echo "Some MYSQL Variables were not valid. ABORTING"
                echo "`get_log_date` CRITICAL: Abort Action /nginx add $mysqlname/ in subfunction /mysql_create_database/ because something with MYSQL Parameters went wrong" >> $logdir
                exit $E_BADARGS
        fi

        $MYSQL -uroot -p$mysql_root_pw -e "$SQL"
}

function delete_database_mysql() {
        mysqlname=$1
        mysqluser=$2
        EXPECTED_ARGS=2
        E_BADARGS=5
        MYSQL=`which mysql`

        Q1="DROP DATABASE $mysqlname;"
        Q2="DROP USER '$mysqluser'@'localhost';"
        SQL="${Q1}${Q2}"
        if [ $# -ne $EXPECTED_ARGS ]; then
                echo "Some MYSQL Variables were not valid. ABORTING"
                echo "`get_log_date` CRITICAL: Abort Action /nginx add $mysqlname/ in subfunction /mysql_create_database/ because something with MYSQL Parameters went wrong" >> $logdir
                exit $E_BADARGS
        fi

        $MYSQL -uroot -p$mysql_root_pw -e "$SQL"
}

function create_wp_config_database_name_pw() {
        mysqlname_edit_wp_conf=$1
        mysqlpw_edit_wp_conf=$2
        mysqluser_edit_wp_conf=$3
        domainname_create_wp_conf=$4
        mysqlname_create_wp_conf=$(echo $domainname_create_wp_conf | tr '.' ' ' | sed 's/ //g' | sed 's/-//g')
        cp $configsamples/wordpress/wp-config-sample.php $path_to_nginx_work$domainname_create_wp_conf/htdocs/wp-config.php
        sed -i "s:MYSQLDATABASENAME:$mysqlname_create_wp_conf:g" $path_to_nginx_work$domainname_create_wp_conf/htdocs/wp-config.php
        sed -i "s:MYSQLPASSWORD:$mysqlpw_edit_wp_conf:g" $path_to_nginx_work$domainname_create_wp_conf/htdocs/wp-config.php
        sed -i "s:MYSQLUSER:$mysqluser_edit_wp_conf:g" $path_to_nginx_work$domainname_create_wp_conf/htdocs/wp-config.php
        key1=`pwgen -s 140 1`
        key2=`pwgen -s 140 1`
        key3=`pwgen -s 140 1`
        key4=`pwgen -s 140 1`
        key5=`pwgen -s 140 1`
        key6=`pwgen -s 140 1`
        key7=`pwgen -s 140 1`
        key8=`pwgen -s 140 1`
        sed -i "s:RANDOMKEY1:$key1:g" $path_to_nginx_work$domainname_create_wp_conf/htdocs/wp-config.php
        sed -i "s:RANDOMKEY2:$key2:g" $path_to_nginx_work$domainname_create_wp_conf/htdocs/wp-config.php
        sed -i "s:RANDOMKEY3:$key3:g" $path_to_nginx_work$domainname_create_wp_conf/htdocs/wp-config.php
        sed -i "s:RANDOMKEY4:$key4:g" $path_to_nginx_work$domainname_create_wp_conf/htdocs/wp-config.php
        sed -i "s:RANDOMKEY5:$key5:g" $path_to_nginx_work$domainname_create_wp_conf/htdocs/wp-config.php
        sed -i "s:RANDOMKEY6:$key6:g" $path_to_nginx_work$domainname_create_wp_conf/htdocs/wp-config.php
        sed -i "s:RANDOMKEY7:$key7:g" $path_to_nginx_work$domainname_create_wp_conf/htdocs/wp-config.php
        sed -i "s:RANDOMKEY8:$key8:g" $path_to_nginx_work$domainname_create_wp_conf/htdocs/wp-config.php
        sed -i "s:wp_TABLEPREFIX:wp_$mysqlname_create_wp_conf:g" $path_to_nginx_work$domainname_create_wp_conf/htdocs/wp-config.php
        echo "`get_log_date` WP_Config edited successfully for $domainname_edit_wp_conf" >> $logdir
}

function print_server_help() {

        echo '%%manage-single-webnode server %% 

                AVAILABLE COMMANDS ARE:

                manage-single-webnode server setup php5
                manage-single-webnode server setup nginx
                manage-single-webnode server setup logrotate
                manage-single-webnode server setup mysql
		manage-single-webnode server setup proftpd'
        
        echo "`get_log_date` Printed help for manage-single-webnode server" >> $logdir
}


function enable_all_user_proftpd () {
        domainname_enable_all_user_proftpd=$1
        for userids in $(sqlite3 /etc/proftpd/proftpdusers.db "SELECT userid FROM users WHERE root_domain='$domainname_enable_all_user_proftpd';"); do
                passwd_orig_enable_all_user_proftpd=$( sqlite3 /etc/proftpd/proftpdusers.db "SELECT passwd_orig FROM users WHERE userid='$userids';")
                sqlite3 /etc/proftpd/proftpdusers.db "UPDATE users SET passwd=\'$passwd_orig_enable_all_user_proftpd\' WHERE userid='$userids';"
        done
}


function disable_all_user_proftpd () {
        domainname_disable_all_user_proftpd=$1
        for userids in $(sqlite3 /etc/proftpd/proftpdusers.db "SELECT userid FROM users WHERE root_domain='$domainname_disable_all_user_proftpd';"); do
		passwd_disable_all_user_proftpd=$( sqlite3 /etc/proftpd/proftpdusers.db "SELECT passwd FROM users WHERE userid='$userids';")
                sqlite3 /etc/proftpd/proftpdusers.db "UPDATE users SET passwd_orig='$passwd_disable_all_user_proftpd' WHERE userid='$userids';"
		random_pw_disable_all_users_proftpd=$(pwgen -s 24 1)
		sqlite3 /etc/proftpd/proftpdusers.db "UPDATE users SET passwd='$random_pw_disable_all_users_proftpd' WHERE userid='$userids';"
        done
}


function delete_all_user_proftpd () {
	domainname_delete_all_user_proftpd=$1
	for userids in $(sqlite3 /etc/proftpd/proftpdusers.db "SELECT userid FROM users WHERE root_domain='$domainname_delete_all_user_proftpd';"); do
		sqlite3 /etc/proftpd/proftpdusers.db "DELETE FROM users WHERE userid='$userids';"
	done
}

function server() {
        action=$1
        todo=$2
        if [ "$action" = "setup" ]; then
                if [ "$todo" = "php5" ]; then
                        if [ ! -f `which php5` ]; then
                                echo "php5 is not installed, should i install it for you? (yes/no)"
                                read answer
                                if [ "$answer" != "yes" ] && [ "$answer" != "no" ]; then
                                        echo "You havent answered with yes or no, please retry"
                                        read answer2
                                        if [ "$answer2" != "yes" ] && [ "$answer2" != "no" ]; then
                                                echo "Aborting, because answer was twice wrong."
                                                echo "`get_log_date` Abort server php5 setup, because of wrong answer in subfunction /installing/" >> $logdir
                                                exit 666
                                        fi
                                elif [ "$answer" != "yes" ]; then
                                        echo "Installing php5 and all needed modules for best experience (php5-mysql, php5-sqlite for example)"
                                        echo "`get_log_date` Installing php5 and all needed modules for best experience (php5-mysql, php5-sqlite for example)" >> $logdir
                                        apt-get -qq install php5-cli php5-common php5-mysql php5-curl php5-sqlite php5-readline php5-fpm
                                        echo "Installed php5 packages"
                                        echo "`get_log_date` Installed php5 Packages from official Repositories" >> $logdir
                                else 
                                        echo "Aborting..."
                                        echo "`get_log_date` Aborted php5 install, because user answer was no" >> $logdir
                                        exit 0
                                fi
                        	if [ "$(cat /etc/php5/fpm/pool.d/www.conf | grep 'group =' | grep 'www-data' | wc -l)" = "1" ]; then
                                	sed -i 's/group = www-data/group = web1/g' /etc/php5/fpm/pool.d/www.conf
                                	sed -i 's_listen = /var/run/php5-fpm.sock_listen = 127.0.0.1:9000_g' /etc/php5/fpm/pool.d/www.conf
                                	sed -i 's/pm = dynamic/pm = ondemand/g' /etc/php5/fpm/pool.d/www.conf
                                	sed -i 's/pm.max_children = 5/pm.max_children = 25/g' /etc/php5/fpm/pool.d/www.conf
                                	echo "`get_log_date` Configured php5" >> $logdir
                                	echo "Configuration of php5 has finished"
                                	#sed -i 's///g' /etc/php5/fpm/pool.d/www.conf  # FALLS MAN NOCH ETWAS BRAUCHT
                                	#sed -i 's///g' /etc/php5/fpm/pool.d/www.conf  # FALLS MAN NOCH ETWAS BRAUCHT
                                	#sed -i 's///g' /etc/php5/fpm/pool.d/www.conf  # FALLS MAN NOCH ETWAS BRAUCHT 
                                	#sed -i 's///g' /etc/php5/fpm/pool.d/www.conf  # FALLS MAN NOCH ETWAS BRAUCHT
                                	service php5-fpm restart
                                	echo "`get_log_date` Restarted php5 because of configuration" >> $logdir
                        	else
                                	echo "It seems like php5 was configured already..."
                                	echo "`get_log_date` Aborted manage-single-webnode server setup php5 because it seems like php5 was configured already" >> $logdir
                                	exit 555
                        	fi
			fi
                fi

                if [ "$todo" = "nginx" ]; then
                        if  [ ! -f /etc/nginx/nginx.conf ]; then
                                echo "nginx is not installed. Should i install it for you? (yes/no)"
                                read answer
                                if [ "$answer" != "yes" ] && [ "$answer" != "no" ]; then
                                        echo "You havent answered with yes or no, please retry"
                                        read answer2
                                        if [ "$answer2" != "yes" ] && [ "$answer2" != "no" ]; then
                                                echo "Aborting, because answer was twice wrong."
                                                echo "`get_log_date` Abort server nginx setup, because of wrong answer in subfunction /installing/" >> $logdir
                                                exit 666
                                        fi
                                elif [ "$answer" != "yes" ]; then
                                        echo "Installing nginx ..."
                                        echo "`get_log_date` Installing nginx" >> $logdir
                                        apt-get -qq install nginx
                                        echo "Installed nginx packages"
                                        echo "`get_log_date` Installed nginx Packages from official Repositories" >> $logdir
                                else
                                        echo "Aborting..."
                                        echo "`get_log_date` Aborted nginx install, because user answer was no" >> $logdir
                                        exit 0
                                fi
                        fi
                        if [ "$(cat /etc/nginx/nginx.conf | grep "$path_to_nginx_conf" | wc -l)" = "0" ] && [ -f /etc/nginx/nginx.conf ]; then
                                sed -i "s:include /etc/nginx/conf.d/*.conf:include $path_to_nginx_conf*.conf:g" /etc/nginx/nginx.conf
                                sed -i 's:768:1024:g' /etc/nginx/nginx.conf
                                sed -i 's:# gzip: gzip:g' /etc/nginx/nginx.conf
                                echo "In which directory should nginx create log files? ex /home (No slash at the end)"
                                read answerdirlog
                                echo "Are you sure that the log-dir should be $answerdirlog? (yes/no)"
                                echo "Even if it's /dev/null the script will accept it."
                                read suredirlog
                                if [ "$suredirlog" != "yes" ] || [ "$suredirlog" != "no" ]; then
                                        echo "Answer was not yes or no, aborting."
                                        echo "`get_log_date` Aborting setting up nginx because answer for logging directory was not valid." >> $logdir
					exit 666
                                elif [ "$suredirlog" = "no" ]; then
                                        echo "In which directory should nginx create log files? ex /home (No slash at the end)"
                                        read answerdirlog
                                        echo "Are you sure that the log-dir should be $answerdirlog? (yes/no)"
                                        echo "Even if it's /dev/null the script will accept it."
                                        read suredirlog
                                        if [ "$suredirlog" = "no" ]; then
                                                echo "Aborting because answer was two times no"
                                                echo "`get_log_date` Aborting setting up nginx because answer for logging directory was two times no." >> $logdir
                                                exit 666
                                        fi
                               	fi 
                                sed -i "s:access_log.*:access_log $answerdirlog/access.log:g" /etc/nginx/nginx.conf
                                sed -i "s:error_log.*:error_log $answerdirlog/error.log:g" /etc/nginx/nginx.conf
                                sed -i "s:SAMPLELOGDIR:$answerdirlog:g" $configsamples/nginx/*.conf
                                echo "Configured nginx"
                                echo "`get_log_date` Configured nginx for command: manage-single-webnode server setup nginx" >> $logdir
                                service nginx restart
                                echo "`get_log_date` Restarted nginx" >> $logdir
                        else
                                echo "It seems nginx was configured already..."
                                echo "`get_log_date` Aborted manage-single-webnode server setup nginx because it seems like nginx was configured already" >> $logdir
                                exit 555
                        fi
                fi
                if [ "$todo" = "logrotate" ]; then
			if [ ! -f `which logrotate` ]; then
				apt-get install -qq -y logrotate
			fi
                        echo "`dirname $logdir`/nginx/*.log {" >> /etc/logrotate.d/nginx
                        echo ' daily
                                missingok
                                dateext
                                dateformat %Y-%m-%d.
                                rotate 180
                                create 0640 www-data adm
                                sharedscripts
                                prerotate
                                if [ -d /etc/logrotate.d/httpd-prerotate ]; then \
                                        run-parts /etc/logrotate.d/httpd-prerotate; \
                                fi; \
                                endscript
                                postrotate
                                [ ! -f /var/run/nginx.pid ] || kill -USR1 `cat /var/run/nginx.pid`
                                endscript
                                }' >> /etc/logrotate.d/nginx
			echo "Installed logrotate successfully"
			exit 0
                fi
                if [ "$todo" = "mysql" ]; then
                        echo "Setting up mysql. You will have to type some passwords in..."
                        apt-get install -y mysql-server
			rc=$?
			if [ "$rc" = "0" ]; then
	                        echo "Installed mysql."
				exit 0
        		else
				echo "Something went wrong... ENable Verbose mode for further information"
			fi
		fi
		if [ "$todo" = "proftpd" ]; then
			apt-get install -y -q proftpd proftpd-mod-sqlite sqlite3
			echo '	DefaultRoot                     ~
				RequireValidShell               on
				PassivePorts                  15000 15250

				<IfModule mod_sql_sqlite.c>
			        SQLBackend sqlite3
				SQLConnectInfo /etc/proftpd/proftpdusers.db
				SQLAuthTypes Crypt Plaintext
				SQLUserInfo users userid passwd uid gid homedir shell
				SQLGroupInfo groups groupname gid members
				</IfModule>' >> /etc/proftpd/proftpd.conf
			echo 'LoadModule mod_sql.c
			      LoadModule mod_sql_sqlite.c' >> /etc/proftpd/modules.conf
			echo 'Should i enable encryption for FTP? (HIGHLY RECOMMENDED) [yes/no]'
			read answer
			if [ "$answer" = "yes" ]; then
				echo '	<IfModule mod_tls.c>
				      	TLSEngine                  on
					TLSLog                     /var/log/proftpd/tls.log
					TLSProtocol                TLSv1.2
					TLSCipherSuite AES128+EECDH:AES128+EDH
					TLSOptions                 AllowClientRenegotiations NoCertRequest NoSessionReuseRequired
					TLSRSACertificateFile      /etc/proftpd/ssl/proftpd.cert.pem
					TLSRSACertificateKeyFile   /etc/proftpd/ssl/proftpd.key.pem
					TLSVerifyClient            off
					TLSRequired                on
					</IfModule>' >> /etc/proftpd/tls.conf
				echo "Include /etc/proftpd/tls.conf" >> /etc/proftpd/proftpd.conf
				echo "Generating Certificate... (You will need too Type some information in"
				echo "It is important, that you set common-name to the domainname clients connecting to the ftp-server"
				echo "If you don't have one, you can use the DNS entry most providers give to you as a default"
				mkdir /etc/proftpd/ssl
				openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/proftpd/ssl/proftpd.key.pem -out /etc/proftpd/ssl/proftpd.cert.pem
				chmod -R 644 /etc/proftpd/ssl
			elif [ "$answer" = "no" ]; then
				echo "Okay, then without encryption. But i've warned you..."
			else
				echo "It seems like you'r answer was wrong. Please try again."
				print_server_help
				exit 15
			fi
			echo "Creating sqlite3 Database"
			sqlite3 /etc/proftpd/proftpdusers.db "CREATE TABLE users (
    						userid VARCHAR(30) NOT NULL UNIQUE,
					        passwd VARCHAR(80) NOT NULL,
    						uid INTEGER UNIQUE,
					        gid INTEGER,
    						homedir VARCHAR(255),
					    	shell VARCHAR(255),
  						passwd_orig VARCHAR(80),
						state VARCHAR(80),
						root_domain VARCHAR(80)
    						);"
			sqlite3 /etc/proftpd/proftpdusers.db "CREATE TABLE groups (
						groupname VARCHAR(80),
						gid INT(4),
						members VARCHAR(255)
						);"
			echo "Done setting up proftpd with sqlite3"
			echo "/bin/false" >> /etc/shells
			service proftpd restart
		else
			print_server_help
			echo "`get_log_date` printed help for server action" >> $logdir
		fi
	
	else
                print_server_help
                echo "`get_log_date` printed help for server action" >> $logdir
        fi
}

function nginx() {
        action=$1
        if [ "$action" = "add" ]; then
                mysqlneed_add_nginx=$5
                premium_costumer=$4
                is_wordpress=$3
                domainname_add_nginx=$2
                if [ "$premiumcostumorenabled" = "true" ]; then
                        if ( [ "$premium_costumer" = "" ] || ( [ "$premium_costumer" != "yes" ] && [ "$premium_costumer" != "no" ] )) || ( [ "$is_wordpress" = "" ] || ([ "$is_wordpress" != "wordpress" ] && [ "$is_wordpress" != "other" ] && [ "$is_wordpress" != "ftp" ])) || ( [ "$domainname_add_nginx" = "" ] || [ "$(echo $domainname_add_nginx | grep -F '.' | wc -l)" != "1" ] ) || ( [ "$mysqlneed_add_nginx" != "yes" ] && [ "$mysqlneed_add_nginx" != "no" ] ); then
                                echo "`get_log_date` CRITICAL: Abort Action /nginx add/ because one ore more variable/s was/were not valid" >> $logdir
                                print_nginx_help
                                exit 5
                        fi
                elif [ "$premiumcostumorenabled" = "false" ]; then
                        if ( [ "$is_wordpress" = "" ] || ([ "$is_wordpress" != "wordpress" ] && [ "$is_wordpress" != "other" ] && [ "$is_wordpress" != "ftp" ])) || ( [ "$domainname_add_nginx" = "" ] || [ "$(echo $domainname_add_nginx | grep -F '.' | wc -l)" != "1" ] ) || ( [ "$mysqlneed_add_nginx" != "yes" ] && [ "$mysqlneed_add_nginx" != "no" ] ); then
                                echo "`get_log_date` CRITICAL: Abort Action /nginx add/ because one ore more variable/s was/were not valid" >> $logdir
                                print_nginx_help
                                exit 5
                        fi
                else
                        mkdir -p $path_to_nginx_work$domainname_add_nginx/htdocs
                        echo "`get_log_date` Created nginx working directory for $domainname_add_nginx" >> $logdir
                fi
                if [ "$is_wordpress" = "wordpress" ]; then
                        if [ "$is_wordpress" = "wordpress" ] && ( [ "$premiumcostumorenabled" = "false" ] || [ "$premium_costumer" = "no" ] ); then
                                create_nginx_conf_add $domainname_add_nginx $is_wordpress no
                        elif [ "$is_wordpress" = "wordpress" ] && ( [ "$premiumcostumorenabled" = "true" ] && [ "$premium_costumer" = "yes" ] ); then
                                create_nginx_conf_add $domainname_add_nginx $is_wordpress yes
                        fi
                        wget -P $path_to_nginx_work$domainname_add_nginx/htdocs https://de.wordpress.org/latest-de_DE.zip
                        unzip $path_to_nginx_work$domainname_add_nginx/htdocs/latest-de_DE.zip -d $path_to_nginx_work$domainname_add_nginx/htdocs/
                        mv $path_to_nginx_work$domainname_add_nginx/htdocs/wordpress/* $path_to_nginx_work$domainname_add_nginx/htdocs/
                        rm -rf $path_to_nginx_work$domainname_add_nginx/htdocs/wordpress
                        rm $path_to_nginx_work$domainname_add_nginx/htdocs/latest-de_DE.zip 
                        find $path_to_nginx_work$domainname_add_nginx/htdocs -type d -exec chmod 775 {} +
                        find $path_to_nginx_work$domainname_add_nginx/htdocs -type f -exec chmod 664 {} +
                        chown -R web1:web1 $path_to_nginx_work$domainname_add_nginx/htdocs
                        if [ "$mysqlneed_add_nginx" = "yes" ]; then
                                mysqlpw=`pwgen -s -1 50`
                                mysqlname=$(echo $domainname_add_nginx | tr '.' ' ' | sed 's/ //g' | sed 's/-//g')
                                mysqluser=`pwgen -1 -0 15`
                                mysql_create_database $mysqlname $mysqlpw $mysqluser
                                create_wp_config_database_name_pw $mysqlname $mysqlpw $mysqluser $domainname_add_nginx
                                service nginx reload
                                echo "`get_log_date` Reloaded nginx" >> $logdir
                        fi
                elif [ "$is_wordpress" = "other" ]; then
                        if [ "$is_wordpress" = "wordpress" ] && ( [ "$premiumcostumorenabled" = "false" ] || [ "$premium_costumer" = "no" ] ); then
                                create_nginx_conf_add $domainname_add_nginx $is_wordpress no
                        elif [ "$is_wordpress" = "wordpress" ] && ( [ "$premiumcostumorenabled" = "true" ] && [ "$premium_costumer" = "yes" ] ); then
                                create_nginx_conf_add $domainname_add_nginx $is_wordpress yes
                        fi
                        create_nginx_conf_add $domainname_add_nginx $is_wordpress $premium_costumer
                        find $path_to_nginx_work$domainname_add_nginx/htdocs -type d -exec chmod 775 {} +
                        find $path_to_nginx_work$domainname_add_nginx/htdocs -type f -exec chmod 664 {} +
                        chown -R web1:web1 $path_to_nginx_work$domainname_add_nginx/htdocs
                        service nginx reload  
                        echo "`get_log_date` Reloaded nginx" >> $logdir
                        #elif FTP!!!!!!!!!!!!!11  -> v0.3
                fi
                        echo '
                        ATTENTION!!!

                        IF YOU WANT TO ADD FTP TOO YOU HAVE TO DO THIS WITH THE manage-single-webnode proftpd add COMMAND!!!
                        '
			exit 0
        elif [ "$action" = "delete" ]; then
                domainname_delete_nginx=$2
                if ( [ "$domainname_delete_nginx" = "" ] || [ "$(echo $domainname_delete_nginx | grep -F '.' | wc -l)" != "1" ] ); then
                        echo "`get_log_date` CRITICAL: Abort Action /nginx delete/ because one ore more variable/s was/were not valid" >> $logdir
                        print_nginx_help
                        exit 5
                fi

                echo '
                ATTENTION!! ARE YOU SURE YOU SHOULD DO THAT? IF YOU ARE NOT PLEASE USE manage-single-webnode nginx disable COMMAND!'
                echo ""
                echo "Are you sure? (yes/no)"
                read sure

                if [ "$sure" = "yes" ]; then
                        echo "Okay, we are beginning deleting the Costumer $domainname_delete_nginx"
                        if [ ! -d "$path_to_nginx_work$domainname_delete_nginx" ]; then
                                echo "`get_log_date` CRITICAL: Abort Action /nginx delete $domainname_delete_nginx/ because working dir in nginx for Costumer was not found" >> $logdir
                                echo "$domainname_delete_nginx does not exist!"
                                exit 5
                        else
                                if [ -f path_to_nginx_work$domainname_delete_nginx/htdocs/wp-config.php ]; then
                                        database_user_delete_nginx=`cat $path_to_nginx_work$domainname_delete_nginx/htdocs/wp-config.php | grep 'DB_USER' | cut -d ',' -f 2 | sed "s/'/\n/g" | sed -n 2p`
                                        mysqlname_delete=$(echo $domainname_delete_nginx | tr '.' ' ' | sed 's/ //g')
                                        delete_database_mysql $mysqlname_delete $database_user_delete_nginx
                                fi
                                rm -rf $path_to_nginx_work$domainname_delete_nginx
                                rm $path_to_nginx_conf$domainname_delete_nginx.conf
                                echo "`get_log_date` Deleted Costumer $domainname_delete_nginx for nginx" >> $logdir
                                service nginx reload
                                echo "`get_log_date` Reloaded nginx" >> $logdir
                        fi
                        echo '
                        ATTENTION!!!

                        YOU HAVE TO DELETE FTP FOR THIS COSTUMER. USE manage-single-webnode proftpd delete COMMAND!!!
                        IF A DATABASED WAS USED FOR THIS COSTUMER AND IT WAS NOT WORDPRESS HE WAS USING YOU
                        GAVE TO DELETE IT MANUALLY!!!!!!!!!!!!
                        '
                else
                        echo "We do NOTHING here. Bye."
                        exit 0
                fi
        elif [ "$action" = "disable" ]; then
                domainname_disable_nginx=$2
                multiple_or_one_disable_nginx=$3
                echo $domainname_disable_nginx
                if ( [ "$domainname_disable_nginx" = "" ] || [ "$(echo $domainname_disable_nginx | grep -F '.' | wc -l)" != "1" ] ); then
                        echo "`get_log_date` CRITICAL: Abort Action /nginx disable/ because one ore more variable/s was/were not valid" >> $logdir
                        echo "Aborting because domainname aka. Costumer Value was NOT valid!"
                        print_nginx_help
                        exit 5
                fi

                if [ "`ls $path_to_nginx_conf | grep $domainname_disable_nginx | wc -l`" = "0" ]; then
                        echo "`get_log_date` CRITICAL: Abort Action /nginx disable $domainname_disable_nginx/ because nginx conf for Costumer was not found" >> $logdir
                        echo "$domainname_disable_nginx does not exist or is already disabled!"
                        exit 5
                elif [ "$(echo $multiple_or_one_disable_nginx)" != "" ]; then
                        if [ "`echo $multiple_or_one_disable_nginx`" != "one" ] && [ "`echo $multiple_or_one_disable_nginx`" != "all" ]; then
                                echo 'You can only use this command like this: nginx disable $domainname one/all'
                                echo "`get_log_date` Action nginx disables because Variables were damaged (all/one)" >> $logdir
                                exit 69
                        elif [ "`echo $multiple_or_one_disable_nginx`" = "all" ]; then
                                disable_all_nginx_confs $domainname_disable_nginx
                                service nginx reload
                        elif [ "`echo $multiple_or_one_disable_nginx`" = "one" ]; then
                                if [ ! -f $path_to_nginx_conf$domainname_disable_nginx.conf ]; then
                                        echo "Aborted because config File doesnt exist or costumer is already disabled"
                                        echo "`get_log_date` Abordet because Costumer config File for nginx was not found" >> $logdir
                                        exit 6
                                else
                                        mv $path_to_nginx_conf$domainname_disable_nginx.conf $path_to_nginx_conf$domainname_disable_nginx.conf.off
                                        echo "`get_log_date` Disabled $domainname_disable_nginx in nginx" >> $logdir
                                        service nginx reload
                                        echo "`get_log_date` Reloaded nginx" >> $logdir
                                fi
                        else
                                print_nginx_help
                                exit 5
                        fi
                fi
                echo '
                ATTENTION!!!

                YOU HAVE TO DISABLE FTP FOR THIS COSTUMER. USE manage-single-webnode proftpd disable COMMAND!!!
                '
                exit 0
        elif [ "$action" = "block" ];then
                domainname_block_nginx=$2
                multiple_or_one_block_nginx=$3
                init_reason=$4
                if ( [ "$domainname_block_nginx" != "" ] || [ "$(echo $domainname_block_nginx | grep -F '.' | wc -l)" = "1" ] ) && ( [ "$multiple_or_one_block_nginx" = "one" ] || [ "$multiple_or_one_block_nginx" = "all" ] ); then
                        if [ "$init_reason" = "" ]; then
                                echo "You didn't put a reason as a parameter. Do you want to set one? [yes/no]"
                                echo "`get_log_date` no reason provided in /manage-single-webnode nginx block/ command. Asking for a string." >> $logdir
                                read answer
                                if [ "$answer" = "yes" ]; then
                                        echo 'Please enter the reason. Following will be displayed at the URL: The webspace was deactivated because $reason'
                                        read reason
                                        echo "You entered $reason. Is that correct? [yes/no]"
                                        read answer
                                        if [ "$answer" = "yes" ]; then
                                                used_reason=$( echo $reason )
                                                echo "`get_log_date` set reason in /manage-single-webnode nginx block/ after aksing for it." >> $logdir
                                        elif [ "$answer" = "no" ]; then
                                                echo "Okay, then i'm terminating myself. Please restart."
                                                echo "`get_log_date` answer was no after asking for reason in /manage-single-webnode nginx block/, so were ending right here" >> $logdir
                                                exit 44
                                        else
                                                echo "No valid answer received. Terminating..."
                                                echo "`get_log_date` answer was not valid after asking for reason in /manage-single-webnode nginx block/. Terminated." >> $logdir
                                                print_nginx_help
                                                echo "`get_log_date` printed nginx help." >> $logdir
                                                exit 69
                                        fi
                                elif [ "$answer" = "no" ]; then
                                        echo "Setting reason=none. Using standart blocked page."
                                        used_reason=none
                                else
                                        print_nginx_help
                                fi
                        fi
                        used_reason=$( echo $init_reason )
                        if [ "$multiple_or_one_block_nginx" = "one" ]; then
                                if [ ! -f $path_to_nginx_conf$domainname_block_nginx.conf ]; then
                                        echo "Aborted because config File doesnt exist or costumer is already blocked/disabled"
                                        echo "`get_log_date` Abordet because Costumer config File for nginx was not found" >> $logdir
                                        exit 6
                                else
                                        mv $path_to_nginx_conf$domainname_block_nginx.conf $path_to_nginx_conf$domainname_block_nginx.conf.off
                                        echo "`get_log_date` Disabled $domainname_block_nginx in nginx" >> $logdir
                                        cp $configsamples/nginx/default_issues.conf $path_to_nginx_conf$domainname_block_nginx-blocked.conf
                                        if [ "$used_reason" = "none" ]; then
                                                sed -i "s:REASON:there was some problem occuring.:g" $path_to_nginx_conf$domainname_block_nginx-blocked.conf
                                        fi
                                        sed -i "s:REASON:$used_reason:g" $path_to_nginx_conf$domainname_block_nginx-blocked.conf
                                        sed -i "s:ROOTDOMAINNAME:$domainname_block_nginx:g" $path_to_nginx_conf$domainname_block_nginx-blocked.conf
                                        service nginx reload
                                        echo "`get_log_date` Reloaded nginx" >> $logdir
                                fi
                        elif [ "`echo $multiple_or_one_block_nginx`" = "all" ]; then
                                disable_all_nginx_confs $domainname_block_nginx
                                cp $configsamples/nginx/default_issues.conf $path_to_nginx_conf$domainname_block_nginx-blocked.conf
                                if [ "$used_reason" = "none" ]; then
                                        sed -i "s:REASON:there was some problem occuring.:g" $path_to_nginx_conf$domainname_block_nginx-blocked.conf
                                fi
                                sed -i "s:REASON:$used_reason:g" $path_to_nginx_conf$domainname_block_nginx-blocked.conf
                                sed -i "s:ROOTDOMAINNAME:.$domainname_block_nginx:g" $path_to_nginx_conf$domainname_block_nginx-blocked.conf
                                service nginx reload
                        else
                                print_nginx_help
                        fi
			print_nginx_help
                fi
	elif [ "$action" = "unblock" ]; then
		domainname_unblock_nginx=$2
		multiple_or_one_unblock_nginx=$3
		if ( [ "$domainname_unblock_nginx" != "" ] || [ "$(echo $domainname_unblock_nginx | grep -F '.' | wc -l)" = "1" ] ) && ( [ "$multiple_or_one_unblock_nginx" = "one" ] || [ "$multiple_or_one_unblock_nginx" = "all" ] ); then
			if [ ! -f $path_to_nginx_conf$domainname_unblock_nginx-blocked.conf ]; then
				echo "Aborted because config File doesnt exist or costumer is unblocked/enabled"
                                echo "`get_log_date` Abordet at /unblock/ because Costumer config File for nginx was not found" >> $logdir
                                exit 6
				if [ "$multiple_or_one_unblock_nginx" = "one" ]; then
                        		rm $path_to_nginx_conf$domainname_unblock_nginx-blocked.conf
					mv $path_to_nginx_conf$domainname_unblock_nginx.conf.off $path_to_nginx_conf$domainname_unblock_nginx.conf
					service nginx reload
				elif [ "`echo $multiple_or_one_unblock_nginx`" = "all" ]; then
                                	enable_all_nginx_confs $domainname_unblock_nginx
	                                rm $path_to_nginx_conf$domainname_block_nginx-blocked.conf
					service nginx reload
                	        else
                        	        print_nginx_help
	                        fi
        	                print_nginx_help
                	fi
		fi
        elif [ "$action" = "enable" ]; then
                domainname_enable_nginx=$2
                enable_because_issue_resolved=$3
                if ( [ "$domainname_enable_nginx" = "" ] || [ "$(echo $domainname_enable_nginx | grep -F '.' | wc -l)" != "1" ] ); then
                        echo "`get_log_date` CRITICAL: Abort Action /nginx enable/ because one ore more variable/s was/were not valid" >> $logdir
                        print_nginx_help
                        exit 5
                fi

                if [ "`ls $path_to_nginx_conf | grep $domainname_enable_nginx | wc -l`" = "0" ]; then
                        echo "`get_log_date` CRITICAL: Abort Action /nginx disable $domainname_enable_nginx/ because nginx conf for Costumer was not found" >> $logdir
                        echo "$domainname_enable_nginx does not exist or is not disabled!"
                        exit 5
                elif [ "`echo $enable_because_issue_resolved`" != "one" ] && [ "`echo $enable_because_issue_resolved`" != "all" ]; then
                        echo 'You can only use this command like this: nginx enable $domainname one/all'
                        echo "`get_log_date` Action nginx enable because Variables were damaged (all/one)" >> $logdir
                        exit 70
                elif [ "`echo $enable_because_issue_resolved`" = "all" ]; then
                        enable_all_nginx_confs $domainname_enable_nginx
			service nginx reload
                elif [ "`echo $enable_because_issue_resolved`" = "one" ]; then
                        if [ ! -f $path_to_nginx_conf$domainname_enable_nginx.conf.off ]; then
                                echo "Aborted because config File doesnt exist or costumer is already enabled"
                                echo "`get_log_date` Abordet because Costumer config File for nginx was not found" >> $logdir
                                exit 6
                        else
                                mv $path_to_nginx_conf$domainname_enable_nginx.conf.off $path_to_nginx_conf$domainname_enable_nginx.conf
                                echo "`get_log_date` Disabled $domainname_enable_nginx in nginx" >> $logdir
                                service nginx reload
                                echo "`get_log_date` Reloaded nginx" >> $logdir
                        fi
                fi
                echo '
                        ATTENTION!!!

                        IF YOU WANT TO RE-ENABLE FTP FOR THIS COSTUMER. USE manage-single-webnode proftpd enable COMMAND!!!
                        '
                        exit 0
        else
                echo "`get_log_date` Printed help for nginx" >> $logdir
                print_nginx_help
                exit 5
        fi
}

function proftpd () {
	action=$1
	if [ "$action" = "add" ]; then
		domainname_proftpd_add=$2
		directory_proftpd_add=$3
		username_proftpd_add=$4
		password_proftpd_add=$5
		if [ "$(echo $domainname_proftpd_add | grep -F '.' | wc -l)" = "1" ] && ( [ "$username_proftpd_add" != "" ] && [ "$username_proftpd_add" != "--i-really-want-to-choose-my-password-by-myself" ] ) && [ -d $directory_proftpd_add ]; then
			if [ "$password_proftpd_add" = "--i-really-want-to-choose-my-password-by-myself" ]; then
				echo "Okay, you want to choose the password for yourself. Please enter it now"
				read -s password_proftpd_add_1
				echo "Please re-enter password"
				read -s password_proftpd_add_2
				if [ "$password_proftpd_add_2" = "$password_proftpd_add_1" ]; then
					echo "Password matched. Setting as password for the user: $username_proftpd_add"
					password_proftpd_add=$password_proftpd_add_1
				else
					echo "Please try again. Passwords didn't match."
					read -s password_proftpd_add_1
	        		        echo "Please re-enter password"
	        	        	read -s password_proftpd_add_2
					if [ "$password_proftpd_add_2" = "$password_proftpd_add_1" ]; then
		        	                echo "Password matched. Setting as password for the user: $username_proftpd_add"
	        		                password_proftpd_add=$password_proftpd_add_1
					else
						print_proftpd_help
						exit 15
					fi
				fi
			else
				echo "I will generate a random secure password."
				password_proftpd_add=$(pwgen -s 24 1)
			fi
			if [ "$(echo $directory_proftpd_add | grep -i $domainname_proftpd_add | wc -l)" = "0" ]; then
				echo "It seems like the directory does not match the domainname."
				echo "If you DONT want it in that way please answer with [DONT DO]."
				read answer
				if [ "$answer" = "DONT DO" ]; then
					echo "Terminating"
					print_proftpd_help
					exit 16
				fi
			fi
			sqlite3 /etc/proftpd/proftpdusers.db "INSERT INTO users VALUES ('$username_proftpd_add','$password_proftpd_add','1010','1010','$directory_proftpd_add','/bin/false',' ','active','$domainname_proftpd_add');"
			echo "Created user."
		else
			print_proftpd_help
			exit 15
		fi
	elif [ "$action" = "disable" ]; then
		username_proftpd_disable=$2
		one_or_all_proftpd_disable=$3
		domainname_proftpd_disable=$4
		if [ "$one_or_all_proftpd_disable" = "one" ] && [ "$( sqlite3 /etc/proftpd/proftpdusers.db "SELECT * from users where userid='$username_proftpd_disable';" | wc -l)" != "0" ]; then
			password_before_proftpd_disable=$(sqlite3 /etc/proftpd/proftpdusers.db "SELECT passwd FROM users WHERE userid='$username_proftpd_disable';")
			random_pw_proftpd_disable=$(pwgen -s 24 1)
			sqlite3 /etc/proftpd/proftpdusers.db "UPDATE users SET passwd_orig='$password_before_proftpd_disable', passwd='$random_pw_proftpd_disable';"
			echo "Disabled user $username_proftpd_disable"
			exit 0
		elif [ "$one_or_all_proftpd_disable" = "all" ] && [ "$username_proftpd_disable" = "none" ] && [ "$(sqlite3 /etc/proftpd/proftpdusers.db "SELECT root_domain FROM users WHERE root_domain='$domainname_proftpd_disable';" | wc -l )" != "0" ]; then
			disable_all_user_proftpd $domainname_proftpd_disable
			echo "Disabled all users for root_domain: $domainname_proftpd_disable"
		else
			print_proftpd_help
			exit 16
		fi
	elif [ "$action" = "enable" ]; then
		username_proftpd_enable=$2
                one_or_all_proftpd_enable=$3
                domainname_proftpd_enable=$4
                if [ "$one_or_all_proftpd_enable" = "one" ] && [ "$( sqlite3 /etc/proftpd/proftpdusers.db "SELECT * from users where userid='$username_proftpd_enable';" | wc -l)" != "0" ]; then
                        password_before_proftpd_enable=$(sqlite3 /etc/proftpd/proftpdusers.db "SELECT passwd_orig FROM users WHERE userid='$username_proftpd_enable';")
                        sqlite3 /etc/proftpd/proftpdusers.db "UPDATE users SET passwd='$password_before_proftpd_enable'"
                        echo "Enabled user $username_proftpd_enable"
                        exit 0
                elif [ "$one_or_all_proftpd_enable" = "all" ] && [ "$username_proftpd_enable" = "none" ] && [ "$(sqlite3 /etc/proftpd/proftpdusers.db "SELECT root_domain FROM users WHERE root_domain='$domainname_proftpd_enable';" | wc -l )" != "0" ]; then
                        enable_all_user_proftpd $domainname_proftpd_enable
                        echo "Enabled all users for root_domain: $domainname_proftpd_enable"
                else
                        print_proftpd_help
                        exit 16
                fi
	elif [ "$action" = "delete" ]; then
		username_proftpd_delete=$2
                one_or_all_proftpd_delete=$3
                domainname_proftpd_delete=$4
                if [ "$one_or_all_proftpd_delete" = "one" ] && [ "$( sqlite3 /etc/proftpd/proftpdusers.db "SELECT * from users where userid='$username_proftpd_delete';" | wc -l)" != "0" ]; then
                        echo "Are you 100% sure that you want to delete this user? If not look at the proftpd to just disable him."
			echo "If you are sure press ENTER. If not CTRL-C."
			read trash
			sqlite3 /etc/proftpd/proftpdusers.db "DELETE FROM users WHERE userid='$username_proftpd_delete'"
                        echo "Deleted user $username_proftpd_delete"
                        exit 0
                elif [ "$one_or_all_proftpd_delete" = "all" ] && [ "$username_proftpd_delete" = "none" ] && [ "$(sqlite3 /etc/proftpd/proftpdusers.db "SELECT root_domain FROM users WHERE root_domain='$domainname_proftpd_delete';" | wc -l )" != "0" ]; then
			echo "Are you 100% sure that you want to delete all users with this root_domain?" 
			echo "If not look at the proftpd to just disable them."
			echo "If you are sure press ENTER. If not CTRL-C."
			read trash
			echo "Sorry to bother, but are you really really sure?"
			echo "If you are really really sure press ENTER. If not CTRL-C."
			read trash
                        delete_all_user_proftpd $domainname_proftpd_delete
                        echo "Deleted all users for root_domain: $domainname_proftpd_delete"
                else
                        print_proftpd_help
                        exit 16
                fi
	elif [ "$action" = "show" ]; then
		sqlite3 /etc/proftpd/proftpdusers.db "SELECT * FROM users;"
	else
		print_proftpd_help
		exit 16
	fi
}

#function ftp-manage-in-nginx-please () {
#        action=$1
#        if [ "$action" = "add" ]; then
#                domainname_add_proftpd=$2
#                should_add_user_ftp_add=$3
#                if [ ! -n "$should_add_user_ftp_add" ]; then
#                        mkdir /home/web/ftp_manage/$domainname_add_proftpd/htdocs
#                        echo "`get_log_date` Created working dir for FTP-Interface for $domainname_add_proftpd" >> $logdir
#                        cp /home/samples/proftpd/webinterface/* /home/web/ftp_manage/$domainname_add_proftpd/htdocs
#                        echo "`get_log_date` Copied Data for Interface for $domainname_add_proftpd" >> $logdir
#                        nginx add ftp-manage.$domainname_add_proftpd ftp no no
#                        domainname_add_proftpd_cutted=$(echo "domainname_add_proftpd" | cut -d '.' -f 1) # FUNKTIONIERT NUR MIT EINEM PUNKT IN EINER SUBDOMAIN
#                        proftpd_add_admin_username=$(echo "$domainname_add_proftpd_cutted-admin")
#                        proftpd_add_admin_pw=$(pwgen -s 24)
#                        sed -i 's:ADMINUSER1234:$proftpd_add_admin_username:g' /home/web/ftp_manage/$domainname_add_proftpd/htdocs/run.php
#                        sqlite3 $proftpd_sqlite3_database_lcoation "INSERT INTO users VALUES ('$proftpd_add_admin_username','$proftpd_add_admin_pw','1001','1001','$path_to_nginx_work$domainname_add_proftpd/htdocs','/bin/false')"
#                        echo "`get_log_date` Created Admin user and configured Managemend Interface" >> $logdir
#                        service nginx reload
#                elif [ "$should_add_user_ftp_add" = "user" ]; then
#                        username_proftpd_add=$4
#                        if [ ! -n "username_proftpd_add" ]; then
#                                echo "You have to enter a correct Username!" 
#                                echo "`get_log_date` Aborted action proftpd add $domainname_add_proftpd user because of wrong username" >> $logdir
#                                exit 453
#                        fi
#                        proftpd_random_pw=$(pwgen -s 24)
#                        sqlite3 $proftpd_sqlite3_database_lcoation "INSERT INTO users VALUES ('$username_proftpd_add','$proftpd_random_pw','1001','1001','$path_to_nginx_work$domainname_add_proftpd/htdocs','/bin/false')"
#                else
#                        print_proftpd_help
#                        exit 564
#                fi
#
#        elif [ "$action" = "delete" ]; then
#                ##                                        !!!
#                ##      EINZELNEN USER LÖSCHEN KÖNNEN     !!!
#                ##                                        !!!
#                echo '
#                ATTENTION!! ARE YOU SURE YOU SHOULD DO THAT?'
#                echo ""
#                echo "Are you sure? (yes/no)"
#                read sure
#
#                if [ "$sure" = "yes" ]; then
#                        domainname_delete_proftpd=$2
#                        rm -rf /home/web/ftp_manage/$domainname_delete_proftpd
#                        sqlite3 $proftpd_sqlite3_database_lcoation "DELETE FROM users WHERE homedir LIKE '%$domainname_delete_proftpd%'"
#                        echo "`get_log_date` FTP-Manage Interface and Account from$domainname_delete_proftpd deleted" >> $logdir
#                else
#                        echo 'WE DO NOTHING HERE!'
#                        echo "`get_log_date` Delete FTP for $domainname_delete_proftpd aborted!" >> $logdir
#                fi
#        else
#                print_proftpd_help
#                exit 1
#        fi
#}
#
# -> v0.3

if [ "$asked_if_variables_are_correct" = "false" ]; then
	echo "You started the script the first time? Have you set all variables for your invironment?"
	echo "We suggest set nginx_work to the partition of the drive with the most of space. (If you have partitions"
	echo "If you've setupped your server with a single partition (usually /) you can keep the variables as they are."
	echo "Type Enter to restart. STRG-C if you want to edit the variables."
	read trash
	/bin/bash -c "sleep 0.2 ; sed -i s/asked_if_variables_are_correct=false/asked_if_variables_are_correct=true/g'" &
	exit 0
fi

if [ "$( grep -c debian /proc/version )" = "1" ] || [ "$( grep -c ubuntu /proc/version )" = "1" ]; then
	echo "This script is currently only tested with debian and ubuntu."
	echo "If you proceed anyways just type ENTER. If not CTRL-C"
	read trash
fi

setup_script

if [ "$1" = "nginx" ]; then
        nginx $2 $3 $4 $5 $6
elif [ "$1" = "proftpd" ]; then
        proftpd $2 $3 $4 $5 $6
elif [ "$1" = "server" ]; then
        server $2 $3 $4
else
        print_main_help
fi
