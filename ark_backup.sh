#!/bin/bash
####
# ARK Backup Script v1.0 
# Created with ChatGPT-Support
# Description: Automated backup solution for ARK Survival Ascendend server.
# Handles FTP download, GZ file extraction, and 7z archiving.
# Do not modify this file unless you know what you're doing.
####

CONFIG_FILE="./ark_backup.conf"

# --------- Utility: Escape backslashes in paths ---------
escape_backslashes() {
    echo "$1" | sed 's|\\|\\\\|g'
}

# --------- Utility: Convert Windows paths to Linux-compatible (via WSL) ---------
convert_path() {
    local input=$(escape_backslashes "$1")
    local output=""
    if [[ "$input" =~ [A-Za-z]:\\ ]]; then
        if command -v wslpath >/dev/null 2>&1; then
            output=$(wslpath -a "$input")
        else
            echo "Error: Windows path detected but 'wslpath' not available."
            exit 1
        fi
    else
        output="$input"
    fi
    [[ "$output" != */ ]] && output="${output}/"
    echo "$output"
}

# --------- Load and validate configuration ---------
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Config file not found: $CONFIG_FILE"
    exit 1
fi
source "$CONFIG_FILE"

# --------- Normalize and ensure trailing slashes for paths ---------
BasePath=$(convert_path "$BasePath")
GZDir=$(convert_path "$GZDir")
ArchivePath=$(convert_path "$ArchivePath")

# --------- Generate timestamp for filenames ---------
RUN_DATE=$(date +"%Y-%m-%d_%H%M")

# --------- Determine if running in automated mode ---------
AUTOMATED_MODE=false
[[ "$1" == "automated" ]] && AUTOMATED_MODE=true

# --------- Ask for backup comment or set default ---------
if $AUTOMATED_MODE; then
    BACKUP_COMMENT="Automated Backup (DEFAULTDOWNLOAD=on servers)"
else
    BACKUP_COMMENT=$(whiptail --inputbox "Enter a backup comment (optional):" 10 60 "" --title "Backup Comment" 3>&1 1>&2 2>&3)
fi

# --------- Create and prepare log file ---------
LOGFILE="${ArchivePath}${RUN_DATE}.log"
mkdir -p "$ArchivePath"
echo "Backup started at $RUN_DATE" > "$LOGFILE"
[[ -n "$BACKUP_COMMENT" ]] && echo "Comment: $BACKUP_COMMENT" >> "$LOGFILE"
echo "" >> "$LOGFILE"

# --------- Build server selection menu from config ---------
declare -A SERVER_MAP
MENU_ITEMS=()
SELECTED_ITEMS=()
i=0
for entry in "${FTP_SERVER_LIST[@]}"; do
    IFS='|' read -r sid host user pass map note def <<< "$entry"
    map_display="$map"
    [[ -n "$note" ]] && map_display="$map_display ($note)"
    SERVER_MAP["$sid"]="$entry"
    MENU_ITEMS+=("$sid" "$map_display" "$def")
    ((i++))
done

if $AUTOMATED_MODE; then
    # Use only servers marked as default (DEFAULTDOWNLOAD=on)
    map_selection=$(for entry in "${FTP_SERVER_LIST[@]}"; do
        IFS='|' read -r sid _ _ _ _ _ def <<< "$entry"
        [[ "$def" == "on" ]] && echo "$sid"
    done)
else
    # --------- Show selection menu ---------
    map_selection=$(whiptail --title "Select Maps to Backup" \
        --checklist "Use space to select. Confirm with Enter." 20 78 10 \
        "${MENU_ITEMS[@]}" 3>&1 1>&2 2>&3)

    if [[ $? -ne 0 || -z "$map_selection" ]]; then
        echo "Backup cancelled by user."
        exit 0
    fi

    # --------- Normalize selection (remove quotes) ---------
    map_selection=$(echo "$map_selection" | sed 's/"//g')
fi

# --------- Process each selected map ---------
for sid in $map_selection; do
    IFS='|' read -r _ host user pass map note def <<< "${SERVER_MAP[$sid]}"
    shortmap="${map/_WP/}"
    idmap="${sid}_${shortmap}"

    echo "Selected: $sid -> $map ${note:+($note)}"
    echo "$sid: $map ${note:+($note)}" >> "$LOGFILE"

    # --------- FTP Download ---------

    # Parse host and port
    hostport="$host"
    host_only="${hostport%%:*}"
    port_only="${hostport##*:}"

    # Define download target directories
    map_short="${map%_WP}"
    target_savegames="${BasePath}${sid}_${map_short}/"
    target_savedarks="${BasePath}${sid}_${map_short}/SavedArks/"
    gz_target="${GZDir}${sid}_${map}/"

    # Clean previous download to avoid stale files
    echo "Cleaning target directory before backup..."
    rm -rf "$target_savegames" "$target_savedarks"
    
    # Create target folders
    mkdir -p "$target_savegames" "$target_savedarks" "$gz_target"

    echo "Downloading SaveGames..."
    if ! ncftpget -v -R -u "$user" -p "$pass" -P "$port_only" "$host_only" "$target_savegames" "${PathSG}/"; then
        echo "Error downloading SaveGames for $map. Skipping..." >> "$LOGFILE"
        continue
    fi

    echo "Downloading SaveArks..."
    if ! ncftpget -R -u "$user" -p "$pass" -P "$port_only" "$host_only" "$target_savedarks" "${PathSA}/${map}"; then
        echo "Error downloading SaveArks for $map. Skipping..." >> "$LOGFILE"
        continue
    fi

    echo "FTP download complete: $sid ($map)" >> "$LOGFILE"

    # --------- Move .gz files ---------
    echo "Moving .gz files..."
    find "$target_savedarks" -type f -name "*.gz" -exec mv {} "$gz_target" \;
    echo "Successfully moved .gz files to $gz_target"

    # --------- Create 7z Archive ---------
    archive_name="${RUN_DATE}_${sid}_${map_short}.7z"
    archive_path="${ArchivePath}${archive_name}"

    echo "Creating 7z archive for $sid ($map) ..."
    7z a -t7z "$archive_path" "${target_savegames}"*

    if [[ -f "$archive_path" ]]; then
        echo "7z archive created at $archive_path"
    else
        echo "ERROR: Failed to create 7z archive for $sid ($map)" >> "$LOGFILE"
    fi

done

# --------- Final log output ---------
echo -e "\nLog written to: $LOGFILE"
more "$LOGFILE"
