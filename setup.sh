#!/bin/bash

# Currently, even in dev builds, siad does not allow local ip
# addresses to be announced.

# Thus, DOMAIN must either be a DNS record (not just an /etc/hosts entry)
# pointing to machine this is running on, or you must patch sia to
# allow hosts to announce local IP addresses.
local_ip=$(ip route get 8.8.8.8 | awk 'NR==1 {print $7}')

DOMAIN="$local_ip"
# Override this if you choose the local DNS entry route
DOMAIN="pewter.cst"

HOSTNUM=6
if [[ X"$1" != X ]]
then
    HOSTNUM=$1
fi

echo "Usage: $0 [number_of_nodes]"
echo "Once ant farm is running, type 'exit' to kill it"

# Bash expanded templated json? Really hacky but easy to understand how it works
read -d '' CONFIGHEAD <<"EOF"
{
    "antconfigs":
    [
EOF
read -d '' CONFIGHOST <<"EOF"
        {
            \\\"jobs\\\": [
                \\\"gateway\\\",
        \\\"host\\\"
            ],
            \\\"apiaddr\\\": \\\"127.0.0.1:100$i\\\",
        \\\"HostAddr\\\": \\\"0.0.0.0:200$i\\\"
        },

EOF
read -d '' CONFIGTAIL <<"EOF"
        {
            "apiaddr": "127.0.0.1:9980",
            "jobs": [
                "gateway",
                "miner"
            ]
        }
    ],
    "autoconnect": true
}
EOF

buildconfig() {
    n=$1
    echo -e $CONFIGHEAD > config.json
    for i in $(seq -w 00 $n)
    do
        echo "Adding node number $i"
        eval "echo -e $(echo -e $CONFIGHOST)" >> config.json
    done
    echo -e $CONFIGTAIL >> config.json
}


main() {
    n=$1
    buildconfig $n
    rm /tmp/sa-fifo
    mkfifo /tmp/sa-fifo # fifo is later used to do basic synchro
    (sia-antfarm 2>&1 | tee /tmp/sa-fifo)&

    # Wait for the antfarm to start
    while true
    do
        if read line
        then
            if [[ "$line" == *"Block Height"* ]]
            then
                break
            fi
        fi
    done </tmp/sa-fifo
    echo "[SCRIPT] Antfarm has finished, will start configuring hosts soon"

    # Give some time to mine
    sleep 10

    # Send money to host wallets for collatoral and announce host
    rm -rf /tmp/siahost
    mkdir /tmp/siahost
    for i in $(seq -w 00 $n)
    do
        addr=$(siac -a localhost:100$i wallet address | awk '{print $4}')
        siac wallet send siacoins 100KS $addr
        siac -a localhost:100$i host folder add /tmp/siahost 1GB
    done
    # Wait for siacoins sent from the miner to all the hosts to clear
    sleep 10
    for i in $(seq -w 00 $n)
    do
        siac -a localhost:100$i host announce $DOMAIN:200$i
    done
    sleep 10
    siac hostdb -v
}

main $HOSTNUM

while read line
do
    if [[ line == "exit" ]]
    then
        break
    fi
done
