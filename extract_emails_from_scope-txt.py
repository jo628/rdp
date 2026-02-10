#!/usr/bin/env python3

import sys

# List of multi-part TLDs that require 3-part domain extraction
MULTIPART_TLDS = {
    'com.ar', 'com.au', 'com.br', 'com.cn', 'com.co', 'com.dz',
    'com.hk', 'com.mx', 'com.my', 'com.ng', 'com.ph', 'com.sg',
    'com.shopapotheke', 'com.tr', 'com.tw', 'com.ua',
    'co.id', 'co.il', 'co.in', 'co.jp', 'co.kr', 'co.nz',
    'co.th', 'co.uk', 'co.za', 'co.do'
}

# Second-level domains for two-letter country codes
SECOND_LEVEL_DOMAINS = {'com', 'co', 'org', 'net', 'gov', 'edu', 'ac', 'br', 'io'}

# TLD keywords to filter out (bare TLDs shouldn't appear as domains)
TLD_KEYWORDS = {
    'com', 'co', 'org', 'net', 'gov', 'edu', 'ac', 'io', 'fr', 'de',
    'in', 'es', 'mx', 'be', 'hr', 'hu', 'it', 'nl', 'pl', 'pt', 'ro',
    'ru', 'tr', 'ar', 'br'
}

def extract_domain(line):
    """Extract the root domain from a line"""
    # Remove protocol
    line = line.split('://')[-1]
    
    # Remove leading wildcards
    if line.startswith('*.'):
        line = line[2:]
    
    # Remove path
    line = line.split('/')[0]
    
    # Remove empty lines
    if not line:
        return None
    
    # Split into parts
    parts = line.lower().split('.')
    n = len(parts)
    
    if n < 2:
        return None
    
    # Check for multi-part TLDs
    if n >= 3:
        # Check last two parts
        last_two = f"{parts[-2]}.{parts[-1]}"
        
        if last_two in MULTIPART_TLDS:
            # Extract 3 parts: example.com.ar
            domain = f"{parts[-3]}.{parts[-2]}.{parts[-1]}"
            # Make sure the first part is not a TLD keyword
            if parts[-3] not in TLD_KEYWORDS:
                return domain
            else:
                return None
        
        # Check for two-letter country code with SLD
        if len(parts[-1]) == 2 and parts[-2] in SECOND_LEVEL_DOMAINS:
            # Extract 3 parts: example.co.uk
            domain = f"{parts[-3]}.{parts[-2]}.{parts[-1]}"
            # Make sure the first part is not a TLD keyword
            if parts[-3] not in TLD_KEYWORDS:
                return domain
            else:
                return None
    
    # Default: extract 2 parts
    if n >= 2:
        domain = f"{parts[-2]}.{parts[-1]}"
        # Make sure the first part is not a TLD keyword
        if parts[-2] not in TLD_KEYWORDS:
            return domain
    
    return None

def main():
    input_file = 'scope.txt'
    output_file = 'emails.txt'
    
    domains = set()
    
    try:
        with open(input_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line:
                    domain = extract_domain(line)
                    if domain:
                        domains.add(f"@{domain}")
    except FileNotFoundError:
        print(f"Error: {input_file} not found")
        sys.exit(1)
    
    # Sort and write to output
    with open(output_file, 'w') as f:
        for domain in sorted(domains):
            f.write(f"{domain}\n")
    
    print(f"Done! Extracted {len(domains)} unique domains to {output_file}")

if __name__ == '__main__':
    main()
