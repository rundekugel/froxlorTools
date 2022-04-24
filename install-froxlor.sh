#!/bin/bash

#
# Downloading, installing and configuring froxlor with nginx + php-fpm via debian package
# for DEBIAN BULLSEYE (11)
#
# Target database and privileged user 'froxroot' should not exist. The given unprivileged
# database user will be created for localhost and should also not exist.
#
# A new blank froxlor database will be filled with the default sql file and a given
# admin user as well as default ip/port entries for port 80 and 443 (ssl-enabled + let's encrypt).
#
# The needed credentials are all given via a JSON parameter file as first parameter to this script.
# Example:
# {
#    "mysql": {"rootpasswd":"xxx", "db":"froxlor", "user":"froxlor", "userpasswd":"xxx"},
#    "froxlor":{"hostname":"froxhost","ipaddr":"127.0.0.1","adminuser":"admin","adminpasswd":"xxx"}
# }
#
# For the settings-adjustments, a prior exported froxlor-settings file is optional and can be
# passed as second parameter to this script.
#
# Authors: froxlor GmbH, 2022
#

if [ -z "$1" ]; then
	echo "JSON parameter file needed"
	exit -1
fi
if [ -f "$1" ]; then
	JPARAM="$1"
else
	echo "JSON parameter file does not exist"
	exit -1
fi

if [ -f "$2" ]; then
	froxsettingsexport="$2"
fi

export DEBIAN_FRONTEND=noninteractive
echo 'APT::Get::Assume-Yes "true";' > /tmp/_tmp_apt.conf
export APT_CONFIG=/tmp/_tmp_apt.conf

echo "Installing requirements"
apt-get -q install apt-transport-https lsb-release ca-certificates curl
echo "Downloading froxlor gpg key for deb.froxlor.org repository"
curl -sSLo /usr/share/keyrings/deb.froxlor.org-froxlor.gpg https://deb.froxlor.org/froxlor.gpg
echo "Adding repository to /etc/apt/sources.list.d/froxlor.list"
sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.froxlor.org-froxlor.gpg] https://deb.froxlor.org/debian $(lsb_release -sc) main" > /etc/apt/sources.list.d/froxlor.list'

echo "Installing overwrites for froxlor debian packages"
apt update
apt -q upgrade
apt -q install nginx screen mc git
apt -q install php php-fpm php-mysql php-xml php-mbstring php-gd php-curl php-bcmath php-zip php-ldap php-cgi
apt -q install mlocate gnupg jq
apt -q install mariadb-client mariadb-server
updatedb

echo "Installing froxlor package"
apt -q install froxlor

echo "Setting required values from parameter file"
rootpasswd=$(jq -r '.mysql.rootpasswd' $JPARAM)
mysqldb=$(jq -r '.mysql.db' $JPARAM)
mysqluser=$(jq -r '.mysql.user' $JPARAM)
mysqlpwd=$(jq -r '.mysql.userpasswd' $JPARAM)
froxhost=$(jq -r '.froxlor.hostname' $JPARAM)
froxip=$(jq -r '.froxlor.ipaddr' $JPARAM)
froxadmin=$(jq -r '.froxlor.adminuser' $JPARAM)
froxpwd=$(jq -r '.froxlor.adminpasswd' $JPARAM)

echo "Setting up privileged mysql user"
mysql -e "CREATE USER 'froxroot'@'localhost' IDENTIFIED BY '${rootpasswd}';"
mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'froxroot'@'localhost' WITH GRANT OPTION;"

echo "Setting up froxlor database and user"
mysqldb=${mysqldb:-froxlor}
mysqluser=${mysqluser:-froxlor}
mysql -e "CREATE DATABASE ${mysqldb}"
mysql -e "CREATE USER '${mysqluser}'@'localhost' IDENTIFIED BY '${mysqlpwd}';"
mysql -e "GRANT ALL PRIVILEGES ON ${mysqldb}.* TO '${mysqluser}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

echo "Importing froxlor database layout"
mysql ${mysqldb} </var/www/froxlor/install/froxlor.sql

echo "Setting up admin user for froxlor"
froxadmin=${froxadmin:-admin}
# using md5 for simplicity, it will be updated in the database after the first login to whatever hash-algorithm is specified in the settings
froxpwd=`php -r "echo md5('${froxpwd}');"`

echo "Adding main admin user"
echo "TRUNCATE TABLE \`panel_admins\`;" > /tmp/froxlor-admin.sql
echo "INSERT INTO \`panel_admins\` SET \`loginname\` = '${froxadmin}', \`password\` = '${froxpwd}', \`name\` = 'Siteadmin', \`email\` = 'admin@${froxhost}', \`api_allowed\` = 1, \`customers\` = -1, \`customers_see_all\` = 1, \`caneditphpsettings\` = 1, \`domains\` = -1, \`domains_see_all\` = 1, \`change_serversettings\` = 1, \`diskspace\`  = -1024, \`mysqls\` = -1, \`emails\` = -1, \`email_accounts\` = -1, \`email_forwarders\` = -1, \`email_quota\` = -1, \`ftps\` = -1, \`subdomains\` = -1, \`traffic\` = -1048576;" >> /tmp/froxlor-admin.sql
mysql -u${mysqluser} -p${mysqlpwd} ${mysqldb} < /tmp/froxlor-admin.sql
rm /tmp/froxlor-admin.sql

echo "Adding ip/port"
echo "TRUNCATE TABLE \`panel_ipsandports\`;" > /tmp/froxlor-ipport.sql

n=0
doit=1
while [ $doit != 0 ] 
do
  ip=$(jq -r '.froxlor.ipaddr'[$n] $JPARAM)
  if [ "$ip" == "null" ] 
  then
    doit=0
  else
    echo "add $ip."
    echo "INSERT INTO \`panel_ipsandports\` (\`ip\`, \`port\`, \`vhostcontainer\`, \`vhostcontainer_servername_statement\`) VALUES ('${ip}', 80, 1, 1);" >> /tmp/froxlor-ipport.sql
    echo "INSERT INTO \`panel_ipsandports\` (\`ip\`, \`port\`, \`vhostcontainer\`, \`vhostcontainer_servername_statement\`, \`ssl\`) VALUES ('${ip}', 443, 1, 1, 1);" >> /tmp/froxlor-ipport.sql
  fi
  n=$((n+1))
done  

mysql -u${mysqluser} -p${mysqlpwd} ${mysqldb} < /tmp/froxlor-ipport.sql
rm /tmp/froxlor-ipport.sql

echo "Adjusting settings"
echo "UPDATE \`panel_settings\` SET \`value\` = '${froxhost}' WHERE \`settinggroup\` = 'system' AND \`varname\` = 'hostname';" > /tmp/froxlor-settings.sql
echo "UPDATE \`panel_settings\` SET \`value\` = 'admin@${froxhost}' WHERE \`settinggroup\` = 'panel' AND \`varname\` = 'adminmail';" >> /tmp/froxlor-settings.sql
echo "UPDATE \`panel_settings\` SET \`value\` = '${froxip}' WHERE \`settinggroup\` = 'system' AND \`varname\` = 'ipaddress';" >> /tmp/froxlor-settings.sql
echo "UPDATE \`panel_settings\` SET \`value\` = '1' WHERE \`settinggroup\` = 'system' AND \`varname\` = 'defaultip';" >> /tmp/froxlor-settings.sql
echo "UPDATE \`panel_settings\` SET \`value\` = '2' WHERE \`settinggroup\` = 'system' AND \`varname\` = 'defaultsslip';" >> /tmp/froxlor-settings.sql
mysql -u${mysqluser} -p${mysqlpwd} ${mysqldb} < /tmp/froxlor-settings.sql
rm /tmp/froxlor-settings.sql

echo "Adjusting php-fpm versions"
phpv=`php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;'`
echo "UPDATE \`panel_fpmdaemons\` SET \`reload_cmd\` = 'service php${phpv}-fpm restart', \`config_dir\` = '/etc/php/${phpv}/fpm/pool.d/' WHERE \`id\` ='1';" > /tmp/froxlor-fpm.sql
mysql -u${mysqluser} -p${mysqlpwd} ${mysqldb} < /tmp/froxlor-fpm.sql
rm /tmp/froxlor-fpm.sql

echo "Creating user-config for froxlor"
echo "<?php" >/var/www/froxlor/lib/userdata.inc.php
echo "// automatically generated userdata.inc.php for Froxlor" >>/var/www/froxlor/lib/userdata.inc.php
echo "\$sql['host']='127.0.0.1';" >>/var/www/froxlor/lib/userdata.inc.php
echo "\$sql['user']='${mysqluser}';" >>/var/www/froxlor/lib/userdata.inc.php
echo "\$sql['password']='${mysqlpwd}';" >>/var/www/froxlor/lib/userdata.inc.php
echo "\$sql['db']='${mysqldb}';" >>/var/www/froxlor/lib/userdata.inc.php
echo "\$sql_root[0]['caption']='Default';" >>/var/www/froxlor/lib/userdata.inc.php
echo "\$sql_root[0]['host']='127.0.0.1';" >>/var/www/froxlor/lib/userdata.inc.php
echo "\$sql_root[0]['user']='froxroot';" >>/var/www/froxlor/lib/userdata.inc.php
echo "\$sql_root[0]['password']='${rootpasswd}';" >>/var/www/froxlor/lib/userdata.inc.php
echo "\$sql['debug'] = false;" >>/var/www/froxlor/lib/userdata.inc.php
echo "?>" >>/var/www/froxlor/lib/userdata.inc.php
chmod 0640 /var/www/froxlor/lib/userdata.inc.php

#
# froxlor services json for Debian 11 (Bullseye), including nginx, php-fpm, dovecot, postfix, proftp and required system-services such as libnss-extrausers,logrotate and cron
#
echo '{"distro":"bullseye","dns":"x","ftp":"proftpd","http":"nginx","mail":"dovecot_postfix2","smtp":"postfix_dovecot","system":["cron","libnssextrausers","logrotate","php-fpm"]}' >/tmp/froxlor_services.json

if [ -z "${froxsettingsexport}" ]; then
	echo "Running services configuration without importing settings"
	/usr/bin/php /var/www/froxlor/install/scripts/config-services.php --froxlor-dir=/var/www/froxlor/ --apply=/tmp/froxlor_services.json
else
	echo "Running services configuration with importing settings"
	/usr/bin/php /var/www/froxlor/install/scripts/config-services.php --froxlor-dir=/var/www/froxlor/ --import-settings=${froxsettingsexport} --apply=/tmp/froxlor_services.json
fi

export DEBIAN_FRONTEND=
export APT_CONFIG=
rm /tmp/_tmp_apt.conf
rm /tmp/froxlor_services.json

echo
echo "Froxlor completely installed and configured."
echo
