#!/bin/bash

#MIT License
#
#Copyright (c) 2022 gaul1-lifesim.de
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.


echo Try installing froxlor with nginx and all dependencies...
echo This script is copyrighted by gaul1-lifesim.de. 

#froxlor needs a user for php-fpm
useradd -r -G www-data customer1
usermod -G customer1 www-data 

apt update
apt -y upgrade
apt -y remove apache2
apt -y install nginx screen mc git letsencrypt
apt -y install php php-fpm php-mysql php-xml php-mbstring php-gd php-curl php-bcmath php-zip php-ldap php-cgi
apt -y install mlocate gnupg
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
echo add "ssl_certificate /etc/letsencrypt/live/{DOMAIN}/cert.pem;
        ssl_certificate_key /etc/letsencrypt/live/{DOMAIN}privkey.pem;
        "
echo to "Eigene SSL vHost-Einstellungen"        
exit 0
# -------------------------------------------------



