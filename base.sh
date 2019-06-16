#!/bin/bash
# TODO: UDS stack as seen here https://www.getpagespeed.com/server-setup/faster-web-server-stack-powered-by-unix-sockets-proxy (separate stackscript)
# this one is only NGINX with good modules + PHP-FPM
# This block defines the variables the user of the script needs to input
# when deploying using this script.
#
#
#<UDF name="fqdn" label="The new Linode's Fully Qualified Domain Name">
# FQDN=

# This sets the variable $IPADDR to the IP address the new Linode receives.
IPADDR=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')

# This updates the packages on the system from the distribution repositories.
yum -y upgrade

# This section sets the hostname.
hostnamectl set-hostname $FQDN
# This section sets the Fully Qualified Domain Name (FQDN) in the hosts file.
# TODO: hostname = first component of FQDN
echo $IPADDR $FQDN >> /etc/hosts

# Best practice is using UTC timezone and overwriding as needed 
timedatectl set-timezone UTC

echo "Configuring SWAP space x1 the RAM"
fallocate -l ${LINODE_RAM}M /var/swap
chmod 600 /var/swap
mkswap /var/swap
swapon /var/swap
echo "/var/swap    none    swap    sw    0    0" >> /etc/fstab
yum -y install https://extras.getpagespeed.com/release-el$(rpm -E %{rhel})-latest.rpm \
  https://repo.percona.com/yum/percona-release-latest.noarch.rpm \
  https://rpms.remirepo.net/enterprise/remi-release-7.rpm \
  yum-utils
yum-config-manager --enable remi-php73
# Percona SELinux package mentioned there: https://www.percona.com/doc/percona-server/5.6/installation/yum_repo.html
yum -y install \
  nginx nginx-module-nps nginx-module-nbr \
  php-fpm php-cli php-json php-opcache php-mysqlnd php-soap php-gd php-pecl-imagick php-mbstring \
  php-pecl-apcu php-xml php-tidy php-pecl-memcached php-ioncube-loader \
  Percona-Server-server-56 Percona-Server-client-56 mysqltuner \
  pwgen
  
# start MySQLd now so we can set it up
systemctl start mysql

# mysql_secure_installation alternative:
MYSQL_PASS=$(pwgen --secure)
mysqladmin -u root password ${MYSQL_PASS}
declare -a tools=("mysqladmin" "mysql" "mysqlcheck" "mysqldump")
for tool in "${tools[@]}"; do
  printf "[$tool]\npassword = ${MYSQL_PASS}\nuser = root\n\n" >> ~/.my.cnf
done
chmod 0600 ~/.my.cnf
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
mysql -e "DELETE FROM mysql.user WHERE User=''"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
mysqladmin flush-privileges

# enable at boot time our services:
systemctl enable nginx php-fpm mysql
# start them now:
systemctl start nginx php-fpm mysql
# open up Firewall a little bit:
firewall-cmd --zone=public --change-interface=eth0
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload
