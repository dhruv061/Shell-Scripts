#This script craete backup and store it in one folder if the folder rech 3 backup after that scipt delete 
#oldest backup and keep only 3 latest backup everytime.

#!/bin/bash

# Set the source folder to be backed up
source_folder="/home/ubuntu/shellscripting"

# Set the destination folder for backups
backup_folder="/usr/backupfileTask"

# Set the log files
backup_log="/var/log/backupfileTaskLog/backup.log"
retention_log="/var/log/backupfileTaskLog/retention.log"

# Create timestamp for the backup file
timestamp=$(date +"%Y%m%d_%H%M%S")
backup_file="$backup_folder/backup_$timestamp.zip"

# Function to log messages to the backup log
log_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$backup_log"
}

# Function to perform the backup
perform_backup() {
    log_message "Starting backup of $source_folder to $backup_file"
    zip -r "$backup_file" "$source_folder"
    log_message "Backup completed successfully"
}

# Function to perform retention cleanup
perform_retention_cleanup() {
    log_message "Starting retention cleanup"
    
    # Keep only the latest three backup files and log the removed files
    removed_files=$(ls -t "$backup_folder" | tail -n +4)
    for file in $removed_files; do
        rm "$backup_folder/$file"
        log_message "Removed old backup file: $file"
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Removed old backup file: $file" >> "$retention_log"
    done
    
    log_message "Retention cleanup completed successfully"
}

# Main script execution
perform_backup

# Add retention cleanup if needed
perform_retention_cleanup


