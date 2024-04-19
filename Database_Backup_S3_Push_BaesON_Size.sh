# This Script is for database backup
#When new Data is added and it's size is grater then previous databse then this script take 
#backup of it and push this backup into the S3 bucket.

#!/bin/bash

# MySQL database credentials
DB_USER="la_database_of_design"
DB_PASS="zoQa9DctMV"
DB_NAME="la_database_of_design"

# Current date & time
CURRENT_DATE=$(date +"%Y-%m-%d")
CURRENT_TIME=$(TZ=Asia/Kolkata date +'%H:%M:%S')

# Set the directory to store the SQL backup file
BACKUP_DIR="/home/ubuntu/db_backup/backups"

# Set the name for the backup SQL file
BACKUP_FILE="db_backup_$CURRENT_DATE.sql.gz"

# Set the bucket name in AWS S3
S3_BUCKET="design.desk.db.backup"

# Log files
ACCESS_LOG_FILE="/home/ubuntu/db_backup/access_logs.txt"
ERROR_LOG_FILE="/home/ubuntu/db_backup/error_logs.txt"

# Previous backup size file
PREV_SIZE_FILE="$BACKUP_DIR/prev_backup_size.txt"

# Function to log messages without overwriting previous logs
log_message() {
    local message="$1"
    local log_file="$2"
    echo "$message" >> "$log_file"
}

# Check if the backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
fi

# Function to get database size
get_db_size() {
    local size=$(mysql -u$DB_USER --password=$DB_PASS -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.TABLES WHERE table_schema='$DB_NAME';" | grep -v 'Size (MB)')
    # Update the prev_backup_size.txt file with the current size
    echo "$size" > "$PREV_SIZE_FILE"
    echo $size
}

# Function to take backup
take_backup() {
    local backup_file="$BACKUP_DIR/$DB_NAME-$CURRENT_DATE-$CURRENT_TIME.sql.gz"
    mysqldump -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip > "$backup_file"
    echo "Backup taken: $backup_file"
}

# Main script
if [ ! -f $PREV_SIZE_FILE ]; then
    echo "Previous size file not found. Creating..."
    get_db_size > $PREV_SIZE_FILE
    take_backup
    exit 0
fi

previous_size=$(cat $PREV_SIZE_FILE)
current_size=$(get_db_size)

echo "Previous size: $previous_size MB"
echo "Current size: $current_size MB"

if (( $(echo "$current_size > $previous_size" | bc) )); then
    echo "Database size increased. Taking backup..."
    take_backup
    echo $current_size > $PREV_SIZE_FILE

   # Upload the backup file to S3 using AWS CLI
    aws s3 cp "$BACKUP_DIR/$BACKUP_FILE" "s3://$S3_BUCKET/$BACKUP_FILE"

    # Log backup creation
    log_message "Backup is created on $CURRENT_DATE-$CURRENT_TIME" "$ACCESS_LOG_FILE"
    log_message "Backup uploaded to S3 successfully." "$ACCESS_LOG_FILE"
else
    echo "Database size has not increased. No backup taken."
    # Log that no new data is added
    log_message "No new data added. Skipping backup." "$ERROR_LOG_FILE"
    log_message "No Backup is created on $CURRENT_DATE-$CURRENT_TIME" "$ERROR_LOG_FILE"
fi
