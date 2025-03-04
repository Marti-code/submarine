#!/bin/bash

### Enumeration Preparation ###

# Usage check
if [ -z "$1" ]; then
  echo "Usage: $0 <target-domain>"
  exit 1
fi

target="$1"
base_dir="${target}/recon"

# Function to check if a command exists
command_exists () {
    command -v "$1" >/dev/null 2>&1 || { echo "[-] $1 is required but not installed. Aborting." >&2; exit 1; }
}

# Check for required tools
tools=(assetfinder subfinder amass httpx nuclei masscan nmap gau waybackurls)
for tool in "${tools[@]}"; do
    command_exists "$tool"
done

# Create necessary directories
mkdir -p "$base_dir"/{scans,httprobe,potential_takeovers,wayback/{params,extensions}}

# Initialize files
touch "$base_dir/httprobe/alive.txt" "$base_dir/final.txt"

### Subdomain Enumeration ###

echo "[+] Harvesting subdomains with assetfinder..."
assetfinder "$target" >> "$base_dir/assets.txt"

echo "[+] Harvesting subdomains with subfinder..."
subfinder -d "$target" >> "$base_dir/subfinder.txt"

echo "[+] Harvesting subdomains with amass..."
amass enum -d "$target" >> "$base_dir/amass.txt"

# Combine and deduplicate all subdomains found
cat "$base_dir/assets.txt" "$base_dir/subfinder.txt" "$base_dir/amass.txt" | grep "$target" | sort -u > "$base_dir/final.txt"
rm "$base_dir/assets.txt" "$base_dir/subfinder.txt" "$base_dir/amass.txt"

### Alive Domain Check using httpx ###

echo "[+] Probing for alive domains with httpx..."
cat "$base_dir/final.txt" | sort -u | httpx -silent -status-code -follow-redirects | awk '{print $1}' | sort -u > "$base_dir/httprobe/alive.txt"

### Subdomain Takeover Check using nuclei ###
# Make sure to update the path to your nuclei takeover templates directory
echo "[+] Checking for possible subdomain takeover with nuclei..."
nuclei -l "$base_dir/final.txt" -t /path/to/takeover-templates/ -o "$base_dir/potential_takeovers/nuclei_takeover.txt"

### Preliminary Port Scanning with masscan ###
echo "[+] Performing preliminary port scan with masscan (requires sudo)..."
sudo masscan -p1-65535 -iL "$base_dir/httprobe/alive.txt" --rate=1000 -oG "$base_dir/scans/masscan.txt"

### Detailed Port Scanning with nmap ###
echo "[+] Scanning for open ports with nmap..."
nmap -iL "$base_dir/httprobe/alive.txt" -T4 -oA "$base_dir/scans/scanned"

### Historical URL Collection ###
echo "[+] Scraping historical URLs with waybackurls..."
cat "$base_dir/final.txt" | waybackurls >> "$base_dir/wayback/wayback_output.txt"

echo "[+] Fetching additional URLs using gau..."
gau "$target" >> "$base_dir/wayback/gau_output.txt"

# Combine results from waybackurls and gau
cat "$base_dir/wayback/wayback_output.txt" "$base_dir/wayback/gau_output.txt" | sort -u > "$base_dir/wayback/all_urls.txt"
rm "$base_dir/wayback/wayback_output.txt" "$base_dir/wayback/gau_output.txt"

### Parameter and File Extension Extraction ###
echo "[+] Extracting parameters from historical URLs..."
grep '?*=' "$base_dir/wayback/all_urls.txt" | cut -d '=' -f 1 | sort -u > "$base_dir/wayback/params/wayback_params.txt"

echo "[+] Extracting file extensions from historical URLs..."
for ext in js html json php aspx; do
    grep "\.${ext}$" "$base_dir/wayback/all_urls.txt" | sort -u > "$base_dir/wayback/extensions/${ext}.txt"
done

echo "[+] Reconnaissance complete. Results saved in ${base_dir}."
