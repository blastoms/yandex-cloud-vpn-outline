#!/bin/bash

set -euo pipefail

INSTANCE_NAME=outline-vpn
CLEANUP_REQUIRED=0
OUTPUT_CONFIG='>/dev/null 2>&1'
CONNECTION_ATTEMPTS=12
ATTEMPT_TIMEOUT=5

usage() {
    echo "Usage: $0 " 1>&2
    echo "" 1>&2
    echo "  -d    delete old vpn instance before the configuration" 1>&2
    echo "  -v    verbose output" 1>&2
    echo "  -i    initial connection attempts (default is $CONNECTION_ATTEMPTS)" 1>&2
    echo "  -t    attempt timeout in seconds (default is $ATTEMPT_TIMEOUT)" 1>&2
    exit 1
}

deleteInstance() {
    yc compute instance delete "$INSTANCE_NAME"
}

function get_field_value {
    echo "${ACCESS_CONFIG}" | grep "$1" | sed "s/$1://"
}

while getopts ":i:t:dv" o; do
    case "${o}" in
        i)
            CONNECTION_ATTEMPTS=${OPTARG}
            ;;
        t)
            ATTEMPT_TIMEOUT=${OPTARG}
            ;;
        d)
            CLEANUP_REQUIRED=1
            ;;
        v)
            OUTPUT_CONFIG=''
            ;;
        *)
            usage
            ;;
    esac
done

shift $((OPTIND-1))

if [ "$CLEANUP_REQUIRED" -eq 1 ]
then
    echo "Deleting the old $INSTANCE_NAME server..."
    deleteInstance || true
fi

echo 'Booting up a new server...'

ip=$(yc compute instance create --name $INSTANCE_NAME \
    --zone ru-central1-a \
    --ssh-key ~/.ssh/id_rsa.pub \
    --public-ip \
    --create-boot-disk "name=vpn-disk,auto-delete=true,size=6,image-folder-id=standard-images,image-family=ubuntu-2204-lts" \
    --platform standard-v3 \
    --memory 1 \
    --cores 2 \
    --core-fraction 20 \
    --preemptible \
    | grep -FA2 'one_to_one_nat:' | grep -F 'address:' | sed 's/[[:space:]]*address:[[:space:]]*//g')

echo "New instance IP address: $ip"

echo -n 'Waiting for the server to boot... '

attempts=0
last_attempt_start=$(date +%s)

# Waiting a few seconds to give the server a chance to boot up
while ! ssh -T -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -o "ConnectTimeout=$ATTEMPT_TIMEOUT" yc-user@$ip whoami >/dev/null 2>&1
do
    time_from_attempt_start=$(($(date +%s)-$last_attempt_start))
    attempts=$((attempts+1))

    if [ "$attempts" -ge "$CONNECTION_ATTEMPTS" ]
    then
        echo "Server connection timed out. Try running the script with a higher initial connection attempts value." >&2
        exit 2
    fi

    if [ "$time_from_attempt_start" -lt "$ATTEMPT_TIMEOUT" ]
    then
        sleep $((ATTEMPT_TIMEOUT-time_from_attempt_start))
    fi

    last_attempt_start=$(date +%s)
done

echo -n 'Configuring the server. It may take a couple of minutes... '

ssh -T -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" yc-user@$ip >/dev/null 2>&1 <<END
wget https://raw.githubusercontent.com/Jigsaw-Code/outline-server/master/src/server_manager/install_scripts/install_server.sh
yes | sudo bash ./install_server.sh
END

ACCESS_CONFIG=$(ssh -T -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" yc-user@$ip sudo cat /opt/outline/access.txt 2>/dev/null)

echo "To manage your Outline server, please copy the following line (including curly brackets) into Step 2 of the Outline Manager interface:"
echo -e "\033[1;32m{\"apiUrl\":\"$(get_field_value apiUrl)\",\"certSha256\":\"$(get_field_value certSha256)\"}\033[0m"

echo 'Press enter to remove the created instance (you have an hour), or Ctrl+C to keep at alive.'

read -t 3600

echo 'Removing the instance... '
deleteInstance
