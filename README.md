# 🧬 ARK: Survival Ascended – FTP Backup Script

Ein Bash-Script zur automatisierten Sicherung von **ARK: Survival Ascended** Spielständen (z. B. von Nitrado gehosteten Servern).  
Das Script lädt SaveGames und SaveArks via FTP herunter, legt `.gz`-Dateien separat ab und erstellt ein komprimiertes `.7z`-Archiv.

## Hinweis
- Das Skript funktioniert derzeit nur mit FTP/FTPS. Wenn du SFTP oder SCP verwenden möchtest, musst du die entsprechenden Tools wie lftp oder scp verwenden. Wenn sich tester für scp/sftp finden, kann ich mich da gerne drum kümmern.
- Das Skript wurde auf WSL v2 (Windows Subsystem for Linux) getestet.
---

## ⚙️ Voraussetzungen

- **WSL 2** (Windows Subsystem for Linux) oder ein natives **Linux-System**
- Bash-kompatible Umgebung
- Die folgenden Tools müssen installiert sein:

### 🛠️ Installation unter Ubuntu / Debian:

```bash
sudo apt update
sudo apt install p7zip-full ncftp whiptail
```

💡 **Hinweis:** Wer eine andere Distribution nutzt, kennt üblicherweise den passenden Paketmanager.

---

## 📁 Konfiguration (`ark_backup.conf`)

Die Konfiguration erfolgt in der Datei `ark_backup.conf`.  
Hier werden die lokalen Zielpfade und die Serverinformationen für den FTP-Zugriff definiert.

### 🔧 Wichtige Pfade:

```bash
BasePath="c:\GameServer\Maps"        # Temporäres Zielverzeichnis für Spielstände
GZDir="c:\GameServer\GZip"           # Hier landen .gz-Dateien vom Server
ArchivePath="c:\GameServer\Archive"  # Speicherort für .7z-Backups + Logfiles
```

📌 **Hinweis zu Pfadangaben:**
- **Windows**: `C:\Pfad\zum\Ordner`
- **Linux**: `/mnt/c/Pfad/zum/Ordner/`
- Pfade werden automatisch ins Linux-Format konvertiert – ein `/` am Ende ist erlaubt.

---

### 🌐 FTP-Server-Liste

Format der `FTP_SERVER_LIST` in der `ark_backup.conf`:

```bash
FTP_SERVER_LIST=(
  "01|ftp.nitrado.net:21|myuser|mypw|TheIsland_WP||on"
  "02|ftp.nitrado.net:21|myuser|mypw|ScorchedEarth_WP|Cluster A|off"
  "03|ftp.nitrado.net:21|myuser|mypw|TheIsland_WP|Cluster B|on"
)
```

#### Felder:

| Feld         | Bedeutung |
|--------------|-----------|
| `ID`         | Interne Kennung → wird für Dateinamen & Verzeichnisse verwendet (**einmal gesetzt, nicht mehr ändern!**) |
| `HOST:PORT`  | FTP-Adresse und Port |
| `USERNAME`   | FTP-Benutzername |
| `PASSWORD`   | FTP-Passwort |
| `MAPNAME`    | Map-Name wie auf dem Server (z. B. `TheIsland_WP`) (**einmal gesetzt, nicht mehr ändern!**) |
| `MAPNOTE`    | (Optional) Zusatzinfo z. B. für Cluster |
| `DEFAULT`    | `on` → wird bei automatisiertem Lauf mitgesichert |

---

## ▶️ Ablauf des Scripts

### Manuell starten:

```bash
./ark_backup.sh
```

1. Auswahlmenü für zu sichernde Maps (via `whiptail`)
2. Optional: Eingabe eines Kommentars
3. Ablauf pro Map:
   - Vorherige Spielstände im Zielordner werden gelöscht
   - SaveGames und SaveArks werden per FTP heruntergeladen
   - `.gz`-Dateien werden separat ins `GZDir` verschoben
   - Ein `.7z`-Archiv wird erstellt
   - Alle Schritte werden in ein Logfile geschrieben
4. ❗ Das heruntergeladene SaveGame bleibt erhalten – es wird erst beim nächsten Durchlauf gelöscht.

---

### Automatisiert starten (z. B. via Cron):

```bash
./ark_backup.sh automated
```

- Keine Benutzereingaben
- Es werden alle Maps mit `DEFAULT=on` automatisch gesichert
- Logfile enthält den Hinweis: `"Automated Backup (DEFAULT=on servers)"`

---

## 🗃️ Ergebnis

Nach dem Backup findest du:

- 🧩 `.gz`-Dateien im `GZDir`  
  z. B. `GZip/001_TheIsland_WP/`
- 📦 `.7z`-Archiv im `ArchivePath`  
  z. B. `Archive/2025-05-06_001_TheIsland.7z`
- 📄 Logfile mit Ablaufprotokoll  
  z. B. `Archive/2025-05-06_001_TheIsland.log`

---

## 💡 Optional & ToDo

- sftp/scp-Integration

---

## ❓ Häufige Hinweise

- **ID** und **MAPNAME** dürfen nachträglich nicht geändert werden, da sie in Ordner- und Dateinamen verwendet werden!
- Bei Problemen mit `wslpath`: Stelle sicher, dass WSL 2 korrekt installiert ist.
- `whiptail` wird für die Benutzerinteraktion benötigt – alternativ ließe sich `dialog` einbauen.

---

Viel Spaß mit dem Script – Backups retten Leben 😉
