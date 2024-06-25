import re
import os
import subprocess

def print_in_red(text):
    """
    Prints the given text in red color.
    """
    print(f"\033[91m{text}\033[0m")

def extract_ip(config_url):
    """
    Extracts the IP or hostname from the VLESS configuration URL.
    """
    pattern = r'vless://[a-f0-9-]+@([a-zA-Z0-9.-]+):\d+'
    match = re.search(pattern, config_url)
    if match:
        return match.group(1)
    else:
        return None

def ping_ip(ip):
    """
    Pings the given IP address or hostname.
    """
    print(f"[+] Pinging {ip}...")
    response = os.system(f"ping -c 4 {ip}")
    if response == 0:
        print(f"[+] {ip} is up!")
    else:
        print(f"[-] {ip} is down!")

def validate_config_url(config_url):
    """
    Validates if the config URL starts with 'vless://'.
    """
    return config_url.startswith("vless://")

if __name__ == "__main__":
    while True:
        config_url = input("Please enter the config_url: ")
        if not validate_config_url(config_url):
            print_in_red("Error: config_url must start with 'vless://'.")
        else:
            ip = extract_ip(config_url)
            if ip:
                print(f"[+] Extracted IP: {ip}")
                ping_ip(ip)
                break
            else:
                print_in_red("Failed to extract IP from config URL. Please try again.")
