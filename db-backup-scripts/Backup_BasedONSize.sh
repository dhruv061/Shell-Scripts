#If any new data is added then size is incese and then only take backup of it.
#!/bin/bash

# Set the source folder to be backed up
source_folder="/home/ubuntu/shellscripting"

# Set the destination folder for backups
backup_folder="/usr/backupfileTask"

# Set the log files
backup_log="/var/log/backupfileTaskLog/backup.log"
retention_log="/var/log/backupfileTaskLog/retention.log"

# File to store the timestamp of the last backup
last_backup_timestamp_file="/var/log/backupfileTaskLog/last_backup_timestamp.txt"

# Function to log messages to the backup log
log_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$backup_log"
}

# Function to get the timestamp of the last backup
get_last_backup_timestamp() {
    if [ -f "$last_backup_timestamp_file" ]; then
        cat "$last_backup_timestamp_file"
    else
        echo "0"
    fi
}

# Function to set the timestamp of the last backup
set_last_backup_timestamp() {
    date +"%s" > "$last_backup_timestamp_file"
}

# Function to perform the backup
perform_backup() {
    log_message "Checking for changes in $source_folder"
    
    last_backup_timestamp=$(get_last_backup_timestamp)
    latest_file_timestamp=$(find "$source_folder" -type f -exec stat -c %Y {} + | sort -n | tail -n 1)

    if [ "$latest_file_timestamp" -gt "$last_backup_timestamp" ]; then
        timestamp=$(date +"%Y%m%d_%H%M%S")
        backup_file="$backup_folder/backup_$timestamp.zip"

        log_message "Starting backup of $source_folder to $backup_file"
        zip -r "$backup_file" "$source_folder"
        log_message "Backup completed successfully"
        
        set_last_backup_timestamp
    else
        log_message "No changes detected. Skipping backup."
    fi
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
