#!/bin/bash

if [ "$#" -eq 0 ]
then
  echo "Usage: ./port.sh [IP/IP range] [output_file]"
  echo "Example 1: ./port.sh 192.168.1.1 192.168.1.100 192.168.1.200 result.txt"
  echo "Example 2: ./port.sh 192.168.1.1-10 result.txt"
else
  output_file=${@: -1}
  ips=("${@:1:$#-1}")

  # Function to check if an IP is reachable
  is_reachable() {
    local ip="$1"
    ping -c 1 -W 1 "$ip" > /dev/null 2>&1
  }

  # Function to scan an IP address
  scan_ip() {
    local ip="$1"
    local output="$output_file"

    if is_reachable "$ip"; then
      echo "Scanning IP: $ip"
      echo "Please wait while it is scanning all the open ports for IP: $ip..."
      udp_ports=""
      tcp_ports=""

      for port in $(seq 1 65535)
      do
        (echo >/dev/tcp/$ip/$port) >/dev/null 2>&1 && {
          echo "Port $port is open"
          if nc -zu $ip $port; then
            udp_ports+="$port, "
          else
            tcp_ports+="$port, "
          fi
        }
      done

      # Save output to the specified file
      {
        echo -e "\nIP address: $ip"
        echo -e "\nOpen UDP ports:"
        echo "${udp_ports%, }"
        echo -e "\nOpen TCP ports:"
        echo "${tcp_ports%, }"
      } >> "$output"

      echo "Scan result for IP $ip saved to $output"
    else
      echo "IP $ip is not reachable. Skipping..."
    fi
  }

  # Process each argument (IP or IP range)
  for arg in "${ips[@]}"
  do
    # Check if the argument is an IP range
    if [[ "$arg" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+-[0-9]+$ ]]
    then
      start=$(echo "$arg" | cut -d'-' -f1 | cut -d'.' -f4)
      end=$(echo "$arg" | cut -d'-' -f2)
      prefix=$(echo "$arg" | cut -d'-' -f1 | cut -d'.' -f1-3)

      for ((ip=$start; ip<=$end; ip++))
      do
        scan_ip "$prefix.$ip"
      done
    else
      scan_ip "$arg"
    fi
  done
fi
