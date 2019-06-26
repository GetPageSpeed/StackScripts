# StackScripts
StackScripts ([Linode](https://www.getpagespeed.com/recommends/linode), etc.) for quick setup of servers

## base.sh

Get your server up and running with LEMP stack in no time-powered by:

* latest stable NGINX with Brotli and PageSpeed modules
* Percona MySQL 
* PHP-FPM. 

Features:
* SELinux protection
* Installs the bare minimum. No stuff that you don't need. Efficient without all the bloatware, so it's good for panel-less setup
* All-packaged install. All the packages are maintained in CDN powered RPM repository and you are always on the bleeding edge yet stable versions of NGINX and PageSpeed module with just `yum -y upgrade`.
* Build for stability. Configures extra swap space in order to prevent out of memory issue - an often oversight of many web server installs
* This StackScript is a good starting point for other LEMP based specific installations, e.g. a WP LEMP StackScript or a Magento LEMP StackScript
