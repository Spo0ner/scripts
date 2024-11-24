#!/bin/bash
#Script by Spooner
#Changelog

# 0.1 - Initiale Version
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

  echo "Installiere MySQL Server..."
  apt install -y mysql-server

  echo "Sichere MySQL-Installation..."
  mysql_secure_installation <<EOF

y
root
root
y
y
y
y
EOF

  echo "Installiere phpMyAdmin..."
  DEBIAN_FRONTEND=noninteractive apt install -y phpmyadmin
}

install_redhat_based() {
  echo "Aktualisiere die Paketliste und installiere Updates..."
  yum update -y || dnf update -y

  echo "Installiere MariaDB Server..."
  yum install -y mariadb-server mariadb || dnf install -y mariadb-server mariadb

  echo "Starte und aktiviere MariaDB..."
  systemctl start mariadb
  systemctl enable mariadb

  echo "Installiere phpMyAdmin..."
  yum install -y epel-release || dnf install -y epel-release
  yum install -y phpmyadmin || dnf install -y phpmyadmin
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

echo "Starte und aktiviere den Datenbankdienst..."
systemctl start mysql || systemctl start mariadb
systemctl enable mysql || systemctl enable mariadb

echo "Installation abgeschlossen!"
echo "phpMyAdmin ist jetzt installiert und bereit. Konfiguriere deinen Webserver manuell."
