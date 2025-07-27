#!/bin/bash
# Proxmox System Report Generator
# Version: 1.0.0
# Author: github.com/sambila
# License: MIT

# === Konfiguration ===
REPORT_FILE="proxmox_report_$(hostname)_$(date +%Y%m%d_%H%M%S).txt"

# === Hilfsfunktionen ===
print_section() {
  echo -e "\n==== $1 ====\n" >> "$REPORT_FILE"
}

# === Report-Erstellung ===
# 1. Hostname und Systeminfo
print_section "Hostname und Systeminformationen"
{
  echo "Hostname: $(hostname)"
  echo "FQDN: $(hostname -f)"
  echo "Betriebssystem:"
  cat /etc/os-release 2>/dev/null | grep -E "^(PRETTY_NAME|NAME|VERSION|ID)="
  echo "Kernel: $(uname -r)"
  echo "Uptime: $(uptime -p)"
} >> "$REPORT_FILE"

# 2. Netzwerkschnittstellen und IP-Adressen
print_section "Netzwerkschnittstellen und IP-Adressen"
ip -brief address >> "$REPORT_FILE"

# 3. Routing-Tabelle
print_section "Routing-Tabelle"
ip route show >> "$REPORT_FILE"

# 4. Offene Ports und zugehörige Dienste
print_section "Offene Ports und Dienste (ss)"
ss -tulpn 2>/dev/null | grep LISTEN >> "$REPORT_FILE"

# 5. Proxmox-Cluster- und Node-Informationen
print_section "Proxmox Node-Informationen"
pveversion -v >> "$REPORT_FILE"

print_section "Proxmox Cluster-Status"
pvecm status 2>/dev/null || echo "Kein Cluster konfiguriert" >> "$REPORT_FILE"

# 6. VMs und Container (IDs, Namen, IPs)
print_section "Virtuelle Maschinen (QEMU/KVM)"
qm list >> "$REPORT_FILE"

for VMID in $(qm list | awk 'NR>1 {print $1}'); do
  print_section "VM $VMID Konfiguration"
  qm config "$VMID" | grep -E '^(name|net[0-9]|boot|memory|cores|sockets):' >> "$REPORT_FILE"
done

print_section "Container (LXC)"
pct list >> "$REPORT_FILE"

for CTID in $(pct list | awk 'NR>1 {print $1}'); do
  print_section "CT $CTID Konfiguration"
  pct config "$CTID" | grep -E '^(hostname|net[0-9]|memory|cores|rootfs):' >> "$REPORT_FILE"
done

# 7. Storage-Informationen
print_section "Storage-Informationen"
pvesm status >> "$REPORT_FILE"

print_section "ZFS Pools"
zpool list 2>/dev/null >> "$REPORT_FILE" || echo "Keine ZFS Pools gefunden" >> "$REPORT_FILE"

print_section "LVM Volumes"
lvs 2>/dev/null >> "$REPORT_FILE" || echo "Keine LVM Volumes gefunden" >> "$REPORT_FILE"

# 8. Firewall-Status
print_section "Firewall-Status"
pve-firewall status 2>/dev/null >> "$REPORT_FILE" || echo "Firewall nicht konfiguriert" >> "$REPORT_FILE"

# 9. Hosts-Datei
print_section "/etc/hosts"
cat /etc/hosts >> "$REPORT_FILE"

# 10. Zusätzliche Informationen
print_section "CPU Informationen"
lscpu | grep -E "^(Model name|CPU\(s\)|Thread|Core|Socket):" >> "$REPORT_FILE"

print_section "Speicher Informationen"
free -h >> "$REPORT_FILE"

print_section "Festplatten Übersicht"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT >> "$REPORT_FILE"

print_section "Systemauslastung"
{
  echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
  echo "CPU Auslastung:"
  top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/CPU: \1% idle/"
  echo "Speicherauslastung:"
  free | awk 'NR==2{printf "RAM: %.2f%% verwendet\n", $3*100/$2 }'
} >> "$REPORT_FILE"

print_section "Proxmox Services Status"
for service in pve-cluster pvedaemon pveproxy pvestatd; do
  systemctl is-active $service &>/dev/null && status="AKTIV" || status="INAKTIV"
  echo "$service: $status" >> "$REPORT_FILE"
done

# === Abschluss ===
echo -e "\nReport wurde erstellt: $REPORT_FILE"
echo "Dateigröße: $(du -h $REPORT_FILE | cut -f1)"