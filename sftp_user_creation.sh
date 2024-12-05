#!/bin/bash

# Function to generate an 8-character random password
generate_password() {
  tr -dc 'A-Za-z0-9@#%&' </dev/urandom | head -c 8
}

# Function to log staged progress
log_stage() {
  echo -e "\n========== $1 ==========\n"
}

# Function to print a formatted table row
print_table_row() {
  printf "| %-15s | %-15s | %-40s | %-15s |\n" "$1" "$2" "$3" "$4"
}

# Function to check if vsftpd is installed
check_vsftpd_installed() {
  if dpkg -l | grep -qw vsftpd; then
    return 0
  else
    return 1
  fi
}

# Step 1: Get the username and generate a password
log_stage "STEP 1: User Creation"
read -p "Enter the username for the SFTP user: " username

# Validate the username
if id "$username" &>/dev/null; then
  echo "Error: User $username already exists." >&2
  exit 1
fi

password=$(generate_password)

# Create the user and set the password
if sudo adduser --disabled-password --gecos "" "$username"; then
  echo "$username:$password" | sudo chpasswd
  echo "User $username created successfully."
else
  echo "Error: Failed to create user $username." >&2
  exit 1
fi

# Step 2: Configure SSH for password authentication
log_stage "STEP 2: Configuring SSH"
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Get the custom SSH port if any
ssh_port=$(sudo grep -E "^Port [0-9]+" /etc/ssh/sshd_config | awk '{print $2}')
ssh_port=${ssh_port:-22} # Default to 22 if not set

# Update 60-cloudimg-settings.conf if it exists
if [ -f /etc/ssh/sshd_config.d/60-cloudimg-settings.conf ]; then
  sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
  echo "Updated 60-cloudimg-settings.conf."
fi

sudo systemctl restart ssh
echo "SSH configuration updated and service restarted."

# Step 3: Install and configure vsftpd
log_stage "STEP 3: Configuring SFTP"

if check_vsftpd_installed; then
  echo "vsftpd is already installed. Skipping installation."
else
  sudo apt-get update -y
  sudo apt-get install -y vsftpd
  echo "vsftpd installed."
fi

sudo sed -i 's/^#local_enable=YES/local_enable=YES/' /etc/vsftpd.conf
sudo sed -i 's/^#write_enable=YES/write_enable=YES/' /etc/vsftpd.conf
sudo sed -i 's/^#chroot_local_user=YES/chroot_local_user=YES/' /etc/vsftpd.conf

# Additional security configurations
echo "seccomp_sandbox=NO" | sudo tee -a /etc/vsftpd.conf
echo "allow_writeable_chroot=YES" | sudo tee -a /etc/vsftpd.conf

sudo systemctl restart vsftpd
echo "vsftpd configured."

# Step 4: Add user to the 'ubuntu' group
log_stage "STEP 4: Group Assignment"
sudo adduser "$username" ubuntu
echo "User $username added to group 'ubuntu'."

# Step 5: Display connection details
log_stage "User Connection Details"

public_ip=$(curl -s ifconfig.me)

# Prepare connection string with port if not default
connection_string="ssh $username@$public_ip"
if [ "$ssh_port" -ne 22 ]; then
  connection_string+=" -p $ssh_port"
fi

# Print table header
printf "\n+-----------------+-----------------+------------------------------------------+-----------------+\n"
printf "| %-15s | %-15s | %-40s | %-15s |\n" "Username" "Password" "Connection String" "Public IP"
printf "+-----------------+-----------------+------------------------------------------+-----------------+\n"

# Print user details in table format
print_table_row "$username" "$password" "$connection_string" "$public_ip"

# Print table footer
printf "+-----------------+-----------------+------------------------------------------+-----------------+\n"

echo -e "\nUser setup complete. Use the above credentials to connect.\n"
