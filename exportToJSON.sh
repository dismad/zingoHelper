#!/bin/bash


#number of txid
#length=$(grep -n "}" test | head -n 2 | tail -n 1 | cut -d: -f1)

#create test file of transactions

echo
echo "fetching transaction data now ..."

./zingoHelper.sh transactions >> txidDump

echo "Creating JSON now ..."
echo

if [ -f transactions.json ]; then
	rm transactions.json
fi

mapfile -t txidArray < <(cat txidDump | grep -n txid | cut -d: -f1  )
numOfTXIDs=${#txidArray[@]}
k=0
echo "       [" >> transactions.json

for ((k = 0 ; k < numOfTXIDs ; k++ ))

do	

	headIndex=$(echo "${txidArray[$k + 1]} - 2" | bc)
	tailIndex=$(echo "${txidArray[$k]} - 1" | bc)

	#echo "headIndex: $headIndex"
	#echo "tailIndex: $tailIndex"

	#grab top transaction, idea is to create new test file that moves the index down to the next txid
	#2:    txid: a8dc
	#24:    txid: e319
	#46:    txid: 2652
	#77:    txid: f6030
	#99:    txid: edbe6
	#121:    txid: c4d28
	#161:    txid: c6d65
	#186:    txid: 4f87
	#208:    txid: 5599
	#244:    txid: 92db

	#head txidDump -22 | tail -n +1
	#head txidDump -n44 | tail -n +23
	#head txidDump -n75 | tail -n +45

	head txidDump -n$headIndex | tail -n +$tailIndex > test

	txid=$(head -n2 test | tail -n1 | cut -d ':' -f2- | column -t)
	datetime=$(head -n3 test | tail -n1 | cut -d ':' -f2- | column -t)
	status=$(head -n4 test | tail -n1 | cut -d ':' -f2- | column -t)
	blockheight=$(head -n5 test | tail -n1 | cut -d ':' -f2- | column -t)
	kind=$(head -n6 test | tail -n1 | cut -d ':' -f2- | column -t)
	value=$(head -n7 test | tail -n1 | cut -d ':' -f2- | column -t)
	fee=$(head -n8 test | tail -n1 | cut -d ':' -f2- | column -t)

	if [[ "$fee" == *" "* ]]; then
  		fee=0
	fi


	zec_price=$(head -n9 test | tail -n1 | cut -d ':' -f2- | column -t)
	s_value=0
	s_output_index=0
	t_value=0
	t_output_index=0
	outgoing_o_value=0
	outgoing_o_output_index=0
	outgoing_s_value=0
	outgoing_s_output_index=0
	outgoing_t_value=0
	outgoing_t_output_index=0

	echo "            {" >> transactions.json
	echo "                \"txid\": \"$txid\"," >> transactions.json
	echo "                \"datetime\": \"$datetime\"," >> transactions.json
	echo "                \"status\": \"$status\"," >> transactions.json
	echo "                \"blockheight\": $blockheight," >> transactions.json
	echo "                \"kind\": \"$kind\"," >> transactions.json
	echo "                \"value\": $value," >> transactions.json
	echo "                \"fee\": $fee," >> transactions.json
	echo "                \"zec_price\": \"$zec_price\"," >> transactions.json
	echo "                \"orchard_notes\": [" >> transactions.json

	## Loop through orchard array

	# find line number of orchard section
	orchardLineNumber=$(cat test | head -n100 | grep -n -m 1 "orchard notes" | cut -d: -f1) # need to add 1
	orchardLineNumber=$(echo "$orchardLineNumber + 1" | bc)

	#find line number of sapling section
	saplingLineNumber=$(cat test | head -n100 | grep -n -m 1 "sapling notes" | cut -d: -f1) # need to subtract 1
	saplingLineNumber=$(echo "$saplingLineNumber - 1" | bc)

	#number of orchard txid's
	mycount=$(head -n$saplingLineNumber test | tail -n +$orchardLineNumber | grep -c '}')

	j=$(echo "$orchardLineNumber + 1" | bc)

	for ((i = 0 ; i < $mycount ; i++ ))
	do
		o_value=$(head -n$j test | tail -n1 | cut -d ':' -f2- | column -t)
		o_spend_status=$(head -n$(echo "$j + 1" | bc) test | tail -n1 | cut -d ':' -f2- | column -t)
		o_output_index=$(head -n$(echo "$j + 2" | bc) test | tail -n1 | cut -d ':' -f2- | column -t)
		o_memo=$(head -n$(echo -e "$j + 3" | bc) test | tail -n1 | cut -d ':' -f2- | column -t | sed 's/\\/\\\\/g; s/\//\\\//g')
                o_memo="${o_memo//\"/}"

		

		echo "                    {" >> transactions.json
		echo "                        \"value\": $o_value," >> transactions.json
		echo "                        \"spend_status\": \"$o_spend_status\"," >> transactions.json
		echo "                        \"output_index\": $o_output_index," >> transactions.json
		echo "                        \"memo\": \"$o_memo\"" >> transactions.json
		if [ "$i" == "$(($mycount-1))" ];
		then

			echo "                    }" >> transactions.json
		else
			echo "                    }," >> transactions.json
		fi

		test=$(head -n$(echo "$j + 4" | bc) test | tail -n1 | cut -d ':' -f2- | column -t)

		if [ "$test" == "}" ]; then
			j=$(echo "$j + 6" | bc)
		fi
	done

	echo "                ]," >> transactions.json

	echo "                \"sapling_notes\": [" >> transactions.json
	## Loop through sapling array

	#find line number of sapling section
	saplingLineNumber=$(cat test | head -n100 | grep -n -m 1 "sapling notes" | cut -d: -f1) # need to add 1
	saplingLineNumber=$(echo "$saplingLineNumber + 1" | bc)

	#find line number of transpartion coin section
	transparentLineNumber=$(cat test | head -n100 | grep -n -m 1 "transparent coins" | cut -d: -f1) # need to subtract 1
	transparentLineNumber=$(echo "$transparentLineNumber - 1" | bc)

	#number of sapling txids
	mycount=$(head -n$transparentLineNumber test | tail -n +$saplingLineNumber | grep -c '}')

	j=$(echo "$saplingLineNumber + 1" | bc)

	for ((i = 0 ; i < $mycount ; i++ ))
	do
		#echo "j: $j"
		s_value=$(head -n$j test | tail -n1 | cut -d ':' -f2- | column -t)
		s_spend_status=$(head -n$(echo "$j + 1" | bc) test | tail -n1 | cut -d ':' -f2- | column -t)
		s_output_index=$(head -n$(echo "$j + 2" | bc) test | tail -n1 | cut -d ':' -f2- | column -t)
		s_memo=$(head -n$(echo "$j + 3" | bc) test | tail -n1 | cut -d ':' -f2- | column -t | sed 's/\\/\\\\/g; s/\//\\\//g')
                s_memo="${s_memo//\"/}"

		echo "                    {" >> transactions.json
		echo "                        \"value\": $s_value," >> transactions.json
		echo "                        \"spend_status\": \"$s_spend_status\"," >> transactions.json
		echo "                        \"output_index\": $s_output_index," >> transactions.json
		echo "                        \"memo\": \"$s_memo\"" >> transactions.json
		if [ "$i" == "$(($mycount-1))" ];
		then

			echo "                    }" >> transactions.json
		else
			echo "                    }," >> transactions.json
		fi

		test=$(head -n$(echo "$j + 4" | bc) test | tail -n1 | cut -d ':' -f2- | column -t)

		if [ "$test" == "}" ]; then
			j=$(echo "$j + 6" | bc)
		fi
	done

	echo "                ]," >> transactions.json

	## Loop through transparent coins
	echo "                \"transparent_coins\": [" >> transactions.json

	#find the line number of transparent coins section
	transparentLineNumber=$(cat test | head -n100 | grep -n -m 1 "transparent coins" | cut -d: -f1) # need to add 1 
	transparentLineNumber=$(echo "$transparentLineNumber + 1" | bc) 

	#find line number of outgoing orchard notes section
	#find line number of transpartion coin section
	outgoingOrchardNotesLineNumber=$(cat test | head -n100 | grep -n -m 1 "outgoing orchard notes" | cut -d: -f1) # need to subtract 1
	outgoingOrchardNotesLineNumber=$(echo "$outgoingOrchardNotesLineNumber - 1" | bc)

	#number of transparent txids
	mycount=$(head -n$outgoingOrchardNotesLineNumber test | tail -n +$transparentLineNumber | grep -c '}')

	j=$(echo "$transparentLineNumber + 1" | bc)

	for ((i = 0 ; i < $mycount ; i++ ))
	do
		#echo "j: $j"
		t_value=$(head -n$j test | tail -n1 | cut -d ':' -f2- | column -t)
		t_spend_status=$(head -n$(echo "$j + 1" | bc) test | tail -n1 | cut -d ':' -f2- | column -t)
		t_output_index=$(head -n$(echo "$j + 2" | bc) test | tail -n1 | cut -d ':' -f2- | column -t)
		t_memo=$(head -n$(echo "$j + 3" | bc) test | tail -n1 | cut -d ':' -f2- | column -t | sed 's/\\/\\\\/g; s/\//\\\//g')

		echo "                    {" >> transactions.json
		echo "                        \"value\": $t_value," >> transactions.json
		echo "                        \"spend_status\": \"$t_spend_status\"," >> transactions.json
		echo "                        \"output_index\": $t_output_index," >> transactions.json
		echo "                        \"memo\": \"\"" >> transactions.json
		if [ "$i" == "$(($mycount-1))" ];
		then

			echo "                    }"  >> transactions.json
		else
			echo "                    }," >> transactions.json
		fi

		test=$(head -n$(echo "$j + 4" | bc) test | tail -n1 | cut -d ':' -f2- | column -t)

		if [ "$test" == "}" ]; then
			j=$(echo "$j + 6" | bc)
		fi
	done

	echo "                ]," >> transactions.json

	## Loop through ougoing_orchard_notes section

	echo "                \"outgoing_orchard_notes\": [" >> transactions.json

	#find the line number of outgoing_orchard notes section
	outgoingOrchardNotesLineNumber=$(cat test | head -n100 | grep -n -m 1 "outgoing orchard notes" | cut -d: -f1) # need to add 1 
	outgoingOrchardNotesLineNumber=$(echo "$outgoingOrchardNotesLineNumber + 1" | bc) 

	#find line number of outgoing sapling notes section
	outgoingSaplingNotesLineNumber=$(cat test | head -n100 | grep -n -m 1 "outgoing sapling notes" | cut -d: -f1) # need to subtract 1
	outgoingSaplingNotesLineNumber=$(echo "$outgoingSaplingNotesLineNumber - 1" | bc)

	#number of outgoing orchard notes
	mycount=$(head -n$outgoingSaplingNotesLineNumber test | tail -n +$outgoingOrchardNotesLineNumber | grep -c '}')

	j=$(echo "$outgoingOrchardNotesLineNumber + 1" | bc)


	for ((i = 0 ; i < $mycount ; i++ ))
	do
		outgoing_o_value=$(head -n$j test | tail -n1 | cut -d ':' -f2- | column -t)
		outgoing_o_memo=$(head -n$(echo "$j + 1" | bc) test | tail -n1 | cut -d ':' -f2- | column -t | sed 's/\\/\\\\/g; s/\//\\\//g')
		outgoing_o_memo="${outgoing_o_memo//\"/}"
		outgoing_o_recipient=$(head -n$(echo "$j + 2" | bc) test | tail -n1 | cut -d ':' -f2- | column -t)
		outgoing_o_recipient_unified_address=$(head -n$(echo "$j + 3" | bc) test | tail -n1 | cut -d ':' -f2- | column -t)
		outgoing_o_output_index=$(head -n$(echo "$j + 4" | bc) test | tail -n1 | cut -d ':' -f2- | column -t)
		outgoing_o_account_id=$(head -n$(echo "$j + 5" | bc) test | tail -n1 | cut -d ':' -f2- | column -t)
		outgoing_o_scope=$(head -n$(echo "$j + 6" | bc) test | tail -n1 | cut -d ':' -f2- | column -t)

		echo "                    {" >> transactions.json
		echo "                        \"value\": $outgoing_o_value," >> transactions.json
		echo "                        \"memo\": \"$outgoing_o_memo\"," >> transactions.json
		echo "                        \"recipient\": \"$outgoing_o_recipient\"," >> transactions.json
		echo "                        \"recipient_unified_address\": \"$outgoing_o_recipient_unified_address\"," >> transactions.json
		echo "                        \"output_index\": $outgoing_o_output_index," >> transactions.json
		echo "                        \"account_id\": $outgoing_o_account_id," >> transactions.json
		echo "                        \"scope\": \"$outgoing_o_scope\"" >> transactions.json
		if [ "$i" == "$(($mycount-1))" ];
		then

			echo "                    }" >> transactions.json
		else
			echo "                    }," >> transactions.json
		fi

		test=$(head -n$(echo "$j + 7" | bc) test | tail -n1 | cut -d ':' -f2- | column -t)

		if [ "$test" == "}" ]; then
			j=$(echo "$j + 9" | bc)
		fi
	done

	echo "                ]," >> transactions.json
	echo "                \"outgoing_sapling_notes\": [" >> transactions.json
	echo "                    {" >> transactions.json
	echo "                        \"value\": $outgoing_s_value," >> transactions.json
	echo "                        \"spend_status\": \"$outgoing_s_spend_status\"," >> transactions.json
	echo "                        \"output_index\": $outgoing_s_output_index," >> transactions.json
	echo "                        \"memo\": \"$outgoing_s_memo\"" >> transactions.json
	echo "                    }" >> transactions.json
	echo "                ]," >> transactions.json
	echo "                \"outgoing_transparent_coins\": [" >> transactions.json
	echo "                    {" >> transactions.json
	echo "                        \"value\": $outgoing_t_value," >> transactions.json
	echo "                        \"spend_status\": \"$outgoing_t_spend_status\"," >> transactions.json
	echo "                        \"output_index\": $outgoing_t_output_index," >> transactions.json
	echo "                        \"memo\": \"\"" >> transactions.json
	echo "                    }" >> transactions.json
	echo "                ]" >> transactions.json

	if [ "$k" == "$(($numOfTXIDs-1))" ];
	then

		echo "            }" >> transactions.json
	else
		echo "            }," >> transactions.json
	fi

done

echo "       ]" >> transactions.json

rm test
rm txidDump

echo "\"transactions.json\" written!"
