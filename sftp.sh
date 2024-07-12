#!/bin/bash

# Prompt for the path of the directory
read -p "Enter the username: " USERNAME
read -s -p "Enter the password: " PASSWORD
echo
read -p "Enter the path of the directory (e.g., /var/www/html): " HOMEDIR
echo

# Create the user & set password
sudo useradd -m $USERNAME
echo "$USERNAME:$PASSWORD" | sudo chpasswd

# Change the ownership of the directory to the new user
sudo chown -R $USERNAME:$USERNAME $HOMEDIR

# Restrict User Access to the specified directory
sudo usermod -s /bin/bash $USERNAME

# Configure SSH for SFTP access
sudo bash -c "cat >> /etc/ssh/sshd_config << EOF

Match User $USERNAME
    ChrootDirectory $HOMEDIR
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
EOF"

# set permission
sudo chown root:root $HOMEDIR
sudo chmod 755 $HOMEDIR

sudo systemctl restart ssh

echo "User $USERNAME has been created and configured for SFTP access to $HOMEDIR"
