#!/bin/bash

#Script by Spooner
#Changelog

# 0.1 - Initiale Version
# 0.2 - Dynamische IP am ende der Installation
# 0.3 - Prüft vor der Installation welches Betriebsystem installiert (Support für Ubuntu / Debian basierend und RedHat basierend)



# Sicherstellen, dass das Skript als root ausgeführt wird
if [ "$EUID" -ne 0 ]; then
  echo "Bitte führe das Skript als root aus (sudo)."
  exit 1
fi

# Distribution erkennen
if [ -f /etc/os-release ]; then
  source /etc/os-release
  DISTRO=$ID
else
  echo "Konnte die Linux-Distribution nicht erkennen."
  exit 1
fi

echo "Erkannte Distribution: $DISTRO"

# Funktionen für die Installation basierend auf der Distribution
install_debian_based() {
  echo "Aktualisiere die Paketliste und installiere Updates..."
  apt update && apt upgrade -y

  echo "Installiere Apache..."
  apt install -y apache2

  echo "Installiere PHP und notwendige Module..."
  apt install -y php libapache2-mod-php php-mysql php-cli php-curl php-zip php-gd php-mbstring

  echo "Installiere MySQL Server..."
  apt install -y mysql-server

  echo "Installiere phpMyAdmin..."
  DEBIAN_FRONTEND=noninteractive apt install -y phpmyadmin
}

install_redhat_based() {
  echo "Aktualisiere die Paketliste und installiere Updates..."
  yum update -y || dnf update -y

  echo "Installiere Apache (httpd)..."
  yum install -y httpd || dnf install -y httpd

  echo "Installiere PHP und notwendige Module..."
  yum install -y php php-mysqlnd php-cli php-common php-gd php-mbstring || dnf install -y php php-mysqlnd php-cli php-common php-gd php-mbstring

  echo "Installiere MariaDB Server..."
  yum install -y mariadb-server mariadb || dnf install -y mariadb-server mariadb

  echo "Installiere phpMyAdmin..."
  yum install -y epel-release || dnf install -y epel-release
  yum install -y phpmyadmin || dnf install -y phpmyadmin

  echo "Konfiguriere SELinux (falls aktiv)..."
  if command -v setenforce &> /dev/null && [ "$(getenforce)" = "Enforcing" ]; then
    setenforce 0
    sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
  fi
}

# Installation basierend auf der Distribution
case $DISTRO in
  ubuntu|debian)
    install_debian_based
    ;;
  centos|fedora|rhel)
    install_redhat_based
    ;;
  *)
    echo "Diese Distribution wird nicht unterstützt."
    exit 1
    ;;
esac

# Starte und aktiviere Dienste
echo "Starte und aktiviere Apache..."
if [ "$DISTRO" = "centos" ] || [ "$DISTRO" = "fedora" ] || [ "$DISTRO" = "rhel" ]; then
  systemctl start httpd
  systemctl enable httpd
else
  systemctl start apache2
  systemctl enable apache2
fi

echo "Starte und aktiviere MySQL/MariaDB..."
systemctl start mysql || systemctl start mariadb
systemctl enable mysql || systemctl enable mariadb

# Apache-Konfiguration für phpMyAdmin
if [ "$DISTRO" = "ubuntu" ] || [ "$DISTRO" = "debian" ]; then
  echo "Konfiguriere Apache für phpMyAdmin..."
  ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
elif [ "$DISTRO" = "centos" ] || [ "$DISTRO" = "fedora" ] || [ "$DISTRO" = "rhel" ]; then
  echo "Konfiguriere Apache für phpMyAdmin..."
  ln -s /usr/share/phpMyAdmin /var/www/html/phpmyadmin
fi

echo "Aktiviere Apache-Module und lade die Konfiguration neu..."
a2enmod rewrite 2>/dev/null || echo "Rewrite-Modul aktivieren für Red Hat-basierte Distributionen ist manuell erforderlich."
systemctl restart apache2 || systemctl restart httpd

# IP-Adresse dynamisch ermitteln
IP=$(hostname -I | awk '{print $1}')

echo "Installation abgeschlossen!"
echo "Der Webserver ist jetzt erreichbar unter: http://$IP"
echo "phpMyAdmin ist erreichbar unter: http://$IP/phpmyadmin"
