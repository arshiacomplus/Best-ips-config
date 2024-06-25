#!/usr/bin/env bash

# Clear the terminal
clear

# Log file
LOG_FILE="install.log"

# Function to log messages
log_message() {
    local message=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') : $message" | tee -a "$LOG_FILE"
}

# Update package list
log_message "Updating package list..."
pkg update -y >> "$LOG_FILE" 2>&1

# Function to check if a package is installed and up-to-date
check_and_install() {
    local package=$1
    if pkg list-installed | grep -q "^$package/"; then
        log_message "$package is already installed. Checking for updates..."
        pkg upgrade -y $package >> "$LOG_FILE" 2>&1
    else
        log_message "Installing $package..."
        pkg install -y $package >> "$LOG_FILE" 2>&1
    fi
}

# Install or update required packages
log_message "Checking and installing required packages..."
check_and_install jq
check_and_install inetutils

# Check if packages were installed successfully
if ! command -v jq &> /dev/null || ! command -v ping &> /dev/null; then
    log_message "One or more required packages failed to install. Please check your package manager settings."
    exit 1
fi

log_message "All required packages are installed and up-to-date."

# Clear the terminal before executing the next script
clear

# Execute the script from the provided URL
log_message "Executing script from URL..."
curl -s https://github.com/arshiacomplus/Best-ips-config/raw/main/ip_config_best.sh | bash >> "$LOG_FILE" 2>&1

# Check if the script executed successfully
if [[ $? -eq 0 ]]; then
    log_message "Script executed successfully."
else
    log_message "Script execution failed."
fi

# Clear the terminal
clear
