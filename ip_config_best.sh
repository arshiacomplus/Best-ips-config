#!/usr/bin/env bash

# Clear the terminal
clear

# Log file
LOG_FILE="ip_config_best.log"

# Function to log messages
log_message() {
    local message=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') : $message" | tee -a "$LOG_FILE"
}

# Function to create an IP range
create_ip_range() {
  local start_ip=$1
  local end_ip=$2
  local IFS='.'
  read -r -a start <<< "$start_ip"
  read -r -a end <<< "$end_ip"
  local ip_range=()
  local temp=("${start[@]}")

  while [[ "${temp[*]}" != "${end[*]}" ]]; do
    ip_range+=("${temp[0]}.${temp[1]}.${temp[2]}.${temp[3]}")
    ((temp[3]++))
    for i in 3 2 1; do
      if [[ ${temp[i]} -eq 256 ]]; then
        temp[i]=0
        ((temp[i-1]++))
      fi
    done
  done
  ip_range+=("$end_ip")
  echo "${ip_range[@]}"
}

# Function to scan an IP and port
scan_ip_port() {
  local ip=$1
  local port=$2
  local results_file=$3
  local packet_loss_file=$4

  local ping_output ping_status ping_time
  ping_output=$(ping -c 1 -W 5 "$ip" 2>&1)
  ping_status=$?

  if [[ $ping_status -eq 0 ]]; then
    ping_time=$(echo "$ping_output" | awk -F'time=' '/time=/ {print $2}' | awk '{print $1}')
    echo "$ip,$port,$ping_time" >> "$results_file"
  else
    log_message "IP: $ip Port: $port is not responding or closed."
    echo "$ip" >> "$packet_loss_file"
  fi

  if echo "$ping_output" | grep -q "error"; then
    log_message "Error pinging $ip:$port - $ping_output"
    echo "$ip" >> "$packet_loss_file"
  fi
}

# Function to validate VLESS configuration
validate_vless_config() {
  local config_file=$1
  if ! jq . "$config_file" > /dev/null 2>&1; then
    echo "Invalid JSON format in VLESS configuration"
    exit 1
  fi
  local address=$(jq -r '.vnext[0].address' "$config_file")
  local port=$(jq -r '.vnext[0].port' "$config_file")
  local host=$(jq -r '.headers.Host' "$config_file")
  local path=$(jq -r '.path' "$config_file")

  if [[ -z "$host" || -z "$path" ]]; then
    echo "Invalid VLESS configuration: Host and Path fields are required"
    exit 1
  fi

  echo "Valid VLESS configuration"
}

# Main function
main() {
  local config_file=$1
  if [[ -z "$config_file" ]]; then
    echo "Usage: $0 <path_to_vless_config>"
    exit 1
  fi

  validate_vless_config "$config_file"

  echo "Please wait, scanning IP ..."
  log_message "Started scanning IPs."

  local start_ips=("188.114.96.0" "162.159.192.0" "162.159.195.0")
  local end_ips=("188.114.99.224" "162.159.193.224" "162.159.195.224")
  local ports=(1074 894 908 878)
  local results_file="results.csv"
  local packet_loss_file="packet_loss.csv"
  > "$results_file"
  > "$packet_loss_file"

  for i in "${!start_ips[@]}"; do
    ip_range=($(create_ip_range "${start_ips[$i]}" "${end_ips[$i]}"))
    for ip in "${ip_range[@]}"; do
      for port in "${ports[@]}"; do
        scan_ip_port "$ip" "$port" "$results_file" "$packet_loss_file" &
      done
    done
  done
  wait

  declare -A packet_loss
  while read -r ip; do
    packet_loss["$ip"]=$((packet_loss["$ip"] + 1))
  done < "$packet_loss_file"

  extended_results=()
  while IFS=, read -r ip port ping; do
    loss_rate=${packet_loss["$ip"]}
    [[ -z "$loss_rate" ]] && loss_rate=0
    combined_score=$(awk "BEGIN {print $ping + ($loss_rate * 10)}")
    extended_results+=("$ip,$port,$ping,$loss_rate,$combined_score")
  done < "$results_file"

  for ip in "${!packet_loss[@]}"; do
    if ! grep -q "$ip" "$results_file"; then
      loss_rate=${packet_loss["$ip"]}
      combined_score=$(awk "BEGIN {print $loss_rate * 10}")
      extended_results+=("$ip,None,None,$loss_rate,$combined_score")
    fi
  done

  sorted_results=($(printf '%s\n' "${extended_results[@]}" | sort -t, -k5 -n))

  while [[ ${#sorted_results[@]} -lt 10 ]]; do
    sorted_results+=("No IP,None,None,100,1000")
  done

  echo -e "IP\tPort\tPing (ms)\tPacket Loss (%)\tScore"
  for result in "${sorted_results[@]:0:10}"; do
    IFS=, read -r ip port ping loss_rate combined_score <<< "$result"
    [[ $port == "None" ]] && port=878
    echo -e "$ip\t$port\t${ping:-None}\t$loss_rate%\t$combined_score"
  done

best_result=${sorted_results[0]}
  IFS=, read -r ip port ping loss_rate combined_score <<< "$best_result"

  if [[ "$ip" != "No IP" ]]; then
    echo "The best IP: $ip:$port, ping: ${ping:-None} ms, packet loss: $loss_rate%, score: $combined_score"
    jq --arg address "$ip" --argjson port "$port" '.vnext[0].address = $address | .vnext[0].port = $port' "$config_file" > "new_$config_file"
    echo "Updated VLESS configuration saved to new_$config_file"
    echo "Updated VLESS Configuration:"
    cat "new_$config_file"
    log_message "Updated VLESS configuration saved to new_$config_file."
  else
    echo "Nothing was found"
    log_message "No suitable IP found."
  fi

  # Clear the terminal at the end of the script
  clear
}

main "$@
