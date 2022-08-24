#!/bin/bash

ILO_IP=192.168.86.50
ILO_USER="admin"
ILO_PASSWORD="adminadmin"
OUTPUT=log.log

function check_var {
  if [ -z "${!1}" ]; then 
    echo "$1 is unset in $0";
    exit 1
  fi
}

function login {
  CONTENT="$(curl -k -sD - -o /dev/null  "https://$ILO_IP/redfish/v1/SessionService/Sessions/" \
    -X POST -d "{\"UserName\":\"$ILO_USER\", \"Password\": \"$ILO_PASSWORD\"}" \
    -H "Content-Type: application/json")"
  echo "$CONTENT" >> $OUTPUT
  AUTH_TOKEN=$(awk '/X-Auth-Token/ {print $2}' <<< "$CONTENT")
  echo "$AUTH_TOKEN" >> $OUTPUT
  echo "" >> $OUTPUT
}


function unmount {
  CONTENT="$(curl -k -s -X POST "https://$ILO_IP/redfish/v1/Managers/1/VirtualMedia/2/Actions/VirtualMedia.EjectMedia/"  \
    -H "X-Auth-Token: $AUTH_TOKEN" \
    -H "Content-Type: application/json")"
    
  echo "$CONTENT" >> $OUTPUT
  if [[ $CONTENT == *"Base.1.4.Success"* ]]; then
    echo Unmounted vMedia
    return
  fi
  echo "ERROR: $? -- Failed to mount vMedia"
}

#erase log file
echo > $OUTPUT

# shellcheck disable=SC2086
check_var ILO_IP
check_var ILO_USER
check_var ILO_PASSWORD

echo Attempting Login to $ILO_IP
login

# unmount the iso on vMedia
unmount
