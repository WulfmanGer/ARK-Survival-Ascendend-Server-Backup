# 🧬 ARK: Survival Ascended – FTP Backup Script

A Bash script for automating backups of **ARK: Survival Ascended** game saves (e.g., from Nitrado-hosted servers).  
The script downloads SaveGames and SaveArks via FTP, stores `.gz` files separately, and creates a compressed `.7z` archive.

## Note
- The script currently works only with FTP/FTPS. If you want to use SFTP or SCP, you will need to use corresponding tools like `lftp` or `scp`. If testers for SFTP/SCP are available, I can help with the implementation.
- The script has been tested on **WSL v2** (Windows Subsystem for Linux).
---

## ⚙️ Requirements

- **WSL 2** (Windows Subsystem for Linux) or a native **Linux system**
- A bash-compatible environment
- The following tools must be installed:

### 🛠️ Installation on Ubuntu / Debian:

```bash
sudo apt update
sudo apt install p7zip-full ncftp whiptail

```

💡 **Note:** If you're using a different distribution, you likely know the appropriate package manager.

---

## 📁 Configuration  (`ark_backup.conf`)

Configuration is done in the `ark_backup.conf` file.
Here, local target paths and FTP access server information are defined.

### 🔧 Wichtige Pfade:

```bash
BasePath="c:\GameServer\Maps"        # Temporary target directory for game saves
GZDir="c:\GameServer\GZip"           # Directory for .gz files from the server
ArchivePath="c:\GameServer\Archive"  # Location for .7z backups + log files
```

📌 **Note on Path Notation:**
- **Windows**: `C:\Path\to\folder`
- **Linux**: `/mnt/c/Path/to/folder/`
- Paths are automatically converted to Linux format – a trailing `/` is allowed.

---

### 🌐 FTP Server List

The format of `FTP_SERVER_LIST` in `ark_backup.conf`:

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
| `ID`         | Internal identifier → used for file names & directories  (**once set, do not change!**) |
| `HOST:PORT`  | FTP-Adresse und Port |
| `USERNAME`   | FTP-Benutzername |
| `PASSWORD`   | FTP-Passwort |
| `MAPNAME`    | Map name as it appears on the server (e.g. `TheIsland_WP`) (**once set, do not change!**) |
| `MAPNOTE`    | (Optional) Additional info, e.g., for clusters
| `DEFAULT`    | `on` → Automatically backed up when run in automated mode, off → no backup in automated mode

---

## ▶️ Script Workflow

### Manually Start:

```bash
./ark_backup.sh
```

1. A map selection menu appears (via `whiptail`)
2. Optionally enter a comment for the backup
3. For each selected map:
   - Previous game saves in the target folder are deleted
   - SaveGames and SaveArks are downloaded via FTP
   - `.gz` files are moved to the `GZDir`
   - A `.7z`archive is created
   - All steps are logged in a logfile
4. ❗ The downloaded save game remains in the folder – it will only be deleted on the next script run.

---

### Start Automatically (e.g., via Cron):

```bash
./ark_backup.sh automated
```

- No user input required
- All maps with  `DEFAULT=on` will be automatically backed up
- The logfile will contain the note: `"Automated Backup (DEFAULT=on servers)"`

---

## 🗃️ Output

After the backup, you will find:

- 🧩 `.gz` files in the im `GZDir`  
  e.g., `GZip/001_TheIsland_WP/`
- 📦 `.7z`archive in the  `ArchivePath`  
  e.g., `Archive/2025-05-06_01_TheIsland.7z`
- 📄 Logfile with the process log  
  e.g., `Archive/2025-05-06_01_TheIsland.log`

---

## 💡 Optional & ToDo

- sftp/scp Integration

---

## ❓ Frequently Asked Notes

- **ID** and **MAPNAME** should not be changed after initial setup, as they are used in folder and file names!
- If you have issues with `wslpath`: Make sure WSL 2 is correctly installed.
- `whiptail` is required for user interaction – alternatively, `dialog` could be used.

---
Enjoy using the script – Backups save lives 😉
