#!/usr/bin/env bash

# Clear the terminal
clear

# Update package list
echo "Updating package list..."
pkg update -y

# Function to check if a package is installed and up-to-date
check_and_install() {
    local package=$1
    if pkg list-installed | grep -q "^$package/"; then
        echo "$package is already installed. Checking for updates..."
        pkg upgrade -y $package
    else
        echo "Installing $package..."
        pkg install -y $package
    fi
}

# Install or update required packages
echo "Checking and installing required packages..."
check_and_install jq
check_and_install inetutils

# Check if packages were installed successfully
if ! command -v jq &> /dev/null || ! command -v ping &> /dev/null; then
    echo "One or more required packages failed to install. Please check your package manager settings."
    exit 1
fi

echo "All required packages are installed and up-to-date."

# Clear the terminal before executing the next script
clear

# Execute the script from the provided URL
echo "Executing script from URL..."
curl -s https://github.com/arshiacomplus/Best-ips-config/raw/main/ip_config_best.sh | bash
