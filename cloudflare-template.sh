#!/bin/bash

auth_email=""                                       # The email used to login 'https://dash.cloudflare.com'
auth_method="global"                                # Set to "global" for Global API Key or "token" for Scoped API Token
auth_key=""                                         # Your API Token or Global API Key
zone_identifier=""                                  # Can be found in the "Overview" tab of your domain
record_name=""                                      # Which record you want to be synced
ttl=3600                                            # Set the DNS TTL (seconds)
proxy="false"                                       # Set the proxy to true or false
previous_ip_file="previousIpAddress.txt"            # Filename to save your old IP address. The file will be created in the same folder as this file. The purpose of this file is to reduce the number of api calls to CloudFlare.
ip_services_file="ipServicesFile.txt"               # Filename to save the list of IP services. This list is rotated upon every execution, thus evenly spreading out the requests and reducing the number of calls to each individual service.

###########################################
## Get previously saved IP address
###########################################

# Create the file if it does not exist
if [[ ! -f "$IP_SERVICES_FILE" ]]; then
  touch "$IP_SERVICES_FILE"
  echo "https://api.ipify.org" > "$IP_SERVICES_FILE"
  echo "https://ipv4.icanhazip.com" >> "$IP_SERVICES_FILE"
  echo "https://ipinfo.io/ip" >> "$IP_SERVICES_FILE"
fi

# Create the file if it does not exist
if [[ ! -f "$OLD_IP_FILE" ]]; then
    touch "$OLD_IP_FILE"
fi

# Get the previously saved IP address from the file
if [[ -f "$OLD_IP_FILE" ]]; then
    OLD_IP=$(cat "$OLD_IP_FILE")
fi

###########################################
## Get current IP address
###########################################

# Load IP_SERVICES from file
IP_SERVICES=()
while IFS= read -r line; do
  IP_SERVICES+=("$line")
done < $IP_SERVICES_FILE

# Rotate list
FIRST_SERVICE=${IP_SERVICES[0]}
IP_SERVICES=("${IP_SERVICES[@]:1}" "$FIRST_SERVICE")

# Save rotated list back to file
printf "%s\n" "${IP_SERVICES[@]}" > "$IP_SERVICES_FILE"

REGEX_IPV4="^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))$"

# Try all the IP services for a valid IPv4 address
for service in ${IP_SERVICES[@]}; do
  raw_ip=$(curl -s $service)
  if [[ $raw_ip =~ $REGEX_IPV4 ]]; then
    CURRENT_IP=$BASH_REMATCH
    break
  fi
done

# Exit if IP fetching failed
if [[ -z "$CURRENT_IP" ]]; then
  logger -s "DDNS Updater: Failed to retrieve IP."
  exit 2
fi

# Exit if current IP is the same as the previous
if [[ "$OLD_IP" == "$CURRENT_IP" ]]; then
    logger "DDNS Updater: No update required. Your IP address has not changed."
    exit 0
fi

###########################################
## Check and set the proper auth header
###########################################
if [[ "${AUTH_METHOD}" == "global" ]]; then
  AUTH_HEADER="X-Auth-Key:"
else
  AUTH_HEADER="Authorization: Bearer"
fi

###########################################
## Seek for the A record
###########################################
RECORD=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_IDENTIFIER/dns_records?type=A&name=$RECORD_NAME" \
                      -H "X-Auth-Email: $AUTH_EMAIL" \
                      -H "$AUTH_HEADER $AUTH_KEY" \
                      -H "Content-Type: application/json")
                      
###########################################
## Check if the domain has an A record
###########################################
if [[ $RECORD == *"\"count\":0"* ]]; then
  logger -s "DDNS Updater: Record does not exist, perhaps create one first?"
  exit 1
fi

###########################################
## Set the record identifier from result
###########################################
RECORD_IDENTIFIER=$(echo "$RECORD" | sed -E 's/.*"id":"([A-Za-z0-9_]+)".*/\1/')

###########################################
## Change the IP@Cloudflare using the API
###########################################
UPDATE=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/$ZONE_IDENTIFIER/dns_records/$RECORD_IDENTIFIER" \
                     -H "X-Auth-Email: $AUTH_EMAIL" \
                     -H "$AUTH_HEADER $AUTH_KEY" \
                     -H "Content-Type: application/json" \
                     --data "{\"type\":\"A\",\"name\":\"$RECORD_NAME\",\"content\":\"$CURRENT_IP\",\"ttl\":$TTL,\"proxied\":${PROXY}}")

###########################################
## Save update locally
###########################################
if [[ $UPDATE == *"\"success\":true"* ]]; then 
    printf "%s" "$CURRENT_IP" > "$OLD_IP_FILE"
    logger "DDNS Updater: Successfully updated IP address."
    echo "success"
else
    logger -s "DDNS Updater: Failed to update IP address."
fi