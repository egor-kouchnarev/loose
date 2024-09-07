#!/usr/bin/env zsh

# Check if domain argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <domain>"
  exit 1
fi

DOMAIN=$1

# Define DKIM selectors
DKIM_SELECTORS=(
  "amazonses"
  "axigen"
  "google"
  "office365"
  "sendgrid"
  "mandrill"
  "mailgun"
  "postmark"
  "sparkpost"
  "default"
  "dkim"
  "domain"
  "auth"
  "pic"
  "ic"
  "info"
  "is"
  "k2"
  "k3"
  "s1"
  "s2"
  "s3"
  "selector"
  "selector1"
  "selector2"
  "strong"
  "zoho"
  "sib"
  "smtpapi"
)

# Function to get the RCODE for the domain
get_rcode() {
  local domain=$1
  local result
  result=$(dig +short NS "$domain" 2>&1)

  if echo "$result" | grep -q "NXDOMAIN"; then
    echo "3"  # NXDOMAIN
  elif echo "$result" | grep -q "SERVFAIL"; then
    echo "2"  # SERVFAIL
  elif echo "$result" | grep -q "REFUSED"; then
    echo "5"  # REFUSED
  elif [ -z "$result" ]; then
    echo "4"  # NORESPONSE
  else
    echo "0"  # NOERROR
  fi
}

# Get the RCODE for the domain
RCODE=$(get_rcode "$DOMAIN")

# Initialize YAML output
{
  echo "domain: $DOMAIN"
  echo "timestamp: $(date +'%Y-%m-%dT%H:%M:%S%z')"
  echo "rcode: $RCODE"

  # If RCODE indicates an error or no response, exit early
  if [ "$RCODE" != "0" ]; then
    echo "records: null"
    exit 0
  fi

  # If domain exists, proceed to fetch and print DNS records
  echo "records:"

  # Fetch and print DMARC record
  echo "  dmarc:"
  DMARC_RESULT=$(dig +short TXT _dmarc.$DOMAIN)
  if [ -n "$DMARC_RESULT" ]; then
    echo "$DMARC_RESULT" | while IFS= read -r LINE; do
      CLEAN_LINE=$(echo "$LINE" | tr -d '"')
      echo "    - $CLEAN_LINE"
    done
  else
    echo "    null"
  fi

  # Fetch and print SPF records
  echo "  spf:"
  SPF_RESULT=$(dig +short TXT $DOMAIN | grep "v=spf")
  if [ -n "$SPF_RESULT" ]; then
    echo "$SPF_RESULT" | while IFS= read -r LINE; do
      CLEAN_LINE=$(echo "$LINE" | tr -d '"')
      echo "    - $CLEAN_LINE"
    done
  else
    echo "    null"
  fi

  # Fetch and print DKIM records
  echo "  dkim:"
  DKIM_FOUND=false
  for SELECTOR in "${DKIM_SELECTORS[@]}"; do
    DKIM_RECORDS=$(dig +short TXT "$SELECTOR._domainkey.$DOMAIN")
    CONCATENATED_RECORDS=""
    
    if [ -n "$DKIM_RECORDS" ]; then
      CONCATENATED_RECORDS=$(echo "$DKIM_RECORDS" | tr -d '"')
      
      # Check for DKIM or DomainKey in the concatenated string
      if echo "$CONCATENATED_RECORDS" | grep -iqE 'dkim|domainkey'; then
        echo "    $SELECTOR:"
        echo "$CONCATENATED_RECORDS" | while IFS= read -r LINE; do
          echo "      - $LINE"
        done
        DKIM_FOUND=true
      fi
    fi
  done

  if [ "$DKIM_FOUND" = false ]; then
    echo "    null"
  fi

  # Fetch and print A records
  echo "  a:"
  A_RESULT=$(dig +short A $DOMAIN)
  if [ -n "$A_RESULT" ]; then
    echo "$A_RESULT" | while IFS= read -r LINE; do
      echo "    - $LINE"
    done
  else
    echo "    null"
  fi

  # Fetch and print AAAA records
  echo "  aaaa:"
  AAAA_RESULT=$(dig +short AAAA $DOMAIN)
  if [ -n "$AAAA_RESULT" ]; then
    echo "$AAAA_RESULT" | while IFS= read -r LINE; do
      echo "    - $LINE"
    done
  else
    echo "    null"
  fi

  # Fetch and print MX records
  echo "  mx:"
  MX_RESULT=$(dig +short MX $DOMAIN)
  if [ -n "$MX_RESULT" ]; then
    echo "$MX_RESULT" | while IFS= read -r LINE; do
      echo "    - $LINE"
    done
  else
    echo "    null"
  fi

  # Fetch and print NS records
  echo "  ns:"
  NS_RESULT=$(dig +short NS $DOMAIN)
  if [ -n "$NS_RESULT" ]; then
    echo "$NS_RESULT" | while IFS= read -r LINE; do
      echo "    - $LINE"
    done
  else
    echo "    null"
  fi

  # Fetch and print SOA record
  echo "  soa:"
  SOA_RESULT=$(dig +short SOA $DOMAIN)
  if [ -n "$SOA_RESULT" ]; then
    echo "$SOA_RESULT" | while IFS= read -r LINE; do
      echo "    - $LINE"
    done
  else
    echo "    null"
  fi
}
