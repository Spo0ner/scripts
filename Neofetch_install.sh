#!/bin/bash
# by Spooner 2024
# Beachte, dass vor dem Ausführen folgendes unternommen werden muss:
# chmod +x Neofetch_install.sh
# Support für Debian/Ubuntu/CentOS/Fedora, Arch-basierte Linux-Distributionen und macOS (mit Homebrew)



#changelog

#Version 1.0
# Initial Version
#Version 1.1
#macOS-Kompatibilität hinzugefügt: Die Prüfung auf Homebrew (brew) wurde in die Funktion install_neofetch eingebaut.
#Wenn Homebrew gefunden wird, wird Neofetch über brew install neofetch installiert.


# Neofetch installieren
install_neofetch() {
    echo "Starte die Installation von Neofetch..."

    # Prüfen, ob Neofetch bereits installiert ist
    if command -v neofetch &> /dev/null; then
        echo "Neofetch ist bereits installiert."
        return
    fi

    # Neofetch installieren
    if [ -x "$(command -v apt-get)" ]; then
        # Debian/Ubuntu-basiert
        sudo apt-get update
        sudo apt-get install -y neofetch
    elif [ -x "$(command -v yum)" ]; then
        # RHEL/CentOS-basiert
        sudo yum install -y epel-release
        sudo yum install -y neofetch
    elif [ -x "$(command -v dnf)" ]; then
        # Fedora-basiert
        sudo dnf install -y neofetch
    elif [ -x "$(command -v pacman)" ]; then
        # Arch-basiert
        sudo pacman -Syu --noconfirm neofetch
    elif [ -x "$(command -v brew)" ]; then
        # macOS mit Homebrew
        echo "Homebrew erkannt. Neofetch wird installiert..."
        brew install neofetch
    else
        echo "Unbekanntes Paketmanagement-System. Bitte installiere Neofetch manuell."
        return
    fi

    echo "Neofetch wurde erfolgreich installiert."
}

# Neofetch beim Start der Shell ausführen
configure_shell() {
    echo "Konfiguriere die Shell, um Neofetch bei jedem Start auszuführen..."

    # Bestimme die aktuelle Shell-Konfigurationsdatei
    SHELL_PROFILE=""
    if [ -n "$BASH_VERSION" ]; then
        SHELL_PROFILE="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        SHELL_PROFILE="$HOME/.zshrc"
    else
        echo "Unbekannte Shell. Bitte füge manuell 'neofetch' in die Konfigurationsdatei ein."
        return
    fi

    # Prüfen, ob Neofetch bereits in der Konfigurationsdatei steht
    if grep -q "neofetch" "$SHELL_PROFILE"; then
        echo "Neofetch ist bereits in der Konfigurationsdatei vorhanden."
    else
        # Neofetch am Ende der Konfigurationsdatei hinzufügen
        echo "neofetch" >> "$SHELL_PROFILE"
        echo "Neofetch wurde zur Shell-Konfigurationsdatei hinzugefügt."
    fi
}

# Hauptfunktion
main() {
    install_neofetch
    configure_shell
    echo "Installation und Konfiguration abgeschlossen."
}

# Skript ausführen
main
