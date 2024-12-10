#!/bin/bash

myfield="${1}"   #1 represent 1st argument
address="${2}"
amount="${3}"     
memo="${4}"


myconfig="--server http://127.0.0.1:8137 --data-dir /media/zebra5/zebra/.cache/lightwalletd"

if [ "$myfield" == "info" ]; then

        ./zingo-cli $myconfig $myfield | grep -A 25 '{' | jq .vendor | jq '. | select( . != null )'

elif [ "$myfield" == "balance" ]; then

        ./zingo-cli $myconfig $myfield | grep -A 25 '{' | grep -w 'sapling_balance\|orchard_balance\|transparent_balance'

elif [ "$myfield" == "messages" ]; then

        ./zingo-cli $myconfig $myfield | grep -A 25 '{' | jq .value_transfers | jq '. | select( . != null )' | jq .[].memos.[]

elif [ "$myfield" == "quicksend" ]; then
        memo="\"$memo\"" 
        ./zingo-cli $myconfig $myfield $address $amount "$memo" | grep -A 25 '{' | jq .txids | jq '. | select( . != null )' 

elif [ "$myfield" ==  "addresses" ]; then

      ./zingo-cli $myconfig $myfield | grep -A 25 '{' | grep 'address\|transparent\|sapling' | column -t | tr -d ','

elif [ "$myfield"  == "transactions" ]; then

      ./zingo-cli $myconfig $myfield | grep -A 25 '{' | grep 'txid\|datetime\|blockheight\|kind' | sed '/kind/a --------------'

fi

