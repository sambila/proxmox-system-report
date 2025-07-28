#!/bin/bash
# Proxmox System Report Generator - Markdown Edition
# Version: 2.1.0
# Author: github.com/sambila
# License: MIT

# === Konfiguration ===
REPORT_FILE="proxmox_report_$(hostname)_$(date +%Y%m%d_%H%M%S).md"

# Farben für Terminal-Ausgabe
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# === Hilfsfunktionen ===
print_header() {
  echo -e "\n## $1\n" >> "$REPORT_FILE"
}

print_subheader() {
  echo -e "\n### $1\n" >> "$REPORT_FILE"
}

# Funktion zum Berechnen von Prozentsätzen
calc_percentage() {
  if [ "$2" -eq 0 ]; then
    echo "0"
  else
    echo "scale=2; $1 * 100 / $2" | bc
  fi
}

# Status Badge erstellen
create_badge() {
  local status=$1
  if [ "$status" = "running" ] || [ "$status" = "AKTIV" ]; then
    echo '<span style="color: #22c55e;">✓ Läuft</span>'
  elif [ "$status" = "stopped" ] || [ "$status" = "INAKTIV" ]; then
    echo '<span style="color: #ef4444;">✗ Gestoppt</span>'
  else
    echo '<span style="color: #f59e0b;">⚡ '"$status"'</span>'
  fi
}

# Zeitstempel formatieren
format_date() {
  local timestamp=$1
  date -d "@$timestamp" "+%d.%m.%Y %H:%M" 2>/dev/null || echo "$timestamp"
}

# === Report-Header ===
{
  echo "# Proxmox Server Status Report - $(hostname | tr '[:lower:]' '[:upper:]')"
  echo ""
  echo "**Datum:** $(date '+%d. %B %Y')"
  echo "**Server:** $(hostname -f)"
  echo ""
} > "$REPORT_FILE"

# === Systemübersicht ===
print_header "Systemübersicht"
{
  echo "| Eigenschaft | Wert |"
  echo "|------------|------|"
  
  # OS Info
  os_name=$(grep "PRETTY_NAME" /etc/os-release 2>/dev/null | cut -d'"' -f2)
  echo "| Betriebssystem | $os_name |"
  
  # Proxmox Version
  pve_version=$(pveversion -v | grep "proxmox-ve:" | awk '{print $2}')
  echo "| Proxmox Version | $pve_version |"
  
  # Kernel
  echo "| Kernel | $(uname -r) |"
  
  # Uptime
  uptime_info=$(uptime -p | sed 's/up //')
  echo "| Laufzeit | $uptime_info |"
  
  # Main IP
  main_ip=$(ip -4 addr show vmbr0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
  echo "| IP-Adresse | $main_ip |"
  
  # CPU Info
  cpu_model=$(lscpu | grep "Model name:" | sed 's/Model name: *//')
  cpu_count=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
  echo "| Prozessor | $cpu_model ($cpu_count Kerne) |"
  echo ""
} >> "$REPORT_FILE"

# === Ressourcenauslastung ===
print_header "Ressourcenauslastung"

# RAM Info
print_subheader "Arbeitsspeicher"
{
  mem_total=$(free -b | awk 'NR==2{print $2}')
  mem_used=$(free -b | awk 'NR==2{print $3}')
  mem_available=$(free -b | awk 'NR==2{print $7}')
  mem_percent=$(calc_percentage $mem_used $mem_total)
  
  echo "- **Gesamt:** $(numfmt --to=iec-i --suffix=B $mem_total | sed 's/iB/B/')"
  echo "- **Verwendet:** $(numfmt --to=iec-i --suffix=B $mem_used | sed 's/iB/B/') ($mem_percent%)"
  echo "- **Verfügbar:** $(numfmt --to=iec-i --suffix=B $mem_available | sed 's/iB/B/')"
  echo ""
} >> "$REPORT_FILE"

# System Load
print_subheader "Systemlast"
{
  load_avg=$(uptime | awk -F'load average:' '{print $2}')
  cpu_idle=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/")
  cpu_used=$(echo "scale=1; 100 - $cpu_idle" | bc)
  
  echo "- **CPU-Auslastung:** $cpu_used% ($cpu_idle% idle)"
  echo "- **Load Average:**$load_avg"
  echo ""
} >> "$REPORT_FILE"

# === VMs ===
if qm list | grep -q "running\|stopped"; then
  print_header "Virtuelle Maschinen"
  
  # VM Details
  for VMID in $(qm list | awk 'NR>1 {print $1}'); do
    vm_name=$(qm config "$VMID" | grep "^name:" | cut -d' ' -f2)
    vm_status=$(qm list | grep "^[[:space:]]*$VMID" | awk '{print $3}')
    vm_mem=$(qm config "$VMID" | grep "^memory:" | cut -d' ' -f2)
    vm_cores=$(qm config "$VMID" | grep "^cores:" | cut -d' ' -f2)
    vm_sockets=$(qm config "$VMID" | grep "^sockets:" | cut -d' ' -f2 || echo "1")
    total_cores=$((vm_cores * vm_sockets))
    
    # Disk size
    boot_disk=$(qm config "$VMID" | grep "^scsi0:\|^virtio0:\|^ide0:" | head -1 | grep -oP 'size=\K[0-9]+[GMK]' || echo "N/A")
    
    echo "### $vm_name (ID: $VMID)"
    echo "- **Status:** $(create_badge $vm_status)"
    echo "- **RAM:** $(echo $vm_mem | sed 's/[0-9]*/& MB/' | sed 's/ MB/ GB/' | awk '{print $1/1024 " GB"}')"
    echo "- **CPU:** $total_cores Kerne"
    if [ "$vm_cores" != "$total_cores" ]; then
      echo "  - $vm_cores Kerne × $vm_sockets Sockets"
    fi
    echo "- **Festplatte:** $boot_disk"
    echo "- **Netzwerk:** Bridge vmbr0"
    echo ""
  done >> "$REPORT_FILE"
fi

# === Container ===
if pct list | grep -q "running\|stopped"; then
  print_header "Container"
  
  echo "| Name | ID | Status | RAM | CPU | Festplatte | IP-Adresse |" >> "$REPORT_FILE"
  echo "|------|-----|--------|-----|-----|------------|------------|" >> "$REPORT_FILE"
  
  for CTID in $(pct list | awk 'NR>1 {print $1}'); do
    ct_status=$(pct list | grep "^$CTID" | awk '{print $2}')
    ct_name=$(pct config "$CTID" | grep "^hostname:" | cut -d' ' -f2)
    ct_mem=$(pct config "$CTID" | grep "^memory:" | cut -d' ' -f2)
    ct_cores=$(pct config "$CTID" | grep "^cores:" | cut -d' ' -f2)
    ct_rootfs=$(pct config "$CTID" | grep "^rootfs:" | grep -oP 'size=\K[0-9]+[GMK]')
    
    # IP Address
    ct_ip=$(pct config "$CTID" | grep "^net0:" | grep -oP 'ip=\K[^,]+' || echo "N/A")
    if [ "$ct_ip" = "dhcp" ]; then
      ct_ip="DHCP"
    else
      ct_ip=$(echo $ct_ip | cut -d'/' -f1)
    fi
    
    # Status badge
    if [ "$ct_status" = "running" ]; then
      status_badge="✓ Läuft"
    else
      status_badge="✗ Gestoppt"
    fi
    
    echo "| $ct_name | $CTID | $status_badge | $(echo $ct_mem | awk '{print $1/1024}') GB | $ct_cores | $ct_rootfs | $ct_ip |"
  done >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
fi

# === Backup Status ===
print_header "Backup-Status"

# Backup Jobs
print_subheader "Geplante Backup-Jobs"
if [ -f /etc/pve/vzdump.cron ]; then
  echo "| Zeitplan | Typ | Ziel | VMs/Container |" >> "$REPORT_FILE"
  echo "|----------|-----|------|---------------|" >> "$REPORT_FILE"
  
  while IFS= read -r line; do
    # Skip comments and empty lines
    if [[ ! "$line" =~ ^# ]] && [[ -n "$line" ]]; then
      # Parse cron line
      schedule=$(echo "$line" | awk '{print $1" "$2" "$3" "$4" "$5}')
      vzdump_cmd=$(echo "$line" | cut -d' ' -f6-)
      
      # Extract storage
      storage=$(echo "$vzdump_cmd" | grep -oP 'storage=\K[^ ]+' || echo "local")
      
      # Extract mode
      mode="Snapshot"
      if echo "$vzdump_cmd" | grep -q "mode=stop"; then
        mode="Stop"
      elif echo "$vzdump_cmd" | grep -q "mode=suspend"; then
        mode="Suspend"
      fi
      
      # Extract VMs/CTs
      vmids=$(echo "$vzdump_cmd" | grep -oE '[0-9]+' | tail -n +2 | tr '\n' ',' | sed 's/,$//')
      if [ -z "$vmids" ]; then
        vmids="Alle"
      fi
      
      # Convert schedule to readable format
      case "$schedule" in
        "0 2 * * *") readable_schedule="Täglich 02:00" ;;
        "0 3 * * 0") readable_schedule="Sonntags 03:00" ;;
        "0 1 * * 1-5") readable_schedule="Mo-Fr 01:00" ;;
        *) readable_schedule="$schedule" ;;
      esac
      
      echo "| $readable_schedule | $mode | $storage | $vmids |"
    fi
  done < /etc/pve/vzdump.cron >> "$REPORT_FILE"
else
  echo "Keine geplanten Backup-Jobs konfiguriert." >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Recent Backups
print_subheader "Letzte Backups"
{
  # Find backup files in common locations
  backup_found=false
  echo "| VM/CT | Typ | Datum | Größe | Speicherort |" >> "$REPORT_FILE"
  echo "|-------|-----|-------|-------|-------------|" >> "$REPORT_FILE"
  
  # Check all storage locations for backup files
  for storage in $(pvesm status | awk 'NR>1 && $2 ~ /dir|nfs|cifs/ {print $1}'); do
    storage_path=$(pvesm path $storage:backup 2>/dev/null | cut -d: -f2 | sed 's|/backup||')
    if [ -d "$storage_path/dump" ]; then
      # Find recent backup files (last 10)
      find "$storage_path/dump" -name "vzdump-*.vma*" -o -name "vzdump-*.tar*" 2>/dev/null | \
      sort -r | head -10 | while read backup_file; do
        backup_found=true
        filename=$(basename "$backup_file")
        
        # Parse filename
        if [[ "$filename" =~ vzdump-(qemu|lxc)-([0-9]+)-([0-9]{4}_[0-9]{2}_[0-9]{2}-[0-9]{2}_[0-9]{2}_[0-9]{2}) ]]; then
          vm_type="${BASH_REMATCH[1]}"
          vm_id="${BASH_REMATCH[2]}"
          backup_date="${BASH_REMATCH[3]}"
          
          # Convert type
          if [ "$vm_type" = "qemu" ]; then
            vm_type="VM"
          else
            vm_type="CT"
          fi
          
          # Get VM/CT name
          if [ "$vm_type" = "VM" ]; then
            vm_name=$(qm config "$vm_id" 2>/dev/null | grep "^name:" | cut -d' ' -f2 || echo "ID-$vm_id")
          else
            vm_name=$(pct config "$vm_id" 2>/dev/null | grep "^hostname:" | cut -d' ' -f2 || echo "ID-$vm_id")
          fi
          
          # Format date
          formatted_date=$(echo "$backup_date" | sed 's/_/ /;s/-/:/g;s/ /-/')
          
          # Get file size
          file_size=$(du -h "$backup_file" | cut -f1)
          
          echo "| $vm_name | $vm_type | $formatted_date | $file_size | $storage |"
        fi
      done
    fi
  done
  
  if [ "$backup_found" = false ]; then
    echo "| Keine aktuellen Backups gefunden | - | - | - | - |" >> "$REPORT_FILE"
  fi
} >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Backup Storage Usage
print_subheader "Backup-Speicher"
{
  echo "| Speicher | Gesamt | Belegt | Frei | Auslastung |" >> "$REPORT_FILE"
  echo "|----------|--------|--------|------|------------|" >> "$REPORT_FILE"
  
  for storage in $(pvesm status | awk 'NR>1 {print $1}'); do
    # Check if storage is used for backups
    content=$(pvesm status | grep "^$storage" | awk '{print $3}')
    if [[ "$content" =~ "backup" ]] || pvesm path $storage:backup >/dev/null 2>&1; then
      storage_info=$(pvesm status | grep "^$storage")
      total=$(echo "$storage_info" | awk '{print $4}')
      used=$(echo "$storage_info" | awk '{print $5}')
      avail=$(echo "$storage_info" | awk '{print $6}')
      percent=$(echo "$storage_info" | awk '{print $7}')
      
      # Convert to GB
      total_gb=$(echo "scale=1; $total / 1024 / 1024" | bc)
      used_gb=$(echo "scale=1; $used / 1024 / 1024" | bc)
      avail_gb=$(echo "scale=1; $avail / 1024 / 1024" | bc)
      
      echo "| $storage | ${total_gb} GB | ${used_gb} GB | ${avail_gb} GB | $percent |"
    fi
  done
} >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# === Storage ===
print_header "Speicher"

# ZFS Pools
if command -v zpool >/dev/null 2>&1 && zpool list >/dev/null 2>&1; then
  print_subheader "ZFS Pools"
  
  while IFS= read -r line; do
    if [[ ! "$line" =~ ^NAME ]]; then
      pool_name=$(echo "$line" | awk '{print $1}')
      pool_size=$(echo "$line" | awk '{print $2}')
      pool_alloc=$(echo "$line" | awk '{print $3}')
      pool_free=$(echo "$line" | awk '{print $4}')
      pool_cap=$(echo "$line" | awk '{print $8}' | sed 's/%//')
      
      echo "**$pool_name**"
      echo "- **Kapazität:** $pool_size"
      echo "- **Belegt:** $pool_alloc ($pool_cap%)"
      echo "- **Frei:** $pool_free"
      echo ""
    fi
  done < <(zpool list 2>/dev/null)
fi >> "$REPORT_FILE"

# Storage Overview
print_subheader "Speicher-Übersicht"
{
  pvesm status | awk 'NR>1 {
    printf "**%s** (%s)\n", $1, $2
    total_gb = $4 / 1024 / 1024
    used_gb = $5 / 1024 / 1024
    printf "- Gesamt: %.1f GB\n", total_gb
    printf "- Belegt: %.1f GB (%.1f%%)\n", used_gb, $7
    printf "- Frei: %.1f GB\n\n", total_gb - used_gb
  }'
} >> "$REPORT_FILE"

# === Festplatten ===
print_header "Festplatten"
echo "| Gerät | Größe | Verwendung |" >> "$REPORT_FILE"
echo "|-------|-------|------------|" >> "$REPORT_FILE"
{
  lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep "^[a-z]" | grep "disk" | while read line; do
    disk=$(echo "$line" | awk '{print $1}')
    size=$(echo "$line" | awk '{print $2}')
    
    # Bestimme Verwendung
    if mount | grep -q "^/dev/$disk"; then
      usage="System"
    elif zpool status 2>/dev/null | grep -q "$disk"; then
      usage="ZFS Pool"
    elif pvs 2>/dev/null | grep -q "$disk"; then
      usage="LVM"
    elif [ -n "$(lsblk -o MOUNTPOINT -n /dev/$disk 2>/dev/null | grep -v '^$')" ]; then
      usage="Zusatzspeicher"
    else
      usage="Nicht verwendet"
    fi
    
    echo "| $disk | $size | $usage |"
  done
} >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# === Netzwerkdienste ===
print_header "Netzwerkdienste"
echo "| Port | Dienst |" >> "$REPORT_FILE"
echo "|------|---------|" >> "$REPORT_FILE"
{
  # Definiere bekannte Ports
  declare -A known_ports=(
    ["22"]="SSH (Fernzugriff)"
    ["223"]="SSH (Fernzugriff)"
    ["8006"]="Proxmox Web-Interface"
    ["3128"]="Spice Proxy"
    ["111"]="RPC"
    ["25"]="E-Mail (lokal)"
    ["85"]="PVE Daemon (lokal)"
  )
  
  ss -tlpn 2>/dev/null | grep LISTEN | while read line; do
    port=$(echo "$line" | awk '{print $4}' | rev | cut -d: -f1 | rev)
    if [[ -n "${known_ports[$port]}" ]]; then
      echo "| $port | ${known_ports[$port]} |"
    fi
  done | sort -u
} >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# === Systemdienste ===
print_header "Systemdienste"
echo "| Dienst | Status |" >> "$REPORT_FILE"
echo "|--------|--------|" >> "$REPORT_FILE"
{
  for service in pve-cluster pvedaemon pveproxy pvestatd; do
    if systemctl is-active $service &>/dev/null; then
      echo "| $(echo $service | sed 's/pve/Proxmox /;s/daemon/ Daemon/;s/proxy/ Proxy/;s/statd/ Statistik/') | <span style=\"color: #22c55e;\">✓ Aktiv</span> |"
    else
      echo "| $(echo $service | sed 's/pve/Proxmox /;s/daemon/ Daemon/;s/proxy/ Proxy/;s/statd/ Statistik/') | <span style=\"color: #ef4444;\">✗ Inaktiv</span> |"
    fi
  done
  
  # Firewall Status
  fw_status=$(pve-firewall status 2>/dev/null | grep -oP 'Status: \K.*' || echo "unknown")
  if [[ "$fw_status" =~ "running" ]]; then
    echo "| Firewall | <span style=\"color: #22c55e;\">✓ Läuft</span> |"
  else
    echo "| Firewall | <span style=\"color: #ef4444;\">✗ Gestoppt</span> |"
  fi
} >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# === Cluster Status ===
print_header "Cluster-Status"
if pvecm status >/dev/null 2>&1; then
  cluster_name=$(pvecm status | grep "^Cluster name:" | cut -d: -f2 | xargs)
  echo "**Cluster Name:** $cluster_name" >> "$REPORT_FILE"
else
  echo "Einzelner Server (kein Cluster konfiguriert)" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# === Abschluss ===
echo -e "${GREEN}✓${NC} Report wurde erstellt: ${BLUE}$REPORT_FILE${NC}"
echo -e "Dateigröße: $(du -h $REPORT_FILE | cut -f1)"

# Optional: Konvertierung zu HTML
if command -v pandoc >/dev/null 2>&1; then
  HTML_FILE="${REPORT_FILE%.md}.html"
  pandoc -f markdown -t html --css=report.css "$REPORT_FILE" -o "$HTML_FILE" 2>/dev/null && \
  echo -e "${GREEN}✓${NC} HTML-Version erstellt: ${BLUE}$HTML_FILE${NC}"
fi