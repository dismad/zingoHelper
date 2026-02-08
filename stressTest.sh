#!/bin/bash

amount="${1}"

myconfig="--chain testnet --server https://testnet.zec.rocks:443 --data-dir /home/zktails/Documents/scripts/zingoHelper/"
amount=100000
ua="utest1jeryw4al7wtv7efn8yh2apucuy48ss0lwf02pdnrnf69wnp0c5zs02j0t395kwdeqwm60jgjhjkrh606470ptxv0kygfwpdxfczaxl3k"


for (( i=1; i<100; i++ ))
do
	amount=1000000

	
        ./zingo-cli $myconfig "transactions" "--waitsync" > temp.log
        oldHeight=$(cat temp.log | tail -n +3 | head -n -2 | grep 'txid\|datetime\|blockheight\|kind' | sed '/kind/a --------------' | tail -n -3 | head -n -2 | cut -d ":" -f2 | column -t)
        minRequired=$(echo "$oldHeight + 1" | bc)
        ./zingo-cli $myconfig "height" "--waitsync" > myheight.log
        currentHeight=$(cat myheight.log | tail -n +3 | head -n -2 | jq -r '.height')

	echo
	echo "Verify last transaction has confirmed more than 1 times:"
	echo
	echo "old: $oldHeight"
	echo "new: $currentHeight"
	echo "-------------------"
	result=$(echo "$currentHeight - $oldHeight" | bc)
	
	if [ "$result" -gt "1" ]; then
		echo "result: $result ✅"
		echo	
	else
		echo "result: $result ❌"
		echo
	fi

	if [ "$currentHeight" -gt "$minRequired" ]; then
		
		./zingo-cli $myconfig "--waitsync" "rescan" > rescan.log
		sleep 20s

		result=$(./zingoHelper.sh quicksend $ua $amount "memo_$i")
		
        	echo "transaction $i :"
		echo "$result"
		echo
	else
		now=$(date +"%T")
		echo
		echo "Not enough confirmations from last transaction. ($now)"
	fi 

        sleep 3m
done