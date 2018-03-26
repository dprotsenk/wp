#!/bin/bash

MYSQL_PASS=mypass
WORDPRESS_USER=wordpressuser
WORDPRESS_DB=wordpress
WORDPRESS_PASS=wordpress

print_logs () {
	echo "########################################################"
	echo " "
	echo $1
	echo " "
	echo "########################################################"
}

##################################################################
############################START
##################################################################
print_logs "Start system update and install additional applications"
	apt-get update
	apt-get install curl wget zip unzip -y
	debconf-set-selections <<< "mysql-server mysql-server/root_password password ${MYSQL_PASS}"
	debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${MYSQL_PASS}"
	apt-get install mysql-server mysql-client -y
	apt-get install apache2 -y
	wget https://www.dotdeb.org/dotdeb.gpg
	echo -e "deb http://packages.dotdeb.org jessie all\ndeb-src http://packages.dotdeb.org jessie all" > /etc/apt/sources.list.d/dotdeb.list
	apt-get update 2> err
	apt-key adv --keyserver keys.gnupg.net --recv-keys $(grep NO_PUBKEY err |cut -d "Y" -f2)
	rm err
	apt-get update
	apt-get install php7.0 libapache2-mod-php7.0 -y
print_logs " Finished with system update and application install"
############################################################################
#####################    MYSQL ADD USER/DB   ###########################
print_logs "Start MYSQL configuration"

mysql -uroot -p${MYSQL_PASS} <<MYSQL_SCRIPT
CREATE DATABASE ${WORDPRESS_DB} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
GRANT ALL ON ${WORDPRESS_DB}.* TO '${WORDPRESS_USER}'@'localhost' IDENTIFIED BY '${WORDPRESS_PASS}';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

######################################################################
#######   APACHE2    ############################
print_logs "Start Apache2 configuration"

echo 'Mutex file:${APACHE_LOCK_DIR} default
PidFile ${APACHE_PID_FILE}
Timeout 300

KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 5
User ${APACHE_RUN_USER}
Group ${APACHE_RUN_GROUP}
HostnameLookups Off
ErrorLog ${APACHE_LOG_DIR}/error.log
LogLevel warn
IncludeOptional mods-enabled/*.load
IncludeOptional mods-enabled/*.conf
Include ports.conf
<Directory />
        Options FollowSymLinks
        AllowOverride None
        Require all denied
</Directory>

<Directory /usr/share>
        AllowOverride None
        Require all granted
</Directory>

<Directory /var/www/>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
</Directory>
AccessFileName .htaccess
<FilesMatch "^\.ht">
        Require all denied
</FilesMatch>
LogFormat "%v:%p %h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" vhost_combined
LogFormat "%h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" combined
LogFormat "%h %l %u %t \"%r\" %>s %O" common
LogFormat "%{Referer}i -> %U" referer
LogFormat "%{User-agent}i" agent
IncludeOptional conf-enabled/*.conf
IncludeOptional sites-enabled/*.conf
' > /etc/apache2/apache2.conf
############################################################################
print_logs "Start WORDPRESS configuration"
	apt-get install php-curl php-gd php-mbstring php-mcrypt php-xml php-xmlrpc -y
	systemctl restart apache2
	a2enmod rewrite
	systemctl restart apache2
	cd /var/www/html
	wget http://wordpress.org/latest.zip
	unzip latest.zip
	mv wordpress/* .
	rm -rf latest.zip
	touch /var/www/html/.htaccess
	chmod 660 /var/www/html/.htaccess
	mkdir /var/www/html/wp-content/upgrade
	find /var/www/html -type d -exec chmod g+s {} \;
	chmod g+w /var/www/html/wp-content
	chmod -R g+w /var/www/html/wp-content/themes
	chmod -R g+w /var/www/html/wp-content/plugin

	CURL_WP_SECRET=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)

echo "<?php
define('DB_NAME', '$WORDPRESS_DB');
define('DB_USER', '$WORDPRESS_USER');
define('DB_PASSWORD', '$WORDPRESS_PASS');
define('DB_HOST', 'localhost:3306');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

$CURL_WP_SECRET

\$table_prefix  = 'wp_';
define('WP_DEBUG', false);
if ( !defined('ABSPATH') )
        define('ABSPATH', dirname(__FILE__) . '/');
define('WP_ALLOW_REPAIR', true);
require_once(ABSPATH . 'wp-settings.php');" > /var/www/html/wp-config.php
	chown -R www-data:www-data /var/www/html
	rm /var/www/html/index.html
	apt-get install  php7.0-mysqlnd
###############################################################
print_logs "Restart Apache2"
	systemctl restart apache2

##################################################################
############################The End
##################################################################
