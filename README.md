
# Deatiled Of Scripts



## Backup_BasedONSize.sh
This is normal backup scripts that take backup based on file size. Suppose script take backup of 1 MB and stored it and again scrpit will run that time it check that if file size is greater than 1 MB then only it create backup and store it.

## Backup_Normal.sh
This is script is for normal backup, when it runs that time it's create one backup of source file and store it. If you run again this script then it will take backup again of that source files.

## Mysql_Database_Backup_S3_Push_script-1.sh & Mysql_Database_Backup_S3_Push_script-2.sh
This script create backup every time when it's run for mysql databse that created in local host and dumped database in localhost.If you run this script inside EC2 then make sure you have install aws cli in EC2 (not configure only install) & crate one IAM role of S3 full access and attch to that EC2.

## Site_Backup.sh
Take your site backup and store it on S3.

## Database_Backup_S3_Push_BaesON_Size.sh
This script create backup only when databse size is incease of previous store stored database backup. It take backup of Mysql databse that is created and dumped filed in localhost. If you run this script inside EC2 then make sure you have install aws cli in EC2 (not configure only install) & crate one IAM role of S3 full access and attch to that EC2.

## File_Type_Based_forward.sh
This script move source file in specific folder based on file extension. Suppose source filder get one file of PDF extension then it move to the PDF folder. 

## Service_Restart.sh
This script just check any service running on server and if it's stop then it will be restarted automatically when this scripts runs.

## ec2_detail.sh
Show all running ec2 info like key, public ip, private ip etc. make sure aws configure before run this script.

