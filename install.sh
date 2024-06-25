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

# Check if ping is installed
if ! command -v ping &> /dev/null
then
    print_in_red "ping is not installed. Installing it now..."
    pkg install iputils -y
fi

# Download ip_scanner_config.py
download_ip_scanner_config

# Execute the ip_scanner_config.py script
python ip_scanner_config.py
