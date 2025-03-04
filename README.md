# 🌊 Submarine
Submarine is a subdomain enumeration and reconnaissance tool.

The script:
- gathers subdomains - assetfinder, subfinder, and amass
- determines active subdomains - httpx
- detects possible subdomain takeover - nuclei
- scans ports – masscan, nmap
- scrapes historical data - waybackurls, gau

## Installation
Before using Submarine, ensure you have the required tools installed:

```
sudo apt update && sudo apt install -y assetfinder subfinder amass httpx nuclei masscan nmap gau
```

Also make sure /path/to/takeover-templates/ in the script is set to your Nuclei takeover templates directory.

## Usage
Run the script with a target domain
```
chmod +x submarine.sh
./submarine.sh example.com
```

## Output structure
```
example.com/
├── recon/
│   ├── final.txt                 # List of discovered subdomains  
│   ├── httprobe/alive.txt        # Alive subdomains  
│   ├── potential_takeovers/      # Takeover findings  
│   ├── scans/                    # Scan results  
│   ├── wayback/  
│   │   ├── all_urls.txt          # Historical URLs  
│   │   ├── params/               # Extracted parameters  
│   │   ├── extensions/           # Extracted file extensions  
```

## ⚠️ Disclaimer
This tool is for educational and ethical hacking purposes only. 
Do not use it against domains without explicit permission. 
Misuse may lead to legal consequences.

