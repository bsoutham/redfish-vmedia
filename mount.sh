#!/bin/bash

ILO_IP=192.168.86.50
ILO_USER="admin"
ILO_PASSWORD="adminadmin"
ISO_URL="http://192.168.86.202:8000/iso/esxi.ISO"
OUTPUT=log.log

function check_var {
  if [ -z "${!1}" ]; then 
    echo "$1 is unset in $0";
    exit 1
  fi
}

function power {
  STATE=$1
  echo Powering "$STATE" server ....
  if [ "$STATE" == "Off" ]; then
    STATE="ForceOff"
  fi
  if [ $STATE == "Reboot" ]; then
    STATE="ForceRestart"
  fi
  CONTENT="$(curl -k -s "https://$ILO_IP/redfish/v1/Systems/1/Actions/ComputerSystem.Reset/" \
    -X POST \
    -d "{\"ResetType\": \"$STATE\"}" \
    -H "X-Auth-Token: $AUTH_TOKEN" \
    -H "Content-Type: application/json")"
    echo "$CONTENT" >> $OUTPUT
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

function http_head {
  CONTENT="$(curl -k -s -I "$ISO_URL")"
  echo "$CONTENT" >> $OUTPUT
  if [[ $CONTENT == *"200 OK"* ]]; then
    echo Found ISO IMAGE: "$ISO_URL"
  else
    echo "ERROR: $? -- Unable to find $ISO_URL"
  fi
}

function mount {
  CONTENT="$(curl -k -s "https://$ILO_IP/redfish/v1/Managers/1/VirtualMedia/2/Actions/VirtualMedia.InsertMedia/"  \
    -H "X-Auth-Token: $AUTH_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"Image\": \"$ISO_URL\"}")"
  echo "$CONTENT" >> $OUTPUT
  if [[ $CONTENT == *"Base.1.4.Success"* ]]; then
    echo Mounted vMedia
    return
  fi
  if [[ $CONTENT == *"MaxVirtualMediaConnectionEstablished"* ]]; then
    echo Virtual Media already mounted
    return
  fi
  echo "ERROR: $? -- Failed to mount vMedia"
}

function next_boot {
  CONTENT="$(curl -k -s -X PATCH "https://$ILO_IP/redfish/v1/Managers/1/VirtualMedia/2/"  \
    -H "X-Auth-Token: $AUTH_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"Oem\": {\"Hpe\": {\"BootOnNextServerReset\": true}}}")"
  echo "$CONTENT" >> $OUTPUT
  if [[ $CONTENT == *"Base.1.4.Success"* ]]; then
    echo Set next boot from vMedia
  else
    echo "ERROR: $? -- Failed to set for next reboot"
  fi
}

#erase log file
echo > $OUTPUT

# shellcheck disable=SC2086
check_var ILO_IP
check_var ILO_USER
check_var ILO_PASSWORD
check_var ISO_URL

echo Attempting Login to iLO at "$ILO_IP"
login

#echo Checking ISO existence "$ISO_URL"
http_head 

# mount the iso over vMedia
mount

# set the next boot to happen from vMedia
next_boot

# power on the server
power On
