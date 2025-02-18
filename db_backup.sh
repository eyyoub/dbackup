#!/bin/bash
# Database Backup Service
# Author: Eyyoub
# Logs stored in /var/log/dbbackup/

# Configuration
DB_USER="root"  # Change me
DB_PASS="yourpassword" # change me
DB_NAME=""
TABLE_NAME=""
BACKUP_DIR="/var/backups/dbbackup"
ARCHIVE_DIR="$BACKUP_DIR/backup"
LOG_FILE="/var/log/dbbackup/dbbackup.log"
USER="backupuser"
SERVICE_NAME="dbbackup"

# Ensure directories exist
mkdir -p "$BACKUP_DIR" "$ARCHIVE_DIR" "/var/log/dbbackup"
chown -R "$USER":"$USER" "$BACKUP_DIR" "$ARCHIVE_DIR" "/var/log/dbbackup"

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

backup() {
    if [ "$1" == "db" ]; then
        DB_NAME="$2"
        log "Backing up database: $DB_NAME"
        mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DIR/$DB_NAME-$(date +'%Y-%m-%d').sql"
    elif [ "$1" == "table" ]; then
        DB_NAME="$2"
        TABLE_NAME="$3"
        log "Backing up table: $TABLE_NAME from $DB_NAME"
        mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$TABLE_NAME" > "$BACKUP_DIR/${DB_NAME}_${TABLE_NAME}-$(date +'%Y-%m-%d').sql"
    else
        echo "Usage: dbbackup db DB_NAME or dbbackup table DB_NAME TABLE_NAME"
    fi
}

archive() {
    TIMESTAMP=$(date +'%Y-%m-%d_%H-%M')
    ARCHIVE_NAME="$ARCHIVE_DIR/${TIMESTAMP}_backup.tar.gz"
    log "Creating archive: $ARCHIVE_NAME"
    tar -czf "$ARCHIVE_NAME" -C "$BACKUP_DIR" . && rm -f "$BACKUP_DIR"/*.sql
    
    # Keep only 3 archives
    ls -t "$ARCHIVE_DIR"/*.tar.gz | tail -n +4 | xargs rm -f
}

list_archives() {
    echo -e "Date\tSize"
    ls -lh "$ARCHIVE_DIR"/*.tar.gz | awk '{print $9, $5}' | sed 's/\.\/\|_backup\.tar\.gz//g' | sort
}

setup_service() {
    cat <<EOF | sudo tee /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=Database Backup Service
After=network.target

[Service]
User=$USER
ExecStart=/usr/local/bin/dbbackup db YOUR_DB_NAME
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable $SERVICE_NAME
    sudo systemctl start $SERVICE_NAME
    log "$SERVICE_NAME service installed and started."
}

case "$1" in
    db) backup db "$2" ;;
    table) backup table "$2" "$3" ;;
    archive) archive ;;
    list) list_archives ;;
    setup) setup_service ;;
    *) echo "Usage: $0 {db DB_NAME | table DB_NAME TABLE_NAME | archive | list | setup}" ;;
esac
