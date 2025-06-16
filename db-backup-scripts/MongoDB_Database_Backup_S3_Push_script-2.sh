#!/bin/bash

# MongoDB database credentials
DB_USER=""
DB_PASS=""
DB_NAME=""
DB_HOST=""
DB_PORT=""

# Current date & time
CURRENT_DATE=$(date +"%Y-%m-%d")
CURRENT_TIME=$(TZ=Asia/Kolkata date +'%H:%M:%S')

# Set the directory to store the MongoDB backup file
BACKUP_ROOT_DIR="/home/ubuntu/db_backup/mongodb"
BACKUP_DIR="$BACKUP_ROOT_DIR/backups"

# Set the name for the backup file (tar.gz)
BACKUP_FILE="$DB_NAME-$CURRENT_DATE-$CURRENT_TIME.tar.gz"

# Set the bucket name in AWS S3
S3_BUCKET=""

# Log files
ACCESS_LOG_FILE="/home/ubuntu/db_backup/mongodb/access_logs.log"
ERROR_LOG_FILE="/home/ubuntu/db_backup/mongodb/error_logs.log"

# Function to log messages without overwriting previous logs
log_message() {
    local message="$1"
    local log_file="$2"
    echo "$message" >> "$log_file"
}

# Check if the backup directory exists, if not, create it
if [ ! -d "$BACKUP_ROOT_DIR" ]; then
    mkdir -p "$BACKUP_ROOT_DIR"
fi

# Check if the backups directory exists, if not, create it
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
fi

# Function to take backup
take_backup() {
    local backup_dir="$BACKUP_DIR/$DB_NAME-$CURRENT_DATE-$CURRENT_TIME"
    mongodump --username "$DB_USER" --password "$DB_PASS" --db "$DB_NAME" --out "$backup_dir" --host "$DB_HOST" --port "$DB_PORT"
    
    if [ $? -ne 0 ]; then
        log_message "MongoDB backup failed on $CURRENT_DATE-$CURRENT_TIME. Authentication or connection error." "$ERROR_LOG_FILE"
        exit 1  # Exit script if backup fails
    fi

    # Compress the backup
    tar -czvf "$BACKUP_DIR/$BACKUP_FILE" -C "$backup_dir" .
    
    if [ $? -ne 0 ]; then
        log_message "Backup compression failed on $CURRENT_DATE-$CURRENT_TIME" "$ERROR_LOG_FILE"
        rm -rf "$backup_dir"  # Clean up the uncompressed backup folder
        exit 1  # Exit script if compression fails
    fi

    rm -rf "$backup_dir"  # Remove uncompressed backup folder after compression
    echo "Backup taken: $BACKUP_DIR/$BACKUP_FILE"
}

# Function to calculate backup file size dynamically in KB or MB
get_backup_size() {
    local file_size_bytes=$(du --block-size=1 "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    
    if [ "$file_size_bytes" -lt 1048576 ]; then
        # If file size is less than 1 MB, display size in KB
        local file_size_kb=$(echo "scale=2; $file_size_bytes / 1024" | bc)
        echo "$file_size_kb KB"
    else
        # Display size in MB
        local file_size_mb=$(echo "scale=2; $file_size_bytes / 1048576" | bc)
        echo "$file_size_mb MB"
    fi
}

# Take backup
echo "Taking backup..."
take_backup
backup_success=$?

# Check if backup was successful
if [ $backup_success -eq 0 ]; then
    echo "Backup taken successfully."

    # Calculate backup size after compression
    backup_size=$(get_backup_size)
    echo "Current backup size: $backup_size"

    # Upload the backup file to S3 using AWS CLI
    aws s3 cp "$BACKUP_DIR/$BACKUP_FILE" "s3://$S3_BUCKET/$BACKUP_FILE"

    # Check if upload was successful
    upload_success=$?
    if [ $upload_success -eq 0 ]; then
        echo "Backup uploaded to S3 successfully."

        # Remove the local backup file after successful upload
        rm "$BACKUP_DIR/$BACKUP_FILE"

        # Log deletion of local backup file
        log_message "Local backup file deleted after successful upload to S3." "$ACCESS_LOG_FILE"
    else
        echo "Failed to upload backup to S3. Backup file will not be deleted from local machine."

        # Log failure to upload to S3
        log_message "Failed to upload backup to S3. Backup file will not be deleted from local machine." "$ERROR_LOG_FILE"
    fi

    # Log backup creation and size
    log_message "Backup is created on $CURRENT_DATE-$CURRENT_TIME" "$ACCESS_LOG_FILE"
    log_message "Backup uploaded to S3 successfully." "$ACCESS_LOG_FILE"
    log_message "Backup Size is: $backup_size" "$ACCESS_LOG_FILE"
    log_message "--------------------------------------" "$ACCESS_LOG_FILE"
else
    echo "Backup failed. Check error logs for more information."

    # Log backup failure
    log_message "Backup failed on $CURRENT_DATE-$CURRENT_TIME" "$ERROR_LOG_FILE"
    log_message "-----------------------------------------" "$ERROR_LOG_FILE"
fi
