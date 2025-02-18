#!/bin/bash

# Configuration
HOME_DIR="/home/$(logname)"
BACKUP_DIR="${HOME_DIR}/dbackup"
BACKUP_ARCHIVE_DIR="${BACKUP_DIR}/backup"
LOG_DIR="/var/log/dbackup"
LOG_FILE="${LOG_DIR}/backup.log"
CONFIG_FILE="/etc/dbackup/config"

# Create required directories
mkdir -p "$BACKUP_DIR" "$BACKUP_ARCHIVE_DIR" "$LOG_DIR"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Database backup function
do_backup() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        if [ ! -z "$DB_NAME" ] && [ ! -z "$TABLE_NAME" ]; then
            backup_file="${BACKUP_DIR}/${DB_NAME}_${TABLE_NAME}_$(date +%Y%m%d).sql"
            mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$TABLE_NAME" > "$backup_file"
            log "Created backup: $backup_file"
        fi
    fi
}

# Archive function
do_archive() {
    if [ -d "$BACKUP_DIR" ]; then
        timestamp=$(date +%Y-%m-%d_%H-%M)
        archive_name="${BACKUP_ARCHIVE_DIR}/${timestamp}_backup.tar.gz"
        
        tar -czf "$archive_name" -C "$BACKUP_DIR" .
        
        if [ $? -eq 0 ]; then
            log "Created archive: $archive_name"
            rm -f "$BACKUP_DIR"/*.sql
            
            # Keep only latest 3 archives
            ls -t "$BACKUP_ARCHIVE_DIR"/*.tar.gz 2>/dev/null | tail -n +4 | xargs -r rm
        fi
    fi
}

# List archives function
list_archives() {
    echo "Date          Size"
    echo "--------------------"
    ls -lh "$BACKUP_ARCHIVE_DIR"/*.tar.gz 2>/dev/null | awk '{print substr($6,1,4)"."substr($6,6,2)"."substr($6,9,2)".\t"$5}'
}

# Command handling
case "$1" in
    "db")
        echo "DB_NAME=$2" > "$CONFIG_FILE"
        log "Set database name: $2"
        ;;
    "table")
        echo "TABLE_NAME=$2" >> "$CONFIG_FILE"
        log "Set table name: $2"
        ;;
    "backup")
        do_backup
        ;;
    "archive")
        do_archive
        ;;
    "list")
        list_archives
        ;;
    *)
        echo "Usage: $0 {db|table|backup|archive|list} [name]"
        exit 1
        ;;
esac