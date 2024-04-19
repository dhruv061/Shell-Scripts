# This Script is for database backup
# When ever new data is added then you run this scrit then it create one backup and push it into the S3 bucket.

#!/bin/bash

# MySQL database credentials
DB_USER="demo"
DB_PASS="12345678"
DB_NAME="demo_db"

# Current date & time
CURRENT_DATE=$(date +"%Y-%m-%d")
CURRENT_TIME=$(TZ=Asia/Kolkata date +'%H:%M:%S')

# Set the directory to store the SQL backup file
BACKUP_ROOT_DIR="/home/ubuntu/db_backup"
BACKUP_DIR="$BACKUP_ROOT_DIR/backups"

# Set the name for the backup SQL file
BACKUP_FILE="$DB_NAME-$CURRENT_DATE-$CURRENT_TIME.sql.gz"

# Set the bucket name in AWS S3
S3_BUCKET="design.desk.db.backup"

# Log files
ACCESS_LOG_FILE="/home/ubuntu/db_backup/access_logs.log"
ERROR_LOG_FILE="/home/ubuntu/db_backup/error_logs.log"


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

# Function to get database size
get_db_size() {
    local size=$(mysql -u$DB_USER --password=$DB_PASS -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.TABLES WHERE table_schema='$DB_NAME';" | grep -v 'Size (MB)')
    echo $size
}

# Function to take backup
take_backup() {
    local backup_file="$BACKUP_DIR/$DB_NAME-$CURRENT_DATE-$CURRENT_TIME.sql.gz"
    mysqldump -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip > "$backup_file"
    echo "Backup taken: $backup_file"
}


current_size=$(get_db_size)

# echo "Previous size: $previous_size MB"
echo "Current size of backup: $current_size MB"

# Take backup
echo "Taking backup..."
take_backup
backup_success=$?

# Check if backup was successful
if [ $backup_success -eq 0 ]; then
    echo "Backup taken successfully."

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

    # Log backup creation
    log_message "Backup is created on $CURRENT_DATE-$CURRENT_TIME" "$ACCESS_LOG_FILE"
    log_message "Backup uploaded to S3 successfully." "$ACCESS_LOG_FILE"
    log_message "Backup Size is: $current_size MB" "$ACCESS_LOG_FILE"
    log_message "--------------------------------------" "$ACCESS_LOG_FILE"
else
    echo "Backup failed. Check error logs for more information."

    # Log backup failure
    log_message "Backup failed on $CURRENT_DATE-$CURRENT_TIME" "$ERROR_LOG_FILE"

    # Log error in error log
    log_message "Backup failed. Error: $backup_success" "$ERROR_LOG_FILE"
    log_message "-----------------------------------------" "$ERROR_LOG_FILE"
fi
