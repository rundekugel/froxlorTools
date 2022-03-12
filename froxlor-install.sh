
echo try installing froxlor...
apt update
apt -y upgrade
apt remove apache2
apt -y install nginx php php-fpm php-mysql php-xml php-mbstring php-mbstring php-gd php-curl php-bcmath php-zip php-ldap mlocate
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
apt install froxlor

exit 0

mysql_secure_installation
service nginx restart
apt install mariadb-client
apt install php-7.4
apt install mariadb
apt install mariadb-server
/usr/bin/mysql_secure_installation

cat /usr/share/keyrings/deb.froxlor.org-froxlor.gpg 
wget -O - https://deb.froxlor.org/froxlor.gpg | apt-key add -
apt-get update && apt-get upgrade
apt install froxlor
ll
cat trusted.gpg
ll
cat sources.list
ll
cat trusted.gpg.d/debian-archive-buster-stable.gpg 
wget -O - https://deb.froxlor.org/froxlor.gpg
mc
screen
cat pws/froxlor.txt 
su gaul1
service nginx restart
cd /etc/nginx/
ll
cd sites-enabled/
ll
ln -s ../sites-available/froxlor.conf 
service nginx restart
mc
ll
ll html/
ll froxlor/
service apache2 restart
service nginx restart
service nginx status
service nginx test
nginx test
nginx -test
nginx 
nginx  -t
service nginx restart
netstat -pltn | grep 9000
netstat -la
netstat -ltu
netstat -ltun
systemctl list-unit-files | grep fpm
systemctl -l | grep -i fpm
systemctl -l 
apt install php7-3-fpm
apt install php7.3-fpm
curl localhost
curl f.localhost
curl f.localhost/robots.txt
curl f.localhost:robots.txt
curl f.localhost/
curl f.localhost/robots.txt
ll
curl f.localhost/phpcs.xml
cat >test.html
curl f.localhost/test
curl f.localhost/test.html
cat >test.html
cat test.html 
cat >test.html
cat test.html 
curl f.localhost/test.html
service nginx restart
curl f.localhost/test.html
ll
chown www-data:www-data
chown www-data:www-data test.html 
ll
cat test.html 
curl f.localhost/test.html
curl localhost/test.html
curl localhost
service nginx restart
less /etc/nginx/nginx.conf 
less /etc/nginx/fastcgi_params 
less /etc/init.d/php-fcgi 
php /var/www/froxlor//install/scripts/config-services.php --froxlor-dir=/var/www/froxlor/ --create
ll ..
ll ../html/
curl localhost
cat ../html/index.html 
ifconfig
screen
ls
service nginx restart
apt install fpm
apt install php-fpm
apt install php7.3-fpm
ps -Aa
less /etc/init.d/php-fcgi 
systemctl restart php7.3-fpm
ll
