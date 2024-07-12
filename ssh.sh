#!/bin/bash

# Function to check for root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Prompt for username
read -p "Enter the username: " username

# Prompt for password
read -s -p "Enter the password: " password
echo

# Prompt for directory path
read -p "Enter the directory path the user should have access to: " directory_path

# Create the user & set password
sudo useradd -m $username
echo "$username:$password" | sudo chpasswd

# Restrict access to the home directory
chmod 700 /home/$username

# Set permissions for the specified directory
chown -R $username:$username $directory_path
chmod -R 750 $directory_path
chsh -s /bin/bash $username

#----------Add command that are allowd------------#
mkdir /home/$username/bin
ln -s /bin/ls /home/$username/bin/ls
ln -s /bin/cp /home/$username/bin/cp
ln -s /bin/mv /home/$username/bin/mv
ln -s /bin/mkdir /home/$username/bin/mkdir
ln -s /bin/rm /home/$username/bin/rm
ln -s /bin/touch /home/$username/bin/touch
ln -s /bin/nano /home/$username/bin/nano
ln -s /bin/cat /home/$username/bin/cat
ln -s /bin/cd /home/$username/bin/cd

#---------------Change directory in login---------#
echo "export PATH=/home/$username/bin" | tee -a /home/$username/.bashrc
echo "cd $directory_path" | tee -a /home/$username/.bashrc

# Set permissions
chown $username:$username /home/$username/.bashrc
chmod 644 /home/$username/.bashrc
chown -R $username:$username /home/$username/bin
chmod -R 755 /home/$username/bin

echo "User $username created and configured with restricted access to $directory_path."
