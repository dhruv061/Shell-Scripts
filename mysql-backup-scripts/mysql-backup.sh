#!/bin/bash

# ================================
# MySQL Backup Script -> S3 Upload
# ================================

# Timezone (IST) for file naming
IST_TIME=$(TZ="Asia/Kolkata" date +"%H:%M:%S")
IST_DATE=$(TZ="Asia/Kolkata" date +"%d-%m-%Y")

# MySQL credentials
DB_USER=""
DB_PASS=""
DB_NAME=""
DB_HOST=""
DB_PORT=""

# S3 bucket and folder
S3_BUCKET=""
S3_FOLDER=""

# Backup directory on local machine
BACKUP_DIR="/home/ubuntu/mysqlBackup"
LOG_FILE_NAME=""

# File names
BACKUP_FILE="${DB_NAME}-DB-${IST_DATE}-${IST_TIME}-IST.sql"
COMPRESSED_FILE="${BACKUP_DIR}/${DB_NAME}-DB-${IST_DATE}-${IST_TIME}-IST.sql.gz"
LOG_FILE="${BACKUP_DIR}/${LOG_FILE_NAME}"

# Logging function with format
log_message() {
    echo "[$(TZ='Asia/Kolkata' date +"%d-%m-%Y %H:%M:%S")] $1" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

log_message2() {
    echo "----" >> "$LOG_FILE"
}

# Function to take backup and upload
take_backup() {
    log_message "Starting MySQL dump for database: $DB_NAME"
    
    # Dump MySQL database
    mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "${BACKUP_DIR}/${BACKUP_FILE}" 2>>"$LOG_FILE"
    
    if [ ! -s "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
        log_message "ERROR: MySQL dump failed. Aborting."
        exit 1
    fi

    log_message "Compressing backup..."
    gzip "${BACKUP_DIR}/${BACKUP_FILE}" 2>>"$LOG_FILE"

    log_message "Uploading backup to S3 bucket: s3://${S3_BUCKET}/${S3_FOLDER}/"
    aws s3 cp "$COMPRESSED_FILE" "s3://${S3_BUCKET}/${S3_FOLDER}/" >> "$LOG_FILE" 2>&1

    if [ $? -eq 0 ]; then
        rm -f "$COMPRESSED_FILE"
        log_message "SUCCESS: Backup uploaded and local file cleaned up."
        log_message2
    else
        log_message "ERROR: Upload to S3 failed."
        log_message2
        exit 1
    fi
}

# Run backup
take_backup
