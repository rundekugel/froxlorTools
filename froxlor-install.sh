#!/bin/bash

echo try installing froxlor...

apt update
apt -y upgrade
apt -y remove apache2
apt -y install nginx screen mc git letsencrypt
apt -y install php php-fpm php-mysql php-xml php-mbstring php-gd php-curl php-bcmath php-zip php-ldap php-cgi
apt -y install mlocate
apt -y install mariadb-client mariadb-server
updatedb

#get keys
curl -sSLo /usr/share/keyrings/deb.froxlor.org-froxlor.gpg https://deb.froxlor.org/froxlor.gpg

#need lsb-release
apt-get -y install apt-transport-https lsb-release ca-certificates curl
echo release is: $(lsb_release -sc)

#add froxlor to apt-list
echo  "deb [signed-by=/usr/share/keyrings/deb.froxlor.org-froxlor.gpg] https://deb.froxlor.org/debian $(lsb_release -sc) main"  > /etc/apt/sources.list.d/froxlor.list

cp trusted.gpg deb.froxlor.org-froxlor.gpg
apt update
apt -y upgrade
apt -y install froxlor

echo secure database
/usr/bin/mysql_secure_installation

sed -i -e 's|root /var/www/html|root /var/www/froxlor|g' /etc/nginx/sites-enabled/default --follow-symlinks
sed -i -e 's/#location/location/g' /etc/nginx/sites-enabled/default --follow-symlinks
sed -i -e 's|#location ~ \\\.php|location ~ \\\.php|g' /etc/nginx/sites-enabled/default --follow-symlinks
sed -i -e 's|#\tinclude sni|\tinclude sni|g' /etc/nginx/sites-enabled/default --follow-symlinks
sed -i -e 's|#\tfastcgi_pass unix|\tfastcgi_pass unix|g' /etc/nginx/sites-enabled/default --follow-symlinks
sed -i -z -e 's|9000;\n\t#|9000;\n\t|g' /etc/nginx/sites-enabled/default --follow-symlinks
sed -i -E 's|(^\sindex )|\1index.php |g' /etc/nginx/sites-enabled/default --follow-symlinks
service nginx restart

# -------------------------------------------------
echo do manually:
echo "mariadb : SET PASSWORD FOR 'root'@'localhost' = PASSWORD('new_password');"
echo call http://<server-ip>/froxlor
exit 0
# -------------------------------------------------



