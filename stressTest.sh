#!/bin/bash

amount="${1}"

myconfig="--chain testnet --server https://testnet.zec.rocks:443 --data-dir /home/zktails/Documents/scripts/zingoHelper/"
amount=100000
ua="utest1jeryw4al7wtv7efn8yh2apucuy48ss0lwf02pdnrnf69wnp0c5zs02j0t395kwdeqwm60jgjhjkrh606470ptxv0kygfwpdxfczaxl3k"


j=0

echo
echo "rescanning for latest transactions ..."
echo
./zingo-cli $myconfig "--waitsync" "rescan" > recsan.log
#sleep 10s
./zingo-cli $myconfig "--waitsync" "transactions" > oHeight.log
oldHeight=$(cat oHeight.log | tail -n +4 | head -n -2 | grep 'txid\|datetime\|blockheight\|kind' | sed '/kind/a --------------' | tail -n -3 | head -n -2 | cut -d ":" -f2 | column -t)
minRequired=$(echo "$oldHeight + 1" | bc)

for (( i=1; i<100; i++ ))
do
	amount=1000000
        
		./zingo-cli $myconfig "--waitsync" "sync" "run" > sync.log

		#sleep 10s

		#./zingo-cli $myconfig "--waitsync" "sync" "poll" > sync.log
                result=$(cat sync.log)

		echo "debug: $result"
		echo

		result=$(./zingoHelper.sh quicksend $ua $amount "memo_$j")
		
        	echo "transaction $i :"
		echo "memo $j :"
		echo "$result"
		echo
		echo "=> txid submitted to mempool successfully!"
		j=$(( $j + 1 ))

	echo "=> waiting 300 seconds for tx to confirm ... "
	echo
        sleep 300s
	echo "running sync now ..."
	echo
done
