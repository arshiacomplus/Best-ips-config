import re
import os
import subprocess

def print_in_red(text):
    """
    Prints the given text in red color.
    
    Parameters:
    text (str): The text to print in red.
    """
    print(f"\033[91m{text}\033[0m")

def check_and_install_dependencies():
    """
    Checks if required dependencies (ping) are installed and prompts the user to install them if they are missing.
    """
    try:
        # Check if ping is installed
        subprocess.run(["ping", "-c", "1", "127.0.0.1"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print_in_red("ping is not installed. Installing it now...")
        os.system("pkg install iputils -y")

def extract_ip(config_url):
    """
    Extracts the IP or hostname from the VLESS configuration URL.

    Parameters:
    config_url (str): The VLESS configuration URL.

    Returns:
    str: The extracted hostname or IP address, or None if extraction fails.
    """
    # Regex pattern to extract the hostname
    pattern = r'vless://[a-f0-9-]+@([a-zA-Z0-9.-]+):\d+'
    match = re.search(pattern, config_url)
    if match:
        hostname = match.group(1)
        return hostname
    else:
        return None

def ping_ip(ip):
    """
    Pings the given IP address or hostname.

    Parameters:
    ip (str): The IP address or hostname to ping.

    Returns:
    None
    """
    print(f"Pinging {ip}...")
    # Ping the IP address
    response = os.system(f"ping -c 4 {ip}")
    if response == 0:
        print(f"{ip} is up!")
    else:
        print(f"{ip} is down!")

def validate_config_url(config_url):
    """
    Validates if the config URL starts with 'vless://'.

    Parameters:
    config_url (str): The VLESS configuration URL.

    Returns:
    bool: True if the URL is valid, False otherwise.
    """
    return config_url.startswith("vless://")

if __name__ == "__main__":
    check_and_install_dependencies()
    
    # Loop to ensure valid input from user
    while True:
        config_url = input("Please enter the config_url: ")
        
        if not validate_config_url(config_url):
            print_in_red("Error: config_url must start with 'vless://'.")
        else:
            ip = extract_ip(config_url)
            if ip:
                print(f"Extracted IP: {ip}")
                ping_ip(ip)
                break  # Exit the loop if everything is successful
            else:
                print_in_red("Failed to extract IP from config URL. Please try again.")
