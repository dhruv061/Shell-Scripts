#This script restart the service if any service is not started or stoped

#!/bin/bash

# Define the service name you want to monitor
SERVICE_NAME=$1

# Check if the service is running
service_status=$(systemctl is-active $SERVICE_NAME)

if [ "$service_status" != "active" ]; then
    echo "Service $SERVICE_NAME is not running. Restarting..."
    
    # Restart the service
    systemctl restart $SERVICE_NAME
    
    # Check the service status again
    service_status=$(systemctl is-active $SERVICE_NAME)
    
    if [ "$service_status" = "active" ]; then
        echo "Service $SERVICE_NAME restarted successfully."
    else
        echo "Failed to restart $SERVICE_NAME. Check logs for more information."
    fi
fi

# Print all processes associated with the service name
echo "Processes for service $SERVICE_NAME:"
ps aux | grep -E "$SERVICE_NAME"

# Additional information: You can customize the script by replacing "your_service_name" with the actual service name you want to monitor.
