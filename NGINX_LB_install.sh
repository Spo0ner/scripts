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

  echo "Installiere NGINX..."
  apt install -y nginx
}

install_redhat_based() {
  echo "Aktualisiere die Paketliste und installiere Updates..."
  yum update -y || dnf update -y

  echo "Installiere NGINX..."
  yum install -y epel-release || dnf install -y epel-release
  yum install -y nginx || dnf install -y nginx
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

# Load-Balancer-Konfiguration
echo "Konfiguriere NGINX als Load-Balancer..."

cat > /etc/nginx/conf.d/loadbalancer.conf <<EOF
# NGINX Load Balancer Konfiguration
upstream backend {
    server 192.168.1.101; # Backend-Server 1
    server 192.168.1.102; # Backend-Server 2
}

server {
    listen 80;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

echo "Starte und aktiviere NGINX..."
systemctl restart nginx
systemctl enable nginx

echo "Installation abgeschlossen!"
echo "NGINX ist als Load-Balancer konfiguriert."

# Hinweisteil
echo
echo "*********************************** HINWEISE ***********************************"
echo "Die Hauptkonfigurationsdatei des Load-Balancers ist:"
echo "  /etc/nginx/conf.d/loadbalancer.conf"
echo
echo "Um die Backend-Server anzupassen, ändere die Datei:"
echo "  - Füge weitere 'server'-Einträge unter 'upstream backend' hinzu."
echo "  - Entferne nicht benötigte Server, falls erforderlich."
echo
echo "Nach Änderungen: Überprüfe die NGINX-Konfiguration mit:"
echo "  nginx -t"
echo
echo "Starte NGINX neu, um Änderungen zu übernehmen:"
echo "  systemctl restart nginx"
echo
echo "Falls HTTPS benötigt wird, bearbeite die Datei entsprechend, um SSL-Zertifikate"
echo "hinzuzufügen. Teile mit, falls du Unterstützung bei der HTTPS-Konfiguration benötigst!"
echo "*******************************************************************************"
