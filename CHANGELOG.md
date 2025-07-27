# Changelog

Alle nennenswerten Änderungen an diesem Projekt werden in dieser Datei dokumentiert.

## [2.0.0] - 2025-07-28

### Hinzugefügt
- Neues Markdown-Report-Script (`proxmox-report-md.sh`)
- HTML-Export Funktionalität mit pandoc
- CSS-Styling für HTML-Reports (`report.css`)
- Farbige Status-Anzeigen (Grün für Aktiv, Rot für Inaktiv)
- Formatierte Tabellen für bessere Lesbarkeit
- Status-Badges mit Unicode-Symbolen
- Automatische Berechnung von Prozentsätzen
- Verbesserte Service-Namen Darstellung

### Geändert
- Erweiterte README mit neuen Installationsoptionen
- Bessere Strukturierung der Ausgabe
- Optimierte Datenerfassung

## [1.0.0] - 2025-07-28

### Hinzugefügt
- Initiale Version des Proxmox System Report Generators
- Vollständige System- und Netzwerkinformationen
- VM und Container Auflistung mit Konfigurationsdetails
- Storage-Übersicht (ZFS, LVM, etc.)
- Hardware-Informationen (CPU, RAM, Festplatten)
- Service-Status Überprüfung
- Systemauslastung (Load Average, CPU, RAM)
- README mit Installationsanleitung
- MIT Lizenz