#!/bin/bash
ALL_FILE="all.txt"
OUT_PREFIX="urls"
THREADS=5

# Function to extract root domain
get_root_domain() {
    local domain="$1"
    # Remove port if present
    domain=$(echo "$domain" | sed 's/:[0-9]*$//')
    # Extract root domain (last two parts for most TLDs)
    # Handles cases like www.example.com -> example.com
    echo "$domain" | awk -F. '{if (NF>2) print $(NF-1)"."$NF; else print $0}'
}

# Get total number of lines
TOTAL=$(wc -l < "$ALL_FILE")
CURRENT_START=1
RUN=1

while [ $CURRENT_START -le $TOTAL ]; do
    OUT_FILE="${OUT_PREFIX}${RUN}.txt"
    echo "[*] Starting run #$RUN (lines $CURRENT_START to $TOTAL)"
    echo "[*] Output → $OUT_FILE"
    
    # Run gau on the remaining lines
    sed -n "${CURRENT_START},${TOTAL}p" "$ALL_FILE" | gau --threads "$THREADS" --o "$OUT_FILE"
    
    # If gau finished successfully, break
    if [ $? -eq 0 ]; then
        echo "[+] gau finished normally."
        break
    fi
    
    echo "[!] gau was killed or crashed."
    
    # Find last URL processed
    LAST_URL=$(tail -n 1 "$OUT_FILE")
    if [ -z "$LAST_URL" ]; then
        echo "[!] No URLs captured before crash. Moving to next line."
        CURRENT_START=$((CURRENT_START + 1))
        RUN=$((RUN + 1))
        sleep 10
        continue
    fi
    
    # Extract domain from the last URL
    LAST_DOMAIN=$(echo "$LAST_URL" | sed -E 's#https?://([^/]+).*#\1#')
    echo "[*] Last domain processed: $LAST_DOMAIN"
    
    # Extract root domain
    ROOT_DOMAIN=$(get_root_domain "$LAST_DOMAIN")
    echo "[*] Root domain: $ROOT_DOMAIN"
    
    # First try exact match
    LAST_LINE=$(grep -n "^$LAST_DOMAIN$" "$ALL_FILE" | cut -d: -f1 | tail -n 1)
    
    # If exact match not found, search for root domain
    if [ -z "$LAST_LINE" ]; then
        echo "[*] Exact domain not found, searching for root domain: $ROOT_DOMAIN"
        # Find first occurrence of root domain (with or without subdomain/port)
        LAST_LINE=$(grep -n "$ROOT_DOMAIN" "$ALL_FILE" | cut -d: -f1 | head -n 1)
    fi
    
    if [ -z "$LAST_LINE" ]; then
        echo "[!] Root domain not found in all.txt. Exiting."
        exit 1
    fi
    
    echo "[*] Domain was at line: $LAST_LINE"
    
    # Continue from next line
    CURRENT_START=$((LAST_LINE + 1))
    RUN=$((RUN + 1))
    
    echo "[*] Waiting 10 seconds before continuing…"
    sleep 10
done

echo "[✔] All domains processed."
