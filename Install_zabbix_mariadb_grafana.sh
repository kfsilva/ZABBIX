#!/bin/bash

# Version: 1.0
# Date of create: 12/07/2017
# Create by: Kelvyn Ferreira
# Description: Script for installation Zabbix-Server, MariaDB and Grafna-Server (CentOS/RHEL/Fedora)

############# Chanding ##########
#
# Data of last change: 13/07/2017
# Changer by: Kelvyn Ferreira


# Variables
DIR_ROOT="/root"
HTTP_ZBX_FILE="/etc/httpd/conf.d/zabbix.conf"
HTTP_INDEX_ZBX="/var/www/html"
ZBX_SERVER_FILE="/etc/zabbix/zabbix_server.conf"
ZBX_AGENT_FILE="/etc/zabbix/zabbix_agentd.conf"
ZBX_CONF_PHP="/etc/zabbix/web/zabbix.conf.php"
SECURITY_FILE="/etc/sysconfig/selinux"
GRAFANA_CONF="/etc/grafana/grafana.ini"
FQDN=$( ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/' )


# Functions
update-system()
{

		echo " "
		echo "########## Update Operational System... ##########"
		echo " "

			# Update System
			yum -t -y -e 0 update

		echo " "
		echo "########## Done! ##########"
		echo " "

}

install_other_packets()
{
		echo "########## Install Repo EPEL... ##########"
		echo " "

			# Install repo Epen
			yum -t -y -e 0 install epel-release

			# Clean libs repo
			yum clean all

		echo " "
		echo "########## Done! ##########"
		echo " "

		echo "########## Install other packeges... ##########"
		echo " "

			# Install others packages necessary of system
			yum -t -y -e 0 install vim net-tools nc htop glances wget yum-utils unzip net-snmp-utils ntp net-snmp telnet iotop traceroute bind-utils
	
		echo " "
		echo "########## Done! ##########"
		echo " "

}

open_ports_firewalld()
{

		echo "########## Releasing access to ports on the firewalld ##########"
		echo " "

		echo "########## Enable ports 80 and 443 ##########"
		echo " "

			# Enable access port http and https
			firewall-cmd --permanent --add-port=80/tcp
			firewall-cmd --permanent --add-port=443/tcp
		
		echo " "
		echo "########## Enable port 10051 ##########"
		echo " "

			# Enable access port Zabbix Server
			firewall-cmd --permanent --add-port=10051/tcp
		
		echo " "
		echo "########## Enable port 3306 ##########"
		echo " "

			# Enable access port MariaDB
			firewall-cmd --permanent --add-port=3306/tcp 

		echo " "
		echo "########## Enable port 162 ##########"
		echo " "

			# Enable access port SNMP
			firewall-cmd --permanent --add-port=162/tcp 

		echo " "
		echo "########## Reload Service firewall-cmd... ##########"
		echo " "

			# Restart service firewalld
			firewall-cmd --reload

		echo " "
		echo "########## Check ports enable in firewalld ##########" 
		echo " "

			# Check ports enable
			firewall-cmd --list-ports

		echo " "
		echo "########## Done! ##########"
		echo " "

}

change_security_files()
{
		echo "########## Alter Mode Operation Selinux... ##########"
		echo " "
		echo "########## Check Mode Selinux... ##########"

			# Check status selinux
			getenforce

		echo " "

			# Alter mode Selinux config
			sed -i "s/SELINUX=enforcing/SELINUX=permissive/g" $SECURITY_FILE

		echo "########## Alter Mode Selinux... ##########"
		echo " "

			# Alter status Selinux Enforcing > Permissive
			setenforce 0

		echo " "
		echo "########## Done! ##########"
		echo " "

}

install_apache()
{
	
		echo " "
		echo "######### Install Apache Server #########"
		echo " "

			# Install Apache and Apache Tools
			yum -t -y -e 0 install httpd httpd-tools

		echo " "
		echo "######### Done! #########"
		echo " "

}

install_sgbd()
{
	
		echo "########## Install MariaDB (MySQL)... ##########"
		echo " "

			# Install MariaDB and MariaDB-Server
			yum -t -y -e 0 install mariadb mariadb-server mytop

		echo " "
		echo "########## Done! ##########"
		echo " "

		echo "########## Starting Service MariaDB... ##########"
		echo " "

			# Starting Service MariaDB
			systemctl start mariadb

			# Enable Starting Automatic Service MariaDB
			systemctl enable mariadb

		echo " "
		echo "########## Done! ##########"
		echo " "

}

config_access_sgbd()
{

		echo " "
		echo "########## Configuration Access MariaDB... ##########"
		echo " "

		# Reciver password user root for access localhost
		echo -n "Enter with password for user root local MySQL: " 
				read "_passwdrootmysqllocal"

		# Reciver password user root for access external
		echo -n "Enter with password for user root external MySQL: " 
				read "_passwdrootmysqlext"

		# Reciver password user zabbix for access localhost
		echo -n "Enter with password for user zabbix MySQL: " 
				read "_passwdzabbixmysql"

		echo " "
		echo "########### Seting new password for user Root and Zabbix in MySQL... ###########"
		echo ""

		echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '"$_passwdrootmysqllocal"';"
		echo " "

			# Seting new password root localhost
			mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '"$_passwdrootmysqllocal"';"

			# Flush privileges database
			mysql --password=$_passwdrootmysqllocal -e "FLUSH PRIVILEGES;"

		echo " "
		echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '"$_passwdrootmysqlext"';"
		echo " "

			# Seting new password root external
			mysql --password=$_passwdrootmysqllocal -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '"$_passwdrootmysqlext"';"
		
			# Flush privileges database
			mysql --password=$_passwdrootmysqllocal -e "FLUSH PRIVILEGES;"

		echo "########## Create Database Zabbix... ##########"
		echo " "

		echo " "
		echo "CREATE DATABASE zabbix CHARACTER SET utf8 COLLATE utf8_bin;"
		echo " "

			# Create Database Zabbix 
			mysql --password=$_passwdrootmysqllocal -e "CREATE DATABASE zabbix CHARACTER SET utf8 COLLATE utf8_bin;"

		echo " "
		echo "########## Check Databases... ##########"
		echo " "

			# Check Databases in MySQL
			mysql --password=$_passwdrootmysqllocal -e "SHOW DATABASES;"

			sleep 3

		echo " "
		echo "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost' IDENTIFIED BY '"$_passwdzabbixmysql"';"
		echo " "	

			# Seting password zabbix user
			mysql --password=$_passwdrootmysqllocal -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost' IDENTIFIED BY '"$_passwdzabbixmysql"';"
			
			# Flush privileges database
			mysql --password=$_passwdrootmysqllocal -e "FLUSH PRIVILEGES;"

		echo "########## Create file "#DIR_ROOT"/.my.cnf ##########"
		echo " "

		# Create File .my.cnf
		echo "[client]
host='localhost'
user='root'
password='"$_passwdrootmysqllocal"'" > $DIR_ROOT/.my.cnf

		echo " "
		echo "########## Password access for MySQL... ##########"
		echo " "

			echo "Access for MySQL - Zabbix Server"
			echo " "

			echo "Password for root localhost: "$_passwdrootmysqllocal""
			echo " "
			echo "Password for root external: "$_passwdrootmysqlext""
			echo " "
			echo "Password for zabbix localhost: "$_passwdzabbixmysql""

			sleep 7

		echo "########## Done! ##########"
		echo " "

}

install_zabbix_server()
{


		echo "########## Install Zabbix-Server... ##########"
		echo " "

			# Import Zabbix Repo
			rpm -ivh http://repo.zabbix.com/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm

		echo " "			

			# Install MariaDB and MariaDB-Server
			yum -t -y -e 0 install zabbix-server-mysql zabbix-web-mysql zabbix-java-gateway zabbix-get zabbix-agent zabbix-sender

		echo " "
		echo "########## Done! ##########"
		echo " "

}

import_zabbix_sql()
{

		echo "########## Create Database Struct for zabbix Database... ##########"
		echo " "

			# Create struct database zabbix
			zcat -v /usr/share/doc/zabbix-server-mysql-*/create.sql.gz | mysql --password=$_passwdrootmysqllocal zabbix

		echo " "			
		echo "########## Check Tables in zabbix Database... ########## "
		echo " "

		echo "USER zabbix and SHOW TABLES"
		echo " "

			# Check tables zabbix database
			mysql --password=$_passwdrootmysqllocal -e "USE zabbix;SHOW TABLES;"

			sleep 5

		echo " "
		echo "########## Done! ##########"
		echo " "

}

config_zabbix_file()
{

		echo "########## Seting TimeZone Zabbix-Server in "$HTTP_ZBX_FILE"... ##########"
		echo " "

			# Seting TimeZone Zabbix-Server
			sed -i "s/# php_value date.timezone Europe\/Riga/php_value date.timezone America\/Sao_paulo/g" $HTTP_ZBX_FILE
		
		echo " "
		echo "########## Done! ##########"
		echo " "

 		echo " "			
		echo "########## Seting parameters in Zabbix-Agent file "$ZBX_AGENT_FILE"... ##########"
		echo " "

			# Enable Remote Commands
			sed -i "s/# EnableRemoteCommands=0/EnableRemoteCommands=1/g" $ZBX_AGENT_FILE

			# Enable Logs Remote Commands
			sed -i "s/# LogRemoteCommands=0/LogRemoteCommands=1/g" $ZBX_AGENT_FILE

			# Seting hostname Zabbix
			sed -i "s/Hostname=Zabbix server/# Hostname=Zabbix server/g" $ZBX_AGENT_FILE

			# Seting hostname system
			sed -i "s/# HostnameItem=system.hostname/HostnameItem=system.hostname/g" $ZBX_AGENT_FILE

		echo " "
		echo "########## Done! ##########"
		echo " "

 		echo " "			
		echo "########## Seting parameters in Zabbix-Server file "$ZBX_SERVER_FILE"... ##########"
		echo " "

			# Seting password for zabbix user
			sed -i "s/# DBPassword=/DBPassword="$_passwdzabbixmysql"/g" $ZBX_SERVER_FILE

		echo " "
		echo "########## Done! ##########"
		echo " "

}

set_zabbix_name()
{

		echo "########## Seting Name for Zabbix-Server... ##########"
		echo " "

		# Seting Name for Zabbix-Server
		echo -n "Enter with name of Zabbix-Server: "
				read "zbxservername"

		echo "<?php
// Zabbix GUI configuration file.
global \$DB;

\$DB['TYPE']     = 'MYSQL';
\$DB['SERVER']   = '127.0.0.1';
\$DB['PORT']     = '0';
\$DB['DATABASE'] = 'zabbix';
\$DB['USER']     = 'zabbix';
\$DB['PASSWORD'] = '"$_passwdzabbixmysql"';
			  
// Schema name. Used for IBM DB2 and PostgreSQL.
\$DB['SCHEMA'] = '';
			  
\$ZBX_SERVER      = 'localhost';
\$ZBX_SERVER_PORT = '10051';
\$ZBX_SERVER_NAME = '"$zbxservername"';
			  
\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;" > $ZBX_CONF_PHP

		echo " "
		echo "########## Done! ##########"
		echo " "


		echo " "
		echo "########## Create file index.php for Zabbix redirect... ##########"
		echo " "

		echo "<?php header ( "Location: http://$FQDN/zabbix" );?> > $HTTP_INDEX_ZBX/index.php"
		echo " "

		# Create file index.php for redirect /zabbix
		echo "<?php header ( \"Location: http://$FQDN/zabbix\" );?>" > $HTTP_INDEX_ZBX/index.php

		echo "########## Warning in case of external publishing on the Zabbix server change the index.php file by adding the DNS instead of the IP !!! ##########"
		echo " "
		echo "########## The index.php file is located in "$HTTP_INDEX_ZBX"/index.php ##########"
			
		echo " "
		echo "########## Done! ##########"
		echo " "
}

install_grafana_server()
{
    
		echo "########## Install Grafana-Server... ##########"
		echo " "

			# Clean libs repo
			yum clean all

			# Packets necessarys
			yum -t -y -e 0 install fontconfig urw-fonts freetype*

			# Install grafana-server
			yum -t -y -e 0 install https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-4.4.1-1.x86_64.rpm
			
		echo " "
		echo "########## Done! ##########"
		echo " "

		echo "########## Install Plugins Grafana-Server... ##########"
			
			# Install plugins Grafana
			grafana-cli plugins install alexanderzobnin-zabbix-app 
			grafana-cli plugins install grafana-clock-panel 
			grafana-cli plugins install grafana-piechart-panel 
			grafana-cli plugins install jdbranham-diagram-panel 
			grafana-cli plugins install vonage-status-panel
		
		echo " "
		echo "########## Enable port 3000 ##########"
		echo " "

			# Enable access port Grafana-Server
			firewall-cmd --permanent --add-port=3000/tcp 

		echo " "
		echo "########## Done! ##########"
		echo " "

		
		echo "########## Reload Service firewall-cmd... ##########"
		echo " "

			# Restart service firewalld
			firewall-cmd --reload

		echo " "
		echo "########## Disable sign users in "$GRAFANA_CONF"... ##########"
		echo " "

			# Disable sign users Grafana-Server
			sed -i "s/;allow_sign_up = true/allow_sign_up = false/g" $GRAFANA_CONF

		echo " "
		echo "########## Done! ##########"
		echo " "

		echo "########## Staring Grafana-Server... ##########"				
		echo " "

			# Start service Grafana-Server
			systemctl start grafana-server
			
			# Enable starting boot Grafana-Server
			systemctl enable grafana-server

		echo " "
		echo "########## Done! ##########"
		echo " "

		echo "######### Check Status of Grafana-Server... #########"
		echo " "

			# Check status service Grafana-Server
			systemctl status grafana-server -ll

		echo " "
		echo "########## Done! ##########"

}

start_services()
{

		echo "######### Start Apache Server... #########"
		echo " "

			# Start service Apache
			systemctl start httpd

		echo " " 
		echo "######### Configuration auto start service on apache... #########"
		echo " "

			# Enable start service Apache on boot 
			systemctl enable httpd

		echo " "
		echo "########## Done! ##########"
		echo " "

		echo "######### Check Status of Apache Server... #########"

			# Check status service Apache 
			systemctl status httpd -ll

		echo " "
		echo "########## Done! ##########"
		echo " "

		echo "######### Start Zabbix Server... #########"
		echo " "

			# Start service Zabbix-Sever
			systemctl start zabbix-server

		echo " " 
		echo "######### Configuration auto start service on Zabbix-Server... #########"
		echo " "

			# Enable service Zabbix-Server on boot
			systemctl enable zabbix-server

		echo " "
		echo "########## Done! ##########"
		echo " "

		echo "######### Check Status of Zabbix Server... #########"
		echo " "  

			# Check status Zabbix-Server
			systemctl status zabbix-server -ll

		echo " "
		echo "########## Done! ##########"
		echo " "

		echo "######### Start Zabbix Agent... #########"
		echo " "

			# Start service Zabbix-Agent
			systemctl start zabbix-agent

		echo " " 
		echo "######### Configuration auto start service on Zabbix-Agent... #########"
		echo " "

			# Enable service Zabbix-Agent on boot
			systemctl enable zabbix-agent

		echo " "
		echo "######### Check Status of Zabbix Agent... #########"
		echo " "

			# Check status service Zabbix-Agent
			systemctl status zabbix-agent -ll

		echo " "
		echo "########## Done! ##########"
		echo " "

}

confirm() 
{
    # call with a prompt string or use a default
    read -r -p "${1:-Do you want to install Grafana-Server? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true

           	update-system
			install_other_packets
			open_ports_firewalld
			change_security_files
			install_apache
			install_sgbd
			config_access_sgbd
			install_zabbix_server
			import_zabbix_sql
			config_zabbix_file
			set_zabbix_name
			install_grafana_server
			start_services
            
            echo ""
            echo "Grafana-Server Installed with success !!!"
			echo " "
			echo "Acces Grafana-Server Web: http://$FQDN:3000/"
			echo " "
			echo "Zabbix Server Installed with success !!!"
			echo " "
			echo "Acces Zabbix-Server Web: http://$FQDN/zabbix"

            ;;
        
        *)

			update-system
			install_other_packets
			open_ports_firewalld
			change_security_files
			install_apache
			install_sgbd
			config_access_sgbd
			install_zabbix_server
			import_zabbix_sql
			config_zabbix_file
			set_zabbix_name
			start_services

			echo " "
			echo "Zabbix Server Installed with success !!!"
			echo " "
			echo "Acces Zabbix-Server Web: http://$FQDN"

        	false
            ;;

    esac

}


main()
{

	confirm

}

# Call main
main
