#!/bin/bash

# Function to print text in red
print_in_red() {
    echo -e "\033[91m$1\033[0m"
}

# Function to download ip_scanner_config.py
download_ip_scanner_config() {
    if ! command -v curl &> /dev/null
    then
        print_in_red "curl is not installed. Installing it now..."
        pkg install curl -y
    fi

    print_in_red "Downloading ip_scanner_config.py..."
    curl -O https://raw.githubusercontent.com/arshiacomplus/Best-ips-config/main/ip_scanner_config.py
}

# Function to install or update a package
install_or_update_package() {
    local package=$1
    if ! command -v $package &> /dev/null
    then
        print_in_red "$package is not installed. Installing it now..."
        pkg install $package -y
    else
        print_in_red "$package is already installed. Updating it now..."
        pkg update $package -y
    fi
}

# Check if ping is installed and update if necessary
install_or_update_package iputils

# Check if python is installed and update if necessary
install_or_update_package python

# Download ip_scanner_config.py
download_ip_scanner_config

# Execute the ip_scanner_config.py script
python ip_scanner_config.py