# Beispiel Report Output

Dies ist ein Beispiel für den generierten Report:

```
==== Hostname und Systeminformationen ====

Hostname: pve
FQDN: pve.local
Betriebssystem:
PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"
NAME="Debian GNU/Linux"
VERSION_ID="12"
VERSION="12 (bookworm)"
ID=debian
Kernel: 6.8.12-12-pve
Uptime: up 5 days, 12 hours, 34 minutes

==== Netzwerkschnittstellen und IP-Adressen ====

lo               UNKNOWN        127.0.0.1/8 ::1/128
vmbr0            UP             192.168.1.100/24 fe80::1234:5678:90ab:cdef/64

==== Virtuelle Maschinen (QEMU/KVM) ====

      VMID NAME                 STATUS     MEM(MB)    BOOTDISK(GB) PID
       100 ubuntu-server        running    2048              20.00 5678
       101 windows-10           stopped    4096              50.00

==== Container (LXC) ====

VMID       Status     Lock         Name
200        running                 nginx-proxy
201        running                 pihole

==== Storage-Informationen ====

Name             Type     Status           Total            Used       Available        %
local             dir     active        100000000        50000000        50000000   50.00%
local-lvm     lvmthin     active        200000000        80000000       120000000   40.00%
```