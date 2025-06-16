#!/bin/bash

# Set timezone for naming only (not system-wide)
IST_TIME=$(TZ="Asia/Kolkata" date +"%H:%M:%S")
IST_DATE=$(TZ="Asia/Kolkata" date +"%d-%m-%Y")

# MongoDB Atlas credentials and connection settings
DB_USER="username"
DB_PASS="password"
DB_NAME="db-name"
MONGO_URI="mongodb+srv://${DB_USER}:${DB_PASS}@luv-ludo.l5xfat.mongodb.net/${DB_NAME}?retryWrites=true&w=majority"

# S3 bucket name
S3_BUCKET="mongodb-backup-luvludo"

# Set backup file name and log file
BACKUP_FILE="${DB_NAME}-${IST_DATE}-${IST_TIME}-IST.zip"
LOG_FILE="/home/ubuntu/mongodbBackup/mongo-backup.log"

# Function to take the backup and compress it
take_backup() {
    backup_dir="/home/ubuntu/mongodbBackup/${DB_NAME}-${IST_DATE}-${IST_TIME}"
    
    echo "[$(TZ='Asia/Kolkata' date)] Starting MongoDB Atlas dump..." >> "$LOG_FILE" 2>&1
    mongodump --uri="$MONGO_URI" --out="$backup_dir" >> "$LOG_FILE" 2>&1

    # Check if mongodump actually created the backup directory
    if [ ! -d "$backup_dir" ]; then
        echo "[$(TZ='Asia/Kolkata' date)] ERROR: MongoDB dump failed or produced no output. Aborting." >> "$LOG_FILE" 2>&1
        exit 1
    fi

    echo "[$(TZ='Asia/Kolkata' date)] Compressing backup..." >> "$LOG_FILE" 2>&1
    cd "$backup_dir" >> "$LOG_FILE" 2>&1
    zip -r "${backup_dir}.zip" "$DB_NAME" >> "$LOG_FILE" 2>&1
    cd - >> "$LOG_FILE" 2>&1
    rm -rf "$backup_dir"

    echo "[$(TZ='Asia/Kolkata' date)] Uploading backup to S3..." >> "$LOG_FILE" 2>&1
    aws s3 cp "${backup_dir}.zip" "s3://${S3_BUCKET}/mongodb-luvludo-prod/${BACKUP_FILE}" >> "$LOG_FILE" 2>&1

    if [ -f "${backup_dir}.zip" ]; then
        rm "${backup_dir}.zip"
        echo "[$(TZ='Asia/Kolkata' date)] Cleanup completed. Local backup removed." >> "$LOG_FILE" 2>&1
    else
        echo "[$(TZ='Asia/Kolkata' date)] ERROR: Compression failed. Zip file not found." >> "$LOG_FILE" 2>&1
        exit 1
    fi
}

# Execute the backup function
take_backup