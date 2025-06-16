#!/bin/bash

# MySQL database credentials
DB_HOST="localhost"
DB_USER=""
DB_PASS=""
DB_NAME=""

# Current date for backup file naming
CURRENT_DATE=$(date +"%m%Y")

# Set the directory to store the SQL backup file
BACKUP_DIR="/home/preprodsyncezy/backup/monthly"

# Set the name for the backup SQL file
BACKUP_FILE="${CURRENT_DATE}_monthly_bu.gzip"

# Log files
ACCESS_LOG_FILE="/home/preprodsyncezy/backup/access_logs.log"
ERROR_LOG_FILE="/home/preprodsyncezy/backup/error_logs.log"
REMOVE_BACKUP_FILE="/home/preprodsyncezy/backup/monthly_removed_backup.log"

# Function to log messages
log_message() {
    local message="$1"
    local log_file="$2"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$log_file")"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
    echo "-------------------------------------------------------------------------------" >> "$log_file"
}

# Ensure the backup directory exists
mkdir -p "$BACKUP_DIR"

# Function to take backup
take_backup() {
    # Capture both stdout and stderr
    output=$(mysqldump -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>&1)
    if [ $? -eq 0 ]; then
        echo "$output" | gzip > "$BACKUP_DIR/$BACKUP_FILE"
        return 0
    else
        # Log the MySQL error
        log_message "MySQL Error: $output" "$ERROR_LOG_FILE"
        return 1
    fi
}

# Take backup
echo "Taking backup to $BACKUP_DIR/$BACKUP_FILE from host $DB_HOST..."
take_backup
backup_success=$?

# Check if backup was successful
if [ $backup_success -eq 0 ]; then
    echo "Backup taken successfully and saved to $BACKUP_DIR/$BACKUP_FILE"
    log_message "Backup successfully created: $BACKUP_FILE" "$ACCESS_LOG_FILE"
else
    echo "Backup failed. Check error logs at $ERROR_LOG_FILE for more information."
fi

# Check if there are more than 3 backups
if [ "${#TOTAL_BACKUP_FILES[@]}" -gt 3 ]; then
    # Sort backups lexicographically and remove the oldest one
    OLDEST_BACKUP=$(printf "%s\n" "${TOTAL_BACKUP_FILES[@]}" | sort | head -n 1)
    rm "$OLDEST_BACKUP"
    
    # Log the removal with date and time in AEST
    echo "$(TZ='Australia/Sydney' date +"%Y-%m-%d %H:%M:%S") AEST - Removed backup: $(basename "$OLDEST_BACKUP")" >> $REMOVE_BACKUP_FILE
    echo "---------------------------------------------------------------------" >> $REMOVE_BACKUP_FILE
fi