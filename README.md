# Proxmox System Report Generator

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Proxmox VE](https://img.shields.io/badge/Proxmox%20VE-8.x-orange)](https://www.proxmox.com/)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green)](https://www.gnu.org/software/bash/)

Ein umfassendes Bash-Script zur Erstellung detaillierter Systemreports für Proxmox VE Server.

## 🚀 Features

- **Systeminformationen**: Hostname, OS-Version, Kernel, Uptime
- **Netzwerk**: Interfaces, IP-Adressen, Routing, offene Ports
- **Proxmox-Details**: Node-Informationen, Cluster-Status
- **Virtuelle Maschinen**: Auflistung aller VMs mit Konfiguration
- **Container**: Auflistung aller LXC Container mit Details
- **Storage**: Übersicht aller Storage-Pools (ZFS, LVM, etc.)
- **Hardware**: CPU, RAM, Festplatten
- **Services**: Status wichtiger Proxmox-Dienste
- **Systemauslastung**: CPU, RAM, Load Average

## 📋 Voraussetzungen

- Proxmox VE 7.x oder 8.x
- Root-Zugriff auf dem Proxmox Host
- Bash Shell

## 🔧 Installation

### Option 1: Direkter Download

```bash
# Script herunterladen
wget https://raw.githubusercontent.com/sambila/proxmox-system-report/main/proxmox-report.sh

# Ausführbar machen
chmod +x proxmox-report.sh
```

### Option 2: Git Clone

```bash
# Repository klonen
git clone https://github.com/sambila/proxmox-system-report.git
cd proxmox-system-report

# Script ausführbar machen
chmod +x proxmox-report.sh
```

### Option 3: Installation im System

```bash
# Script nach /usr/local/bin kopieren
sudo cp proxmox-report.sh /usr/local/bin/proxmox-report
sudo chmod +x /usr/local/bin/proxmox-report
```

## 📖 Verwendung

### Einfache Ausführung

```bash
# Im aktuellen Verzeichnis
./proxmox-report.sh

# Oder wenn systemweit installiert
proxmox-report
```

### Automatisierte Reports (Cron)

```bash
# Crontab bearbeiten
crontab -e

# Täglicher Report um 2 Uhr nachts
0 2 * * * /usr/local/bin/proxmox-report > /dev/null 2>&1

# Wöchentlicher Report jeden Montag
0 3 * * 1 /usr/local/bin/proxmox-report > /dev/null 2>&1
```

### Report an anderen Ort speichern

```bash
# Script modifizieren oder wrapper erstellen
#!/bin/bash
REPORT_DIR="/var/log/proxmox-reports"
mkdir -p "$REPORT_DIR"
cd "$REPORT_DIR"
/usr/local/bin/proxmox-report
```

## 📄 Report-Inhalt

Der generierte Report enthält folgende Abschnitte:

1. **Hostname und Systeminformationen**
   - Hostname und FQDN
   - Betriebssystem-Details
   - Kernel-Version
   - System-Uptime

2. **Netzwerkkonfiguration**
   - Alle Netzwerkschnittstellen
   - IP-Adressen
   - Routing-Tabelle
   - Offene Ports und Dienste

3. **Proxmox-Informationen**
   - Installierte Proxmox-Pakete
   - Cluster-Status
   - Node-Konfiguration

4. **Virtuelle Umgebungen**
   - Liste aller VMs (QEMU/KVM)
   - Liste aller Container (LXC)
   - Netzwerkkonfiguration pro VM/CT

5. **Storage**
   - Storage-Pool-Übersicht
   - ZFS Pools
   - LVM Volumes

6. **Zusätzliche Informationen**
   - CPU-Details
   - Speicherauslastung
   - Festplattenübersicht
   - Systemlast
   - Service-Status

## 🔍 Beispiel-Output

```
==== Hostname und Systeminformationen ====

Hostname: pve-node01
FQDN: pve-node01.example.com
Betriebssystem:
PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"
NAME="Debian GNU/Linux"
VERSION="12 (bookworm)"
ID=debian
Kernel: 6.8.12-12-pve
Uptime: up 15 days, 3 hours, 42 minutes

==== Virtuelle Maschinen (QEMU/KVM) ====

      VMID NAME                 STATUS     MEM(MB)    BOOTDISK(GB) PID
       100 webserver            running    4096              50.00 12345
       101 database             running    8192             100.00 12346
```

## 🛠️ Anpassungen

Das Script kann einfach angepasst werden:

### Report-Dateiname ändern

```bash
# In Zeile 7 des Scripts
REPORT_FILE="custom_report_$(date +%Y%m%d).txt"
```

### Zusätzliche Informationen hinzufügen

```bash
# Neue Sektion hinzufügen
print_section "Backup-Status"
vzdump list >> "$REPORT_FILE"
```

## 🤝 Beitragen

Contributions sind willkommen! Bitte:

1. Fork das Repository
2. Erstelle einen Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Committe deine Änderungen (`git commit -m 'Add some AmazingFeature'`)
4. Push zum Branch (`git push origin feature/AmazingFeature`)
5. Öffne einen Pull Request

## 📝 Lizenz

Dieses Projekt ist unter der MIT Lizenz lizenziert - siehe [LICENSE](LICENSE) Datei für Details.

## 🙏 Danksagung

- Proxmox Team für die großartige Virtualisierungsplattform
- Community für Feedback und Verbesserungsvorschläge

## 📮 Kontakt

- GitHub: [@sambila](https://github.com/sambila)

## ⚠️ Haftungsausschluss

Dieses Script wird "as is" ohne jegliche Garantie bereitgestellt. Verwenden Sie es auf eigene Gefahr.