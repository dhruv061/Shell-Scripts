#!/bin/bash

# Ensure the main backup directory exists
mkdir -p /home/ubuntu/db-backup
mkdir -p /home/ubuntu/db-backup/logs

# Take date value for naming system
dt="mysql_database_$(date '+%d-%m-%Y_%H:%M').zip"
da="mysql_database_$(date '+%d-%m-%Y_%H:%M')"

# Create a temporary folder for taking separate dump of all the databases
mkdir -p /home/ubuntu/db-backup/"$da"

# Change directory to the temporary folder
cd /home/ubuntu/db-backup/"$da" || exit 1  # Exit if cd fails

# Taking dump of all databases as separate SQL files
for DB in $(mysql --defaults-file=/home/ubuntu/.confi.cnf -e 'show databases' -s --skip-column-names); do
    mysqldump --defaults-file=/home/ubuntu/.confi.cnf --single-transaction "$DB" > "$DB.sql"
done

# Change directory back to the main backup folder
cd /home/ubuntu/db-backup || exit 1  # Exit if cd fails

# Create zip archive
zip -r "$dt" "$da"

# Delete temporary dump folder
rm -rf /home/ubuntu/db-backup/"$da"

# Writing log
echo "wrote $dt" >> /home/ubuntu/db-backup/logs/compiled.log

# Upload the zip file to S3 and remove the local copy if the upload is successful
aws s3 cp /home/ubuntu/db-backup/"$dt" s3://ranthambore-db-backup/ && rm /home/ubuntu/db-backup/"$dt"

# Writing log
if [ $? -eq 0 ]; then
    echo "Successfully uploaded and deleted $dt" >> /home/ubuntu/db-backup/logs/compiled.log
else
    echo "Failed to upload $dt" >> /home/ubuntu/db-backup/logs/compiled.log
fi

echo "Done"