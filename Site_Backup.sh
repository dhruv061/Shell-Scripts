#!/bin/bash

# Set your WordPress directory path
WORDPRESS_DIR="/var/www/html/ranthambore"

# Set your S3 bucket name
S3_BUCKET="ranthambore-wordpress-website-backup"

# Set the destination directory for backups
BACKUP_DIR="/var/www/html/backup"

# Create a backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Generate a timestamp for the backup file name
TIMESTAMP=$(date +"%Y-%m-%d-%H-%M-%S")

# Compress the WordPress directory into a zip file
zip -r $BACKUP_DIR/wordpress_backup_$TIMESTAMP.zip $WORDPRESS_DIR

# Upload the backup to S3 using instance profile credentials
aws s3 cp $BACKUP_DIR/wordpress_backup_$TIMESTAMP.zip s3://$S3_BUCKET/

# Remove the local backup file after uploading to S3 (optional)
rm $BACKUP_DIR/wordpress_backup_$TIMESTAMP.zip

