#!/bin/bash

# Fetch all running EC2 instances in the specified region
region="ap-south-1"
instances=$(aws ec2 describe-instances --region "$region" --filters "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,PublicIpAddress,Tags[?Key=='Name'].Value | [0]]" --output text)

# Check if any instances are found
if [ -z "$instances" ]; then
    echo "No running EC2 instances found in region $region."
    exit 0
fi

# Function to print a line separator
print_separator() {
    printf "+--------------------------------+----------------------+----------------------+\n"
}

# Display the information in a table format
echo "Running EC2 instances in region $region:"
print_separator
printf "| %-30s | %-20s | %-20s |\n" "Instance Name" "Private IP" "Public IP"
print_separator

while IFS=$'\t' read -r instance_id private_ip public_ip instance_name; do
    # If instance_name is empty, set it to a placeholder
    if [ -z "$instance_name" ]; then
        instance_name="N/A"
    fi
    
    # Handle None/empty values for IPs
    if [ -z "$private_ip" ] || [ "$private_ip" == "None" ]; then
        private_ip="None"
    fi
    
    if [ -z "$public_ip" ] || [ "$public_ip" == "None" ]; then
        public_ip="None"
    fi
    
    printf "| %-30s | %-20s | %-20s |\n" "$instance_name" "$private_ip" "$public_ip"
    print_separator
done <<< "$instances"