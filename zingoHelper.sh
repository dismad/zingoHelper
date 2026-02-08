#!/bin/bash

myfield="${1}"   #1 represent 1st argument
address="${2}"
amount="${3}"     #2 represent 2st argument
memo="${4}"

#--chain testnet --server https://testnet.zec.rocks:443 --data-dir /home/zktails/Documents/zingolib
#--server http://127.0.0.1:8137 --data-dir /media/zebra5/zebra/.cache/lightwalletd

myconfig="--chain testnet --server https://testnet.zec.rocks:443 --data-dir /home/zktails/Documents/scripts/zingoHelper/"

if [ "$myfield" == "help" ]; then

        ./zingo-cli $myconfig $myfield | column -s '-' -t

elif [ "$myfield" == "clear" ]; then

	./zingo-cli $myconfig $myfield | tail -n +3 | head -n -2 | jq .

elif [ "$myfield" == "info" ]; then

       ./zingo-cli $myconfig $myfield | tail -n +3 | head -n -2 | jq .

elif [ "$myfield" == "height" ]; then

       ./zingo-cli $myconfig $myfield | tail -n +3 | head -n -2 | jq -r '.height'

elif [ "$myfield" == "rescan" ]; then

       ./zingo-cli $myconfig $myfield $address

elif [ "$myfield" == "balance" ]; then

        ./zingo-cli $myconfig "--waitsync" $myfield | tail -n +3 | head -n -2 | grep -w 'confirmed_sapling_balance\|confirmed_orchard_balance\|confirmed_transparent_balance' | head -n -2 | cut -d ":" -f2 | column -t | column -s '_' -t | tr -d ' '

elif [ "$myfield" == "spendable_balance" ]; then

        ./zingo-cli $myconfig "--waitsync" $myfield | tail -n +3 | head -n -2 | jq .spendable_balance

elif [ "$myfield" == "messages" ]; then

        ./zingo-cli $myconfig "--waitsync" $myfield | tail -n +3 | head -n -2 | jq .value_transfers | jq '. | select( . != null )' | jq .[].memos.[]

elif [ "$myfield" == "sync" ]; then

        ./zingo-cli $myconfig "--waitsync" $myfield $address

elif [ "$myfield" == "confirm" ]; then

	./zingo-cli $myconfig $myfield | tail -n +3 | head -n -2 | jq .

elif [ "$myfield" == "quicksend" ]; then
        memo="\"$memo\""

        ./zingo-cli $myconfig "--waitsync" $myfield $address $amount "$memo" > temp
        cat temp | tail -n +3 | head -n -2 | jq  


elif [ "$myfield" ==  "addresses" ]; then

       ./zingo-cli $myconfig $myfield > hmm
       cat hmm | tail -n +3 | head -n -2 | jq -r '.[].encoded_address'
       rm hmm

elif [ "$myfield"  == "transactions" ]; then

      ./zingo-cli $myconfig $myfield | tail -n +3 | head -n -2 | grep 'txid\|datetime\|blockheight\|kind' | sed '/kind/a --------------' > temp
      cat temp

else
      echo "Try another command!"
      echo
fi

